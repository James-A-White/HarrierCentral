"use client";

import { useRef, useState } from "react";

interface Props {
  value: string;
  onChange: (url: string) => void;
  slug: string;
}

export function ImageUploadField({ value, onChange, slug }: Props) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    setError(null);

    const body = new FormData();
    body.append("file", file);
    body.append("slug", slug);

    try {
      const res = await fetch("/api/admin/upload-image", { method: "POST", body });
      const data = (await res.json()) as { url?: string; error?: string };
      if (!res.ok) {
        setError(data.error ?? "Upload failed.");
      } else if (data.url) {
        onChange(data.url);
      }
    } catch {
      setError("Upload failed — check your connection.");
    } finally {
      setUploading(false);
      if (inputRef.current) inputRef.current.value = "";
    }
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
      {value && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={value}
          alt=""
          style={{ width: "100%", maxHeight: 160, objectFit: "cover", borderRadius: 6 }}
        />
      )}
      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp,image/gif"
        style={{ display: "none" }}
        onChange={handleFileChange}
      />
      <button
        type="button"
        onClick={() => inputRef.current?.click()}
        disabled={uploading}
        style={{
          padding: "8px 14px", borderRadius: 6, border: "1px solid #444",
          background: "#1a1a1a", color: uploading ? "#777" : "#ccc",
          cursor: uploading ? "wait" : "pointer", fontSize: 13, textAlign: "center",
        }}
      >
        {uploading ? "Uploading…" : value ? "Replace image" : "Upload image"}
      </button>
      {value && !uploading && (
        <button
          type="button"
          onClick={() => onChange("")}
          style={{
            padding: "6px 14px", borderRadius: 6, border: "1px solid #333",
            background: "transparent", color: "#777", cursor: "pointer", fontSize: 12,
          }}
        >
          Remove image
        </button>
      )}
      {error && (
        <p style={{ margin: 0, fontSize: 12, color: "#dc2626" }}>{error}</p>
      )}
    </div>
  );
}
