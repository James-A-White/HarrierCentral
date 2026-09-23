"use client";

/**
 * The app's Map tab on the web (E9.F7.S10): the upcoming runs of the
 * kennels I follow as pins, and me as a blue dot when I ask for it (one-tap
 * geolocation — no background tracking in a browser).
 */
import { useEffect, useMemo, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, CircleMarker, useMap } from "react-leaflet";
import L from "leaflet";
import { safeFlyTo } from "@/lib/leaflet-teardown";
import Link from "next/link";
import type { MyRun } from "@/lib/member-api";
import { formatRunDate, relativeTime } from "@/lib/member-format";

const pinIcon = L.icon({ iconUrl: "/images/map_pin_foot.png", iconSize: [37, 44], iconAnchor: [18, 44], popupAnchor: [0, -40] });

function FitToRuns({ points }: { points: [number, number][] }) {
  const map = useMap();
  useEffect(() => {
    if (points.length === 0) return;
    if (points.length === 1) { map.setView(points[0], 12); return; }
    map.fitBounds(L.latLngBounds(points), { padding: [40, 40], maxZoom: 13 });
  }, [map, points]);
  return null;
}

function FlyTo({ pos }: { pos: [number, number] | null }) {
  const map = useMap();
  useEffect(() => { if (pos) safeFlyTo(map, pos, 13); }, [map, pos]);
  return null;
}

export default function MyRunsMap({ runs }: { runs: MyRun[] }) {
  const located = useMemo(() => runs.filter((r) => r.Latitude && r.Longitude), [runs]);
  const points = useMemo(() => located.map((r) => [r.Latitude!, r.Longitude!] as [number, number]), [located]);
  const [me, setMe] = useState<[number, number] | null>(null);
  const [locating, setLocating] = useState(false);

  function locate() {
    if (!navigator.geolocation) return;
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (p) => { setMe([p.coords.latitude, p.coords.longitude]); setLocating(false); },
      () => setLocating(false),
      { enableHighAccuracy: true, timeout: 10_000 },
    );
  }

  return (
    <div className="relative overflow-hidden rounded-2xl" style={{ height: "70vh", minHeight: 360 }}>
      <MapContainer center={points[0] ?? [51.5, -0.12]} zoom={points.length ? 12 : 2} scrollWheelZoom className="h-full w-full" zoomControl>
        <TileLayer attribution="&copy; OpenStreetMap contributors" url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
        <FitToRuns points={points} />
        <FlyTo pos={me} />
        {located.map((r) => {
          const d = formatRunDate(r);
          return (
            <Marker key={r.PublicEventId} position={[r.Latitude!, r.Longitude!]} icon={pinIcon}>
              <Popup>
                <div className="text-sm text-zinc-900">
                  <p className="font-bold">{r.EventName}</p>
                  <p>{r.KennelShortName} · #{r.EventNumber}</p>
                  <p>{d.short} · {d.time} ({relativeTime(r.EventStartDatetimeGmt ?? r.EventStartDatetime)})</p>
                  {r.LocationOneLineDesc && <p>{r.LocationOneLineDesc}</p>}
                  <Link href={`/${r.KennelSlug}/${r.EventNumber}?back=/me/map`} className="underline">Open run</Link>
                </div>
              </Popup>
            </Marker>
          );
        })}
        {me && (
          <>
            <CircleMarker center={me} radius={12} pathOptions={{ color: "#fff", weight: 3, fillColor: "#2A7FFF", fillOpacity: 1 }} />
          </>
        )}
      </MapContainer>
      <button
        type="button" onClick={locate} disabled={locating}
        className="absolute right-3 top-3 z-[1000] rounded-full bg-white px-3 py-2 text-sm font-semibold text-zinc-900 shadow disabled:opacity-60"
      >
        {locating ? "Locating…" : me ? "📍 Me" : "📍 Where am I?"}
      </button>
      {located.length === 0 && (
        <div className="pointer-events-none absolute inset-x-0 bottom-3 z-[1000] text-center text-sm text-white drop-shadow">
          No upcoming runs with a location for the kennels you follow.
        </div>
      )}
    </div>
  );
}
