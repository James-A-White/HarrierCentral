import L from "leaflet";

/**
 * Makes Leaflet survive being torn down in the wrong order.
 *
 * React deletes a subtree parent-first, so when a page holding a map is
 * unmounted, `MapContainer`'s cleanup runs `map.remove()` — which drops the
 * panes and the SVG renderer and empties `_layers` — and only then do the
 * child layers' cleanups run. react-leaflet then asks the dead map to remove
 * a layer it no longer has, and Leaflet 1.9.4 throws twice over:
 *
 *   Map.removeLayer()  → `stamp(layer)` on a null layer
 *                        "Cannot use 'in' operator to search for '_leaflet_id' in null"
 *   Path.onRemove()    → `this._renderer._removePath(this)` with no renderer
 *                        "Cannot read properties of undefined (reading '_removePath')"
 *
 * Both are raised while the thing is being destroyed anyway, so there is
 * nothing to salvage and nothing for the visitor to lose — except that an
 * error thrown during unmount reaches the nearest error boundary, and on the
 * kennel pages that was the root one, which replaces the whole document.
 * 43 visitors lost a run page to this between 17 and 21 September 2026.
 *
 * The two guards below make the already-meaningless case a no-op instead of
 * a throw. Neither swallows a real failure: a layer that is absent has
 * nothing to remove, and a path with no renderer never had a `_path` element
 * to detach.
 */
let hardened = false;

export function hardenLeafletTeardown(): void {
  if (hardened || typeof window === "undefined") return;
  hardened = true;

  const removeLayer = L.Map.prototype.removeLayer;
  L.Map.prototype.removeLayer = function (this: L.Map, layer: L.Layer) {
    // stamp(null) throws; a layer that isn't there is already removed.
    if (!layer) return this;
    return removeLayer.call(this, layer);
  };

  const pathOnRemove = L.Path.prototype.onRemove;
  L.Path.prototype.onRemove = function (this: L.Path, map: L.Map) {
    // No renderer means no `_path` in the DOM to take out.
    if (!(this as unknown as { _renderer?: unknown })._renderer) return this;
    return pathOnRemove.call(this, map);
  };
}

hardenLeafletTeardown();
