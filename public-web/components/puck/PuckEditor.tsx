"use client";

import { Puck, migrate } from "@measured/puck";
import "@measured/puck/puck.css";
import type { Data } from "@measured/puck";
import { useState, useRef, useCallback, useMemo } from "react";
import { Layers, Loader2 } from "lucide-react";
import { createPuckConfig } from "./config";
import { toKennelContext } from "@/lib/kennel-utils";
import { KennelDataProvider } from "./KennelDataContext";
import type { KennelPageData } from "./KennelDataContext";
import { PagePanel } from "./PagePanel";
import type { SiteConfig } from "@/lib/page-layout";
import { getDefaultLayout } from "@/lib/page-layout";

interface PuckEditorProps {
  slug: string;
  initialConfig: SiteConfig;
  pageData: KennelPageData;
}

interface Toast {
  message: string;
  ok: boolean;
}

export function PuckEditor({ slug, initialConfig, pageData }: PuckEditorProps) {
  const kennel = useMemo(() => toKennelContext(pageData.kennelData), [pageData.kennelData]);

  const [siteConfig, setSiteConfig]     = useState<SiteConfig>(initialConfig);
  const [currentPageId, setCurrentPageId] = useState("home");
  const [isDirty, setIsDirty]           = useState(false);
  const [pendingPageId, setPendingPageId] = useState<string | null>(null);
  const [showPagePanel, setShowPagePanel] = useState(true);
  const [toast, setToast]               = useState<Toast | null>(null);
  // A publish or a page-panel save in flight. Both write the whole site
  // config, so they share one guard: a second press is refused until the
  // first returns, and two saves can never interleave and undo each other.
  const [publishing, setPublishing]     = useState(false);
  const [saving, setSaving]             = useState(false);
  const busyRef = useRef(false);

  const latestDataRef  = useRef<Data>(
    initialConfig.pages.find(p => p.id === "home")?.layout ?? getDefaultLayout("home")
  );
  const dirtyAllowed   = useRef(true);

  // ── nav pages → puck config ───────────────────────────────────────────────

  const navPages = useMemo(
    () =>
      [...siteConfig.pages]
        .sort((a, b) => a.order - b.order)
        .filter(p => p.status !== "draft")
        .map(p => ({
          label: p.name,
          href: `/${slug}${p.slug ? `/${p.slug}` : ""}`,
        })),
    [siteConfig.pages, slug]
  );

  const puckConfig = useMemo(() => createPuckConfig(slug, navPages), [slug, navPages]);

  // ── helpers ───────────────────────────────────────────────────────────────

  function showToast(message: string, ok: boolean) {
    setToast({ message, ok });
    setTimeout(() => setToast(null), 4000);
  }

  function currentPageName() {
    return siteConfig.pages.find(p => p.id === currentPageId)?.name ?? currentPageId;
  }

  // ── save ──────────────────────────────────────────────────────────────────

  async function persistConfig(config: SiteConfig): Promise<boolean> {
    try {
      const res = await fetch("/api/admin/save-layout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug, pageLayoutJson: JSON.stringify(config) }),
      });
      return res.ok;
    } catch {
      return false;
    }
  }

  const doSave = useCallback(async (data: Data, baseConfig: SiteConfig): Promise<SiteConfig | null> => {
    const newConfig: SiteConfig = {
      ...baseConfig,
      pages: baseConfig.pages.map(p =>
        p.id === currentPageId ? { ...p, layout: data } : p
      ),
    };
    const ok = await persistConfig(newConfig);
    return ok ? newConfig : null;
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPageId, slug]);

  const handlePublish = useCallback(async (data: Data) => {
    if (busyRef.current) return;
    busyRef.current = true;
    setPublishing(true);
    try {
      const newConfig = await doSave(data, siteConfig);
      if (newConfig) {
        setSiteConfig(newConfig);
        setIsDirty(false);
        showToast("Published successfully.", true);
      } else {
        showToast("Publish failed. Please try again.", false);
      }
    } finally {
      busyRef.current = false;
      setPublishing(false);
    }
  }, [siteConfig, doSave]);

  // ── page panel config changes (auto-save) ─────────────────────────────────

  const handleUpdateConfig = useCallback(async (newConfig: SiteConfig) => {
    if (busyRef.current) return;
    busyRef.current = true;
    setSaving(true);
    try {
    // Merge the currently-editing page's latest data so nothing is lost
    const merged: SiteConfig = {
      ...newConfig,
      pages: newConfig.pages.map(p =>
        p.id === currentPageId ? { ...p, layout: latestDataRef.current } : p
      ),
    };

    // If the current page was deleted, fall back to home
    const currentStillExists = merged.pages.some(p => p.id === currentPageId);

    const ok = await persistConfig(merged);
    if (ok) {
      setSiteConfig(merged);
      if (!currentStillExists) {
        switchPage("home", merged);
      }
      showToast("Saved.", true);
    } else {
      showToast("Save failed.", false);
    }
    } finally {
      busyRef.current = false;
      setSaving(false);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPageId, slug]);

  // ── page switching ────────────────────────────────────────────────────────

  const switchPage = useCallback((pageId: string, config?: SiteConfig) => {
    dirtyAllowed.current = false;
    const activeConfig = config ?? siteConfig;
    const page = activeConfig.pages.find(p => p.id === pageId);
    latestDataRef.current = page?.layout ?? getDefaultLayout(pageId);
    setCurrentPageId(pageId);
    setIsDirty(false);
  }, [siteConfig]);

  const handleSelectPage = useCallback((pageId: string) => {
    if (pageId === currentPageId) return;
    if (isDirty) {
      setPendingPageId(pageId);
    } else {
      switchPage(pageId);
    }
  }, [currentPageId, isDirty, switchPage]);

  const handlePublishAndSwitch = useCallback(async () => {
    if (!pendingPageId || busyRef.current) return;
    busyRef.current = true;
    setPublishing(true);
    try {
      const newConfig = await doSave(latestDataRef.current, siteConfig);
      if (newConfig) {
        setSiteConfig(newConfig);
        showToast("Published successfully.", true);
      } else {
        showToast("Publish failed.", false);
      }
      switchPage(pendingPageId, newConfig ?? siteConfig);
      setPendingPageId(null);
    } finally {
      busyRef.current = false;
      setPublishing(false);
    }
  }, [pendingPageId, doSave, siteConfig, switchPage]);

  const handleDiscardAndSwitch = useCallback(() => {
    if (!pendingPageId || busyRef.current) return;
    switchPage(pendingPageId);
    setPendingPageId(null);
  }, [pendingPageId, switchPage]);

  const handleChange = useCallback((data: Data) => {
    latestDataRef.current = data;
    if (!dirtyAllowed.current) {
      dirtyAllowed.current = true;
      return;
    }
    setIsDirty(true);
  }, []);

  // ── current page data ─────────────────────────────────────────────────────

  const currentPageLayout = useMemo(() => {
    const page = siteConfig.pages.find(p => p.id === currentPageId);
    const raw = page?.layout ?? getDefaultLayout(currentPageId);
    // Migrate legacy DropZone zone data to slot format transparently
    return migrate(raw, puckConfig) as Data;
  }, [siteConfig, currentPageId, puckConfig]);

  // ── render ────────────────────────────────────────────────────────────────

  const bgStyle = useMemo(() => {
    const DEFAULT_BG = "/images/jungle_background.jpg";
    const usingDefault = !kennel.backgroundImageUrl;
    const imageUrl = kennel.backgroundImageUrl ?? DEFAULT_BG;
    const bgSize = usingDefault ? "1024px 1024px" : "cover";
    const blurPx = usingDefault ? 0 : (Math.min(100, Math.max(0, kennel.scrollBlur)) / 100) * 120;
    const overlayColor = usingDefault ? "#000000" : kennel.backgroundOverlayColor;
    const overlayOpacity = usingDefault ? 0.55 : kennel.backgroundOverlayMaxOpacity;
    return { imageUrl, bgSize, blurPx, overlayColor, overlayOpacity };
  }, [kennel]);

  return (
    <KennelDataProvider data={pageData}>

      {/* Toast */}
      {toast && (
        <div style={{
          position: "fixed", top: 16, right: 16, zIndex: 9999,
          padding: "12px 20px", borderRadius: 8,
          fontFamily: "system-ui, sans-serif", fontSize: 14, fontWeight: 500,
          color: "#fff",
          background: toast.ok ? "#16a34a" : "#dc2626",
          boxShadow: "0 4px 16px rgba(0,0,0,0.35)",
        }}>
          {toast.message}
        </div>
      )}

      {/* Unsaved-changes dialog */}
      {pendingPageId && (
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
            <h2 style={{ margin: "0 0 10px", fontSize: 18, fontWeight: 700 }}>Unsaved changes</h2>
            <p style={{ margin: "0 0 24px", color: "#aaa", fontSize: 14, lineHeight: 1.5 }}>
              You have unpublished changes on the{" "}
              <strong style={{ color: "#fff" }}>{currentPageName()}</strong> page.
              Publish them before switching, or discard and continue.
            </p>
            <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
              <button
                onClick={handlePublishAndSwitch}
                disabled={publishing}
                style={{
                  flex: 1, minWidth: 120, padding: "10px 0", borderRadius: 8, border: "none",
                  background: "#2563eb", color: "#fff", fontWeight: 600, fontSize: 14,
                  display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
                  cursor: publishing ? "default" : "pointer", opacity: publishing ? 0.75 : 1,
                }}
              >
                {publishing && <Loader2 size={14} className="animate-spin" />}
                {publishing ? "Publishing…" : <>Publish &amp; Switch</>}
              </button>
              <button
                onClick={handleDiscardAndSwitch}
                disabled={publishing}
                style={{
                  flex: 1, minWidth: 120, padding: "10px 0", borderRadius: 8,
                  border: "1px solid #444", background: "transparent",
                  color: "#ccc", fontWeight: 600, fontSize: 14,
                  cursor: publishing ? "default" : "pointer", opacity: publishing ? 0.5 : 1,
                }}
              >
                Discard &amp; Switch
              </button>
              <button
                onClick={() => setPendingPageId(null)}
                disabled={publishing}
                style={{
                  padding: "10px 18px", borderRadius: 8, border: "1px solid #333",
                  background: "transparent", color: "#777", fontSize: 14,
                  cursor: publishing ? "default" : "pointer", opacity: publishing ? 0.5 : 1,
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Editor layout: [PagePanel?] [Puck] */}
      <div style={{ display: "flex", height: "100vh", overflow: "hidden" }}>

        {showPagePanel && (
          <div style={{ position: "relative", display: "flex" }}>
            <PagePanel
              siteConfig={siteConfig}
              currentPageId={currentPageId}
              onSelectPage={handleSelectPage}
              onUpdateConfig={handleUpdateConfig}
            />
            {/* While a save or publish is in flight the panel takes no clicks:
                each change is built from the last saved config, so a second
                one before the first returns would undo it. */}
            {(saving || publishing) && (
              <div
                aria-busy="true"
                style={{
                  position: "absolute", inset: 0, zIndex: 10,
                  background: "rgba(255,255,255,0.55)", cursor: "progress",
                  display: "flex", alignItems: "flex-start", justifyContent: "center", paddingTop: 12,
                  fontFamily: "system-ui, sans-serif", fontSize: 12, color: "#374151", gap: 6,
                }}
              >
                <Loader2 size={14} className="animate-spin" />
                {saving ? "Saving…" : "Publishing…"}
              </div>
            )}
          </div>
        )}

        <div style={{ flex: 1, overflow: "hidden", minWidth: 0 }}>
          <Puck
            key={currentPageId}
            config={puckConfig}
            data={currentPageLayout}
            onPublish={handlePublish}
            onChange={handleChange}
            iframe={{ enabled: false }}
            overrides={{
              preview: ({ children }) => (
                <div style={{ position: "relative", minHeight: "100%" }}>
                  <div style={{ position: "absolute", inset: 0, transform: "scale(1.08)", backgroundImage: `url(${bgStyle.imageUrl})`, backgroundSize: bgStyle.bgSize, backgroundPosition: "center" }} />
                  <div style={{ position: "absolute", inset: 0, transform: "scale(1.08)", filter: `blur(${bgStyle.blurPx}px)`, backgroundImage: `url(${bgStyle.imageUrl})`, backgroundSize: bgStyle.bgSize, backgroundPosition: "center" }} />
                  <div style={{ position: "absolute", inset: 0, backgroundColor: bgStyle.overlayColor, opacity: bgStyle.overlayOpacity }} />
                  <div style={{ position: "relative" }}>{children}</div>
                </div>
              ),
              headerActions: ({ children }) => (
                <>
                  <div style={{
                    display: "flex", alignItems: "center", gap: 10,
                    marginRight: 8, fontFamily: "system-ui, sans-serif",
                  }}>
                    {/* Pages panel toggle */}
                    <button
                      onClick={() => setShowPagePanel(v => !v)}
                      title={showPagePanel ? "Hide pages panel" : "Show pages panel"}
                      style={{
                        display: "flex", alignItems: "center", justifyContent: "center",
                        width: 32, height: 32, borderRadius: 6, border: "none",
                        background: showPagePanel ? "#2563eb" : "#2a2a2a",
                        color: showPagePanel ? "#fff" : "#888",
                        cursor: "pointer",
                        transition: "background 0.15s",
                      }}
                    >
                      <Layers size={16} />
                    </button>

                    {/* Current page indicator */}
                    <span style={{ fontSize: 13, color: "#ccc", fontWeight: 500 }}>
                      {currentPageName()}
                    </span>

                    {publishing ? (
                      <span style={{ display: "inline-flex", alignItems: "center", gap: 4, fontSize: 11, color: "#60a5fa", whiteSpace: "nowrap" }}>
                        <Loader2 size={12} className="animate-spin" /> Publishing…
                      </span>
                    ) : isDirty && (
                      <span style={{ fontSize: 11, color: "#f59e0b", whiteSpace: "nowrap" }}>
                        ● Unpublished
                      </span>
                    )}
                  </div>
                  {/* Puck's own Publish button: no presses while one is in flight */}
                  <span
                    aria-disabled={publishing || saving}
                    style={{
                      display: "inline-flex",
                      pointerEvents: publishing || saving ? "none" : undefined,
                      opacity: publishing || saving ? 0.5 : 1,
                    }}
                  >
                    {children}
                  </span>
                </>
              ),
            }}
          />
        </div>
      </div>
    </KennelDataProvider>
  );
}
