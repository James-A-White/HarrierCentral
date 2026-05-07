"use client";

import { Puck } from "@measured/puck";
import "@measured/puck/puck.css";
import type { Data } from "@measured/puck";
import { useState, useRef, useCallback, useMemo } from "react";
import { createPuckConfig } from "./config";
import { toKennelContext } from "@/lib/kennel-utils";
import { KennelDataProvider } from "./KennelDataContext";
import type { KennelPageData } from "./KennelDataContext";
import type { PageLayoutBlob, PageType } from "@/lib/page-layout";
import { PAGE_TYPES, PAGE_LABELS, defaultLayouts } from "@/lib/page-layout";

interface PuckEditorProps {
  slug: string;
  initialBlob: PageLayoutBlob;
  pageData: KennelPageData;
}

interface Toast {
  message: string;
  ok: boolean;
}

export function PuckEditor({ slug, initialBlob, pageData }: PuckEditorProps) {
  const puckConfig = useMemo(() => createPuckConfig(slug), [slug]);
  const kennel = useMemo(() => toKennelContext(pageData.kennelData), [pageData.kennelData]);
  const [blob, setBlob] = useState<PageLayoutBlob>(initialBlob);
  const [currentPage, setCurrentPage] = useState<PageType>("home");
  const [isDirty, setIsDirty] = useState(false);
  const [pendingPage, setPendingPage] = useState<PageType | null>(null);
  const [toast, setToast] = useState<Toast | null>(null);
  const latestDataRef = useRef<Data>(initialBlob.home ?? defaultLayouts.home);
  // Prevents the first onChange call (Puck init) from marking dirty after a page switch
  const dirtyAllowed = useRef(true);

  const showToast = (message: string, ok: boolean) => {
    setToast({ message, ok });
    setTimeout(() => setToast(null), 4000);
  };

  const doSave = useCallback(async (data: Data, targetBlob: PageLayoutBlob): Promise<PageLayoutBlob | null> => {
    const newBlob = { ...targetBlob, [currentPage]: data };
    const res = await fetch("/api/admin/save-layout", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ slug, pageLayoutJson: JSON.stringify(newBlob) }),
    });
    if (res.ok) return newBlob;
    return null;
  }, [currentPage, slug]);

  const handlePublish = useCallback(async (data: Data) => {
    const newBlob = await doSave(data, blob);
    if (newBlob) {
      setBlob(newBlob);
      setIsDirty(false);
      showToast("Published successfully.", true);
    } else {
      showToast("Publish failed. Please try again.", false);
    }
  }, [blob, doSave]);

  const handleChange = useCallback((data: Data) => {
    latestDataRef.current = data;
    if (!dirtyAllowed.current) {
      dirtyAllowed.current = true;
      return;
    }
    setIsDirty(true);
  }, []);

  const switchPage = useCallback((page: PageType, updatedBlob?: PageLayoutBlob) => {
    dirtyAllowed.current = false;
    const activeBlob = updatedBlob ?? blob;
    latestDataRef.current = activeBlob[page] ?? defaultLayouts[page];
    setCurrentPage(page);
    setIsDirty(false);
  }, [blob]);

  const handlePageSelect = useCallback((page: PageType) => {
    if (page === currentPage) return;
    if (isDirty) {
      setPendingPage(page);
    } else {
      switchPage(page);
    }
  }, [currentPage, isDirty, switchPage]);

  const handlePublishAndSwitch = useCallback(async () => {
    if (!pendingPage) return;
    const newBlob = await doSave(latestDataRef.current, blob);
    if (newBlob) {
      setBlob(newBlob);
      showToast("Published successfully.", true);
    } else {
      showToast("Publish failed.", false);
    }
    switchPage(pendingPage, newBlob ?? blob);
    setPendingPage(null);
  }, [pendingPage, doSave, blob, switchPage]);

  const handleDiscardAndSwitch = useCallback(() => {
    if (!pendingPage) return;
    switchPage(pendingPage);
    setPendingPage(null);
  }, [pendingPage, switchPage]);

  return (
    <KennelDataProvider data={pageData}>
      {/* Toast notification */}
      {toast && (
        <div style={{
          position: "fixed", top: 16, right: 16, zIndex: 9999,
          padding: "12px 20px", borderRadius: 8,
          fontFamily: "system-ui, sans-serif", fontSize: 14, fontWeight: 500,
          color: "#fff",
          background: toast.ok ? "#16a34a" : "#dc2626",
          boxShadow: "0 4px 16px rgba(0,0,0,0.35)",
          transition: "opacity 0.2s",
        }}>
          {toast.message}
        </div>
      )}

      {/* Unsaved-changes dialog */}
      {pendingPage && (
        <div style={{
          position: "fixed", inset: 0, zIndex: 9998,
          background: "rgba(0,0,0,0.65)",
          display: "flex", alignItems: "center", justifyContent: "center",
        }}>
          <div style={{
            background: "#1c1c1e", borderRadius: 14, padding: "32px 36px", maxWidth: 420, width: "90%",
            fontFamily: "system-ui, sans-serif", color: "#fff",
            boxShadow: "0 12px 48px rgba(0,0,0,0.55)",
          }}>
            <h2 style={{ margin: "0 0 10px", fontSize: 18, fontWeight: 700 }}>
              Unsaved changes
            </h2>
            <p style={{ margin: "0 0 24px", color: "#aaa", fontSize: 14, lineHeight: 1.5 }}>
              You have unpublished changes on the <strong style={{ color: "#fff" }}>{PAGE_LABELS[currentPage]}</strong> page.
              Publish them before switching, or discard and continue.
            </p>
            <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
              <button
                onClick={handlePublishAndSwitch}
                style={{
                  flex: 1, minWidth: 120, padding: "10px 0", borderRadius: 8, border: "none",
                  background: "#2563eb", color: "#fff", fontWeight: 600,
                  cursor: "pointer", fontSize: 14,
                }}
              >
                Publish &amp; Switch
              </button>
              <button
                onClick={handleDiscardAndSwitch}
                style={{
                  flex: 1, minWidth: 120, padding: "10px 0", borderRadius: 8,
                  border: "1px solid #444", background: "transparent",
                  color: "#ccc", fontWeight: 600, cursor: "pointer", fontSize: 14,
                }}
              >
                Discard &amp; Switch
              </button>
              <button
                onClick={() => setPendingPage(null)}
                style={{
                  padding: "10px 18px", borderRadius: 8, border: "1px solid #333",
                  background: "transparent", color: "#777", cursor: "pointer", fontSize: 14,
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      <Puck
        key={currentPage}
        config={puckConfig}
        data={blob[currentPage] ?? defaultLayouts[currentPage]}
        onPublish={handlePublish}
        onChange={handleChange}
        iframe={{ enabled: false }}
        overrides={{
          preview: ({ children }) => {
            const DEFAULT_BG = "/images/jungle_background.jpg";
            const usingDefault = !kennel.backgroundImageUrl;
            const imageUrl = kennel.backgroundImageUrl ?? DEFAULT_BG;
            const bgSize = usingDefault ? "1024px 1024px" : "cover";
            const blurPx = usingDefault ? 0 : (Math.min(100, Math.max(0, kennel.scrollBlur)) / 100) * 120;
            const overlayColor = usingDefault ? "#000000" : kennel.backgroundOverlayColor;
            const overlayOpacity = usingDefault ? 0.55 : kennel.backgroundOverlayMaxOpacity;
            const bgStyle = { backgroundImage: `url(${imageUrl})`, backgroundSize: bgSize, backgroundPosition: "center" };
            return (
              <div style={{ position: "relative", minHeight: "100%" }}>
                {/* Layer 1 — sharp base image */}
                <div style={{ position: "absolute", inset: 0, transform: "scale(1.08)", ...bgStyle }} />
                {/* Layer 2 — blurred image */}
                <div style={{ position: "absolute", inset: 0, transform: "scale(1.08)", filter: `blur(${blurPx}px)`, ...bgStyle }} />
                {/* Layer 3 — colour overlay */}
                <div style={{ position: "absolute", inset: 0, backgroundColor: overlayColor, opacity: overlayOpacity }} />
                {/* Content */}
                <div style={{ position: "relative" }}>
                  {children}
                </div>
              </div>
            );
          },
          headerActions: ({ children }) => (
            <>
              <div style={{
                display: "flex", alignItems: "center", gap: 10,
                marginRight: 8, fontFamily: "system-ui, sans-serif",
              }}>
                <label style={{ fontSize: 12, color: "#999" }}>Page:</label>
                <select
                  value={currentPage}
                  onChange={(e) => handlePageSelect(e.target.value as PageType)}
                  style={{
                    padding: "5px 10px", borderRadius: 6, border: "1px solid #444",
                    background: "#1a1a1a", color: "#fff", fontSize: 13, cursor: "pointer",
                  }}
                >
                  {PAGE_TYPES.map((p) => (
                    <option key={p} value={p}>{PAGE_LABELS[p]}</option>
                  ))}
                </select>
                {isDirty && (
                  <span style={{ fontSize: 11, color: "#f59e0b", whiteSpace: "nowrap" }}>
                    ● Unpublished
                  </span>
                )}
              </div>
              {children}
            </>
          ),
        }}
      />
    </KennelDataProvider>
  );
}
