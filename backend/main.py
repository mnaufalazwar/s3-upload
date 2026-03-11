import uuid
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from s3_client import s3, BUCKET

app = FastAPI(title="S3 Upload Tutorial")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    """
    Accept a file via multipart/form-data and stream it to S3

    How this works under the hood:
    1.  The browser sends the file as multipart/form-data (binary chinks separated by a boundary string).
    2.  FastAPI's UploadFile wraps a SpooledTemporaryFile - small files live in memory,
        large files (>1MB) spill to a temp file on disk. This means the server never loads the entire file into RAM.
    3.  We read the file object and pass it directly to boto3's upload_fileobj, which streams it to S3 in multipart chunks.
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")

    extension = file.filename.rsplit(".", 1)[-1] if "." in file.filename else ""
    s3_key = f"uploads/{uuid.uuid4()}.{extension}"

    try:
        s3.upload_fileobj(
            file.file,
            BUCKET,
            s3_key,
            ExtraArgs={"ContentType": file.content_type or "application/octet-stream"}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"S3 upload failed: {e}")

    return {
        "message": "Upload successful",
        "s3_key": s3_key,
        "bucket": BUCKET
    }


@app.get("/files")
def list_files():
    """List all uploaded files in the bucket"""
    try:
        response = s3.list_objects_v2(Bucket=BUCKET, Prefix="uploads/")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"S3 list failed: {e}")

    files = []
    for obj in response.get("Contents", []):
        files.append({
            "key": obj["Key"],
            "size_bytes": obj["Size"],
            "last_modified": obj["LastModified"].isoformat(),
        })

    return {"files": files}


@app.get("/presign/{s3_key:path}")
def get_presigned_url(s3_key: str, content_type: str = "application/octet-stream"):
    """
    Generate a presigned URL for direct browser-to-S3 upload.

    This is an alternative to the /upload endpoint. Instead of the file
    going through your server, the browser uploads directly to S3.

    Trade-offs:
    - Pro: No server bandwidth or memory used for the file transfer
    - Pro: Faster for large files (one fewer network hop)
    - Con: You lose server-side validation (file type, size checks)
    - Con: More complex client-side code
    - Con: Requires S3 CORS configuration (we already set this in Terraform)
    """
    url = s3.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": BUCKET,
            "Key": s3_key,
            "ContentType": content_type,
        },
        ExpiresIn=3600,
    )

    return {"presigned_url": url, "s3_key": s3_key, "content_type": content_type}
