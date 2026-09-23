import L from "leaflet";

/**
 * Makes Leaflet survive being built up or torn down in the wrong order.
 *
 * React commits a subtree's deletion parent-first, so when a page holding a
 * map goes away, `MapContainer`'s cleanup runs `map.remove()` — dropping the
 * panes, the SVG renderer and `_layers` — and only then do the child layers'
 * cleanups run. react-leaflet then works against a map that is already gone,
 * and Leaflet 1.9.4 throws from four places, two on the way out:
 *
 *   Map.removeLayer()  → `stamp(layer)` on a null layer
 *                        "Cannot use 'in' operator to search for '_leaflet_id' in null"
 *   Path.onRemove()    → `this._renderer._removePath(this)` with no renderer
 *                        "Cannot read properties of undefined (reading '_removePath')"
 *
 * two on the way in, when a layer is *added* to a map whose panes have gone
 * (or in a client with neither SVG nor canvas, where `getRenderer` returns
 * null by design):
 *
 *   Map.getRenderer()  → `hasLayer(renderer)` where the renderer came back null
 *   Path.onAdd()       → `this._renderer._initPath(this)` with no renderer
 *
 * and then, once such a path exists, every later touch of it:
 *
 *   Path.redraw() / _reset() / _update() / bringToFront() / bringToBack()
 *                      → `this._renderer.<...>` on null
 *
 * All four fire around a map that cannot draw anything, so there is nothing
 * to salvage — except that an error thrown during a React commit reaches the
 * nearest error boundary, and before `app/error.tsx` existed that was the
 * root one, which replaces the whole document. 43 visitors lost a run page to
 * this between 17 and 21 September 2026.
 *
 * The guards below make the already-meaningless case a no-op instead of a
 * throw. None of them swallows a real failure: a layer that is absent has
 * nothing to remove, a null layer is not on the map, and a path with no
 * renderer has no `_path` element to create or detach.
 *
 * They are not silent, though. A missing renderer on the way IN can also mean
 * a real ordering bug in our own code — a `<Polyline pane="…">` rendered
 * before its `<Pane>` — and the symptom of that would be a trail that quietly
 * fails to draw. So the first trip per page load is reported to the same
 * place every other web error goes, under its own source.
 */
let hardened = false;
let reported = false;

/** Says once per page load that a guard fired, so a silent miss is visible. */
function reportGuard(reason: string): void {
  if (reported) return;
  reported = true;
  try {
    void fetch("/api/web-error", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        source: "leaflet-guard",
        message: `Leaflet teardown guard: ${reason}`,
        stack: new Error(reason).stack?.slice(0, 2000),
        url: window.location.pathname + window.location.search,
      }),
      keepalive: true,
    });
  } catch {
    /* reporting a guard must never be worse than the throw it replaced */
  }
}

/** Leaflet keeps these on the instance; they are not in the public types. */
type PathInternals = { _renderer?: unknown };

export function hardenLeafletTeardown(): void {
  if (hardened || typeof window === "undefined") return;
  hardened = true;

  // ── On the way out ──────────────────────────────────────────────────────
  const removeLayer = L.Map.prototype.removeLayer;
  L.Map.prototype.removeLayer = function (this: L.Map, layer: L.Layer) {
    if (!layer) return this;
    return removeLayer.call(this, layer);
  };

  const pathOnRemove = L.Path.prototype.onRemove;
  L.Path.prototype.onRemove = function (this: L.Path, map: L.Map) {
    if (!(this as unknown as PathInternals)._renderer) return this;
    return pathOnRemove.call(this, map);
  };

  // ── On the way in ───────────────────────────────────────────────────────
  // `getRenderer` asks `hasLayer(renderer)` and then `addLayer(renderer)`.
  // When the renderer came back null both throw on `stamp(null)`, so guarding
  // only the first would move the throw one frame along rather than remove it.
  const hasLayer = L.Map.prototype.hasLayer;
  L.Map.prototype.hasLayer = function (this: L.Map, layer: L.Layer) {
    if (!layer) return false;
    return hasLayer.call(this, layer);
  };

  const addLayer = L.Map.prototype.addLayer;
  L.Map.prototype.addLayer = function (this: L.Map, layer: L.Layer) {
    if (!layer) {
      reportGuard("addLayer called with no layer (map has no renderer)");
      return this;
    }
    return addLayer.call(this, layer);
  };

  const pathOnAdd = L.Path.prototype.onAdd;
  L.Path.prototype.onAdd = function (this: L.Path, map: L.Map) {
    if (!(this as unknown as PathInternals)._renderer) {
      reportGuard("Path.onAdd with no renderer — nothing drawn");
      return this;
    }
    return pathOnAdd.call(this, map);
  };

  // ── After the way in ────────────────────────────────────────────────────
  // A path that was let in with no renderer is still held by react-leaflet,
  // which calls setLatLngs → redraw when its positions prop changes, and
  // Leaflet's move/zoom handlers call _reset → _update. Every one of those
  // ends at `this._renderer.<something>`. Six visitors found this the day
  // after the inbound guards shipped: the throw had moved from mount to the
  // first update. This closes the set — there is nothing else on Path that
  // dereferences the renderer.
  type RendererMethod = "redraw" | "bringToFront" | "bringToBack" | "_reset" | "_update";
  const proto = L.Path.prototype as unknown as Record<RendererMethod, (this: L.Path) => unknown>;
  for (const name of ["redraw", "bringToFront", "bringToBack", "_reset", "_update"] as RendererMethod[]) {
    const original = proto[name];
    if (typeof original !== "function") continue;
    proto[name] = function (this: L.Path) {
      if (!(this as unknown as PathInternals)._renderer) return this;
      return original.call(this);
    };
  }
}

hardenLeafletTeardown();
