import { useState, useEffect } from "react";

const API = "http://localhost:8000";

export default function App(){
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [message, setMessage] = useState("");
  const [files, setFiles] = useState([]);

  useEffect(
    () => { fetchFiles(); }, // argument 1: a function to run
    []                       // argument 2: when to run it
  );

  async function fetchFiles() {
    try {
      const res = await fetch(`${API}/files`);
      const data = await res.json();
      setFiles(data.files || []);
    } catch {
      console.error("Failed to fetch files");
    }
  }

  function handleFileChange(e) {
    const selected = e.target.files[0];
    if (selected) {
      setFile(selected);
      setMessage("");
      setProgress(0);
    }
  }

  function handleUpload() {
    if (!file) return;

    setUploading(true);
    setProgress(0);
    setMessage("");

    const formData = new FormData();
    formData.append("file", file);

    const xhr = new XMLHttpRequest();

    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable) {
        setProgress(Math.round((e.loaded / e.total) * 100));
      }
    };

    xhr.onload = () => {
      setUploading(false);
      if (xhr.status === 200) {
        const data = JSON.parse(xhr.responseText);
        setMessage(`Uploaded successfully: ${data.s3_key}`);
        setFile(null);
        fetchFiles();
      } else {
        setMessage(`Upload failed (${xhr.status})`);
      }
    };

    xhr.onerror = () => {
      setUploading(false);
      setMessage("Upload failed — network error");
    };

    xhr.open("POST", `${API}/upload`);
    xhr.send(formData);
  }

  async function handlePresignedUpload() {
    if (!file) return;

    setUploading(true);
    setProgress(0);
    setMessage("");

    try {
      // Step 1: Ask the backend for a presigned URL (include content type so the signature matches)
      const s3Key = `uploads/${crypto.randomUUID()}.${file.name.split(".").pop()}`;
      const res = await fetch(`${API}/presign/${s3Key}?content_type=${encodeURIComponent(file.type)}`);
      const { presigned_url } = await res.json();

      // Step 2: Upload the file directly to S3 using the presigned URL
      const xhr = new XMLHttpRequest();

      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) {
          setProgress(Math.round((e.loaded / e.total) * 100));
        }
      };

      xhr.onload = () => {
        setUploading(false);
        if (xhr.status === 200) {
          setMessage(`Uploaded via presigned URL: ${s3Key}`);
          setFile(null);
          fetchFiles();
        } else {
          setMessage(`Presigned upload failed (${xhr.status})`);
        }
      };

      xhr.onerror = () => {
        setUploading(false);
        setMessage("Presigned upload failed — network error");
      };

      xhr.open("PUT", presigned_url);
      xhr.setRequestHeader("Content-Type", file.type);
      xhr.send(file);
    } catch (err) {
      setUploading(false);
      setMessage(`Presigned upload failed: ${err.message}`);
    }
  }

  function formatSize(bytes) {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }

  return (
    <div style={{ maxWidth: 600, margin: "40px auto", fontFamily: "system-ui" }}>
      <h1>S3 File Upload</h1>

      {/* --- File picker --- */}
      <div style={{ marginBottom: 16 }}>
        <input
          type="file"
          accept="video/*,audio/*"
          onChange={handleFileChange}
          disabled={uploading}
        />
      </div>

      {/* --- Selected file info (only shown when a file is picked) --- */}
      {file && (
        <p style={{ color: "#555" }}>
          Selected: <strong>{file.name}</strong> ({formatSize(file.size)})
        </p>
      )}

      {/* --- Upload buttons --- */}
      <div style={{ display: "flex", gap: 12 }}>
        <button
          onClick={handleUpload}
          disabled={!file || uploading}
          style={{
            padding: "10px 24px",
            fontSize: 16,
            cursor: file && !uploading ? "pointer" : "not-allowed",
          }}
        >
          {uploading ? "Uploading..." : "Upload (via server)"}
        </button>
        <button
          onClick={handlePresignedUpload}
          disabled={!file || uploading}
          style={{
            padding: "10px 24px",
            fontSize: 16,
            cursor: file && !uploading ? "pointer" : "not-allowed",
          }}
        >
          {uploading ? "Uploading..." : "Upload (presigned URL)"}
        </button>
      </div>

      {/* --- Progress bar (only shown during upload) --- */}
      {uploading && (
        <div style={{
          marginTop: 12,
          background: "#eee",
          borderRadius: 4,
          overflow: "hidden",
        }}>
          <div style={{
            width: `${progress}%`,
            height: 24,
            background: "#4caf50",
            transition: "width 0.2s",
            textAlign: "center",
            color: "#fff",
            lineHeight: "24px",
            fontSize: 13,
          }}>
            {progress}%
          </div>
        </div>
      )}

      {/* --- Status message (success or error) --- */}
      {message && (
        <p style={{
          marginTop: 12,
          padding: 12,
          background: message.includes("success") ? "#e8f5e9" : "#fbe9e7",
          borderRadius: 4,
        }}>
          {message}
        </p>
      )}

      {/* --- File list --- */}
      <h2 style={{ marginTop: 32 }}>Uploaded Files</h2>
      {files.length === 0 ? (
        <p style={{ color: "#999" }}>No files uploaded yet.</p>
      ) : (
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr style={{ borderBottom: "2px solid #ddd", textAlign: "left" }}>
              <th style={{ padding: 8 }}>Key</th>
              <th style={{ padding: 8 }}>Size</th>
            </tr>
          </thead>
          <tbody>
            {files.map((f) => (
              <tr key={f.key} style={{ borderBottom: "1px solid #eee" }}>
                <td style={{ padding: 8, fontSize: 13, wordBreak: "break-all" }}>
                  {f.key}
                </td>
                <td style={{ padding: 8, fontSize: 13 }}>
                  {formatSize(f.size_bytes)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
