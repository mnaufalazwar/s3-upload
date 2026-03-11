import boto3
from config import settings

kwargs = {"region_name": settings.aws_region}

# If explicit credentials are provided (local dev) use them.
# If not (ECS), boto3 falls back to the task role automatically
if settings.aws_secret_access_key:
    kwargs["aws_access_key_id"] = settings.aws_access_key_id
    kwargs["aws_secret_access_key"] = settings.aws_secret_access_key

s3 = boto3.client(
    "s3",
    **kwargs
)

BUCKET = settings.s3_bucket_name