"use client";

import { Puck } from "@measured/puck";
import "@measured/puck/puck.css";
import type { Data } from "@measured/puck";
import { puckConfig } from "./config";
import { KennelDataProvider } from "./KennelDataContext";
import type { KennelPageData } from "./KennelDataContext";

interface PuckEditorProps {
  slug: string;
  initialData: Data;
  pageData: KennelPageData;
}

export function PuckEditor({ slug, initialData, pageData }: PuckEditorProps) {
  const handlePublish = async (data: Data) => {
    const res = await fetch("/api/admin/save-layout", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ slug, pageLayoutJson: JSON.stringify(data) }),
    });
    if (!res.ok) {
      console.error("save-layout failed", await res.text().catch(() => ""));
    }
  };

  return (
    <KennelDataProvider data={pageData}>
      <Puck
        config={puckConfig}
        data={initialData}
        onPublish={handlePublish}
        iframe={{ enabled: false }}
      />
    </KennelDataProvider>
  );
}
