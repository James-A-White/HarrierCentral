"use client";

import { useState, useRef } from "react";
import { Globe, GlobeOff, Eye, EyeOff, Plus, Trash2, GripVertical } from "lucide-react";
import type { PageConfig, PageStatus, SiteConfig } from "@/lib/page-layout";

interface PagePanelProps {
  siteConfig: SiteConfig;
  currentPageId: string;
  onSelectPage: (pageId: string) => void;
  onUpdateConfig: (config: SiteConfig) => void;
}

function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function isValidSlug(slug: string): boolean {
  return /^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/.test(slug);
}

export function PagePanel({ siteConfig, currentPageId, onSelectPage, onUpdateConfig }: PagePanelProps) {
  const [addingPage, setAddingPage]                 = useState(false);
  const [newName, setNewName]                       = useState("");
  const [newSlug, setNewSlug]                       = useState("");
  const [slugManuallyEdited, setSlugManuallyEdited] = useState(false);
  const [slugError, setSlugError]                   = useState("");

  const dragIndexRef  = useRef<number | null>(null);
  const [dragOverIdx, setDragOverIdx] = useState<number | null>(null);

  const pages = [...siteConfig.pages].sort((a, b) => a.order - b.order);

  // ── helpers ───────────────────────────────────────────────────────────────

  function replacePages(newPages: PageConfig[]) {
    onUpdateConfig({
      ...siteConfig,
      pages: newPages.map((p, i) => ({ ...p, order: i })),
    });
  }

  function patchPage(id: string, patch: Partial<PageConfig>) {
    onUpdateConfig({
      ...siteConfig,
      pages: siteConfig.pages.map(p => p.id === id ? { ...p, ...patch } : p),
    });
  }

  function toggleActive(page: PageConfig) {
    const next: PageStatus = page.status === "draft" ? "url-only" : "draft";
    patchPage(page.id, { status: next });
  }

  function toggleMenu(page: PageConfig) {
    if (page.status === "draft") return;
    const next: PageStatus = page.status === "menu" ? "url-only" : "menu";
    patchPage(page.id, { status: next });
  }

  function deletePage(id: string) {
    replacePages(pages.filter(p => p.id !== id));
  }

  // ── drag-to-reorder ───────────────────────────────────────────────────────

  function handleDragStart(index: number) { dragIndexRef.current = index; }

  function handleDragOver(e: React.DragEvent, index: number) {
    e.preventDefault();
    setDragOverIdx(index);
  }

  function handleDrop(e: React.DragEvent, targetIndex: number) {
    e.preventDefault();
    const from = dragIndexRef.current;
    if (from === null || from === targetIndex) { setDragOverIdx(null); return; }
    const reordered = [...pages];
    const [moved] = reordered.splice(from, 1);
    reordered.splice(targetIndex, 0, moved);
    replacePages(reordered);
    dragIndexRef.current = null;
    setDragOverIdx(null);
  }

  function handleDragEnd() {
    dragIndexRef.current = null;
    setDragOverIdx(null);
  }

  // ── add-page form ─────────────────────────────────────────────────────────

  function handleNameChange(value: string) {
    setNewName(value);
    if (!slugManuallyEdited) setNewSlug(slugify(value));
  }

  function handleSlugChange(value: string) {
    const cleaned = value.toLowerCase().replace(/[^a-z0-9-]/g, "");
    setNewSlug(cleaned);
    setSlugManuallyEdited(true);
    setSlugError(cleaned && !isValidSlug(cleaned)
      ? "Must start and end with a letter or number"
      : "");
  }

  function openAddForm() {
    setAddingPage(true);
    setNewName(""); setNewSlug(""); setSlugManuallyEdited(false); setSlugError("");
  }

  function cancelAdd() { setAddingPage(false); }

  function confirmAdd() {
    if (!newName.trim()) return;
    if (!newSlug || !isValidSlug(newSlug)) {
      setSlugError("Enter a valid slug (letters, numbers, dashes)");
      return;
    }
    if (siteConfig.pages.some(p => p.slug === newSlug)) {
      setSlugError("This slug is already in use");
      return;
    }
    const newPage: PageConfig = {
      id: `custom-${newSlug}-${Date.now()}`,
      name: newName.trim(),
      slug: newSlug,
      isDefault: false,
      status: "draft",
      order: siteConfig.pages.length,
      layout: null,
    };
    onUpdateConfig({ ...siteConfig, pages: [...siteConfig.pages, newPage] });
    setAddingPage(false);
  }

  // ── render ────────────────────────────────────────────────────────────────

  const INPUT: React.CSSProperties = {
    width: "100%",
    padding: "6px 8px",
    background: "#fff",
    border: "1px solid #d1d5db",
    borderRadius: 4,
    color: "#111",
    fontSize: 12,
    boxSizing: "border-box",
    outline: "none",
  };

  const ICON_BTN: React.CSSProperties = {
    background: "none",
    border: "none",
    cursor: "pointer",
    padding: 3,
    display: "flex",
    alignItems: "center",
    borderRadius: 3,
  };

  return (
    <div style={{
      width: 220,
      height: "100%",
      background: "#f7f7f7",
      borderRight: "1px solid #ddd",
      display: "flex",
      flexDirection: "column",
      fontFamily: "system-ui, sans-serif",
      flexShrink: 0,
    }}>
      {/* Header */}
      <div style={{
        padding: "10px 12px",
        borderBottom: "1px solid #e5e7eb",
        background: "#efefef",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
      }}>
        <span style={{
          fontSize: 11,
          fontWeight: 700,
          color: "#555",
          textTransform: "uppercase",
          letterSpacing: "0.07em",
        }}>
          Pages
        </span>
        <button style={{ ...ICON_BTN, color: "#666" }} onClick={openAddForm} title="Add custom page">
          <Plus size={14} color="#666" />
        </button>
      </div>

      {/* Page list */}
      <div style={{ flex: 1, overflowY: "auto" }}>
        {pages.map((page, index) => {
          const isSelected   = currentPageId === page.id;
          const isDraft      = page.status === "draft";
          const isInMenu     = page.status === "menu";
          const isDropTarget = dragOverIdx === index;

          return (
            <div
              key={page.id}
              draggable
              onDragStart={() => handleDragStart(index)}
              onDragOver={(e) => handleDragOver(e, index)}
              onDrop={(e) => handleDrop(e, index)}
              onDragEnd={handleDragEnd}
              onClick={() => onSelectPage(page.id)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 4,
                padding: "7px 8px",
                cursor: "pointer",
                background: isSelected ? "#dbeafe" : isDropTarget ? "#e9e9e9" : "transparent",
                borderLeft: isSelected ? "2px solid #2563eb" : "2px solid transparent",
                userSelect: "none",
                transition: "background 0.1s",
              }}
            >
              <GripVertical size={13} color="#ccc" style={{ flexShrink: 0, cursor: "grab" }} />

              <span style={{
                flex: 1,
                fontSize: 12,
                fontWeight: page.isDefault ? 700 : 400,
                color: isDraft ? "#aaa" : isSelected ? "#1d4ed8" : "#222",
                overflow: "hidden",
                textOverflow: "ellipsis",
                whiteSpace: "nowrap",
              }}>
                {page.name}
              </span>

              {/* Globe: active / draft */}
              <button
                style={ICON_BTN}
                onClick={(e) => { e.stopPropagation(); toggleActive(page); }}
                title={isDraft ? "Activate page" : "Set to draft"}
              >
                {isDraft
                  ? <GlobeOff size={13} color="#ccc" />
                  : <Globe    size={13} color="#16a34a" />}
              </button>

              {/* Eye: in menu / url-only */}
              <button
                style={{ ...ICON_BTN, cursor: isDraft ? "default" : "pointer" }}
                onClick={(e) => { e.stopPropagation(); toggleMenu(page); }}
                disabled={isDraft}
                title={isDraft ? "Activate page to control menu visibility" : (isInMenu ? "Remove from menu" : "Add to menu")}
              >
                {isInMenu
                  ? <Eye    size={13} color="#2563eb" />
                  : <EyeOff size={13} color={isDraft ? "#ddd" : "#bbb"} />}
              </button>

              {/* Trash: custom pages only */}
              {!page.isDefault && (
                <button
                  style={ICON_BTN}
                  onClick={(e) => { e.stopPropagation(); deletePage(page.id); }}
                  title="Delete page"
                >
                  <Trash2 size={12} color="#bbb" />
                </button>
              )}
            </div>
          );
        })}
      </div>

      {/* Add-page form */}
      {addingPage && (
        <div style={{ borderTop: "1px solid #e5e7eb", padding: "10px 12px", background: "#f0f0f0" }}>
          <div style={{ marginBottom: 6 }}>
            <input
              autoFocus
              placeholder="Page name"
              value={newName}
              onChange={(e) => handleNameChange(e.target.value)}
              onKeyDown={(e) => { if (e.key === "Enter") confirmAdd(); if (e.key === "Escape") cancelAdd(); }}
              style={INPUT}
            />
          </div>
          <div style={{ marginBottom: 6 }}>
            <input
              placeholder="url-slug"
              value={newSlug}
              onChange={(e) => handleSlugChange(e.target.value)}
              onKeyDown={(e) => { if (e.key === "Enter") confirmAdd(); if (e.key === "Escape") cancelAdd(); }}
              style={{ ...INPUT, border: `1px solid ${slugError ? "#dc2626" : "#d1d5db"}`, color: "#555" }}
            />
            {slugError && (
              <div style={{ fontSize: 10, color: "#dc2626", marginTop: 3, lineHeight: 1.4 }}>
                {slugError}
              </div>
            )}
          </div>
          <div style={{ display: "flex", gap: 6 }}>
            <button
              onClick={confirmAdd}
              style={{
                flex: 1, padding: "6px 0", background: "#2563eb", color: "#fff",
                border: "none", borderRadius: 4, fontSize: 12, fontWeight: 600, cursor: "pointer",
              }}
            >
              Add
            </button>
            <button
              onClick={cancelAdd}
              style={{
                padding: "6px 10px", background: "#fff", color: "#666",
                border: "1px solid #d1d5db", borderRadius: 4, fontSize: 12, cursor: "pointer",
              }}
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      {/* Legend */}
      <div style={{ padding: "8px 12px", borderTop: "1px solid #e5e7eb" }}>
        <div style={{ fontSize: 10, color: "#999", display: "flex", flexDirection: "column", gap: 3 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 5 }}>
            <Globe  size={10} color="#16a34a" /> Active
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 5 }}>
            <Eye    size={10} color="#2563eb" /> In menu
          </div>
        </div>
      </div>
    </div>
  );
}
