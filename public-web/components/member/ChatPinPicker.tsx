"use client";

/**
 * "Drop a pin" for a chat location (E9.F1.S12): tap the map to place the
 * pin, drag it to fine-tune, send. Leaflet touches `window` at import time,
 * so ChatThread loads this with next/dynamic and ssr: false.
 *
 * It opens on where the member is only when the browser has ALREADY been
 * given their location — asking here would put a permission prompt in front
 * of someone who chose the map precisely to avoid sharing where they are.
 */
import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { MapContainer, Marker, TileLayer, useMap, useMapEvents } from "react-leaflet";
import L from "leaflet";
import "@/lib/leaflet-teardown";
import { formatChatLocation } from "@/lib/chat-content";
import { HC_BLUE } from "@/components/member/app-look";

type LatLng = { lat: number; lng: number };

const pinIcon = L.divIcon({
  className: "",
  html: `<svg xmlns="http://www.w3.org/2000/svg" width="36" height="48" viewBox="0 0 24 32"><path d="M12 0C5.4 0 0 5.4 0 12c0 9 12 20 12 20s12-11 12-20C24 5.4 18.6 0 12 0z" fill="#dc2626" stroke="#fff" stroke-width="1.5"/><circle cx="12" cy="12" r="4.5" fill="#fff"/></svg>`,
  iconSize: [36, 48],
  iconAnchor: [18, 48],
});

function ClickToPlace({ onPlace }: { onPlace: (p: LatLng) => void }) {
  useMapEvents({ click: (e) => onPlace({ lat: e.latlng.lat, lng: e.latlng.lng }) });
  return null;
}

function FlyTo({ to }: { to: LatLng | null }) {
  const map = useMap();
  useEffect(() => { if (to) map.setView([to.lat, to.lng], 15); }, [map, to]);
  return null;
}

export default function ChatPinPicker({ onPick, onClose }: { onPick: (p: LatLng) => void; onClose: () => void }) {
  const [pin, setPin] = useState<LatLng | null>(null);
  const [here, setHere] = useState<LatLng | null>(null);

  useEffect(() => {
    let live = true;
    // Only when already granted: never prompt from the pin picker.
    navigator.permissions?.query({ name: "geolocation" }).then((st) => {
      if (!live || st.state !== "granted") return;
      navigator.geolocation.getCurrentPosition(
        (pos) => { if (live) setHere({ lat: pos.coords.latitude, lng: pos.coords.longitude }); },
        () => undefined,
        { maximumAge: 60_000, timeout: 10_000 },
      );
    }).catch(() => undefined);
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", onKey);
    return () => { live = false; window.removeEventListener("keydown", onKey); };
  }, [onClose]);

  return createPortal(
    <div className="fixed inset-0 z-[80] flex flex-col bg-black/70 p-3 sm:p-6" role="dialog" aria-modal="true" aria-label="Drop a pin">
      <div className="mx-auto flex h-full w-full max-w-3xl flex-col overflow-hidden rounded-2xl bg-white text-zinc-900 shadow-2xl">
        <div className="border-b border-zinc-200 px-4 py-3 text-center text-[18px] font-bold">Drop a pin</div>
        <div className="relative min-h-0 flex-1">
          <MapContainer center={[20, 0]} zoom={2} style={{ height: "100%", width: "100%" }} zoomControl>
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            <ClickToPlace onPlace={setPin} />
            <FlyTo to={here} />
            {pin && (
              <Marker position={[pin.lat, pin.lng]} icon={pinIcon} draggable
                eventHandlers={{ dragend: (e) => { const ll = (e.target as L.Marker).getLatLng(); setPin({ lat: ll.lat, lng: ll.lng }); } }} />
            )}
          </MapContainer>
        </div>
        <div className="flex flex-col items-center gap-2 border-t border-zinc-200 px-4 py-3">
          <p className="text-center text-[15px] tabular-nums text-zinc-600">
            {pin ? formatChatLocation(pin) : "Tap the map where the pin should go."}
          </p>
          <div className="flex flex-wrap justify-center gap-2">
            <button type="button" onClick={onClose}
              className="rounded-full border border-zinc-300 px-5 py-2 text-center text-[16px] font-semibold text-zinc-700 hover:bg-zinc-100">
              Cancel
            </button>
            <button type="button" disabled={!pin} onClick={() => pin && onPick(pin)}
              className="rounded-full px-5 py-2 text-center text-[16px] font-semibold text-white disabled:opacity-40" style={{ backgroundColor: HC_BLUE }}>
              Send this location
            </button>
          </div>
        </div>
      </div>
    </div>,
    document.body,
  );
}
