"use client";

import { useEffect } from "react";
import { MapContainer, TileLayer, Marker, useMap } from "react-leaflet";
import L from "leaflet";
import { MapPin } from "lucide-react";
import type { GlobalRunRow } from "@/lib/api";

const pinIcon = L.icon({
  iconUrl: "/images/map_pin_foot.png",
  iconSize: [74, 88],
  iconAnchor: [37, 88],
});

function RecenterMap({ lat, lon }: { lat: number; lon: number }) {
  const map = useMap();
  useEffect(() => {
    map.setView([lat, lon], 15);
  }, [map, lat, lon]);
  return null;
}

function parseW3w(json: string | null): string | null {
  if (!json) return null;
  try {
    const p = JSON.parse(json) as { map?: string; words?: string };
    return p.map ?? (p.words ? `https://what3words.com/${p.words}` : null);
  } catch { return null; }
}

interface RunLocationMapProps {
  run: GlobalRunRow;
}

export default function RunLocationMap({ run }: RunLocationMapProps) {
  if (!run.Latitude || !run.Longitude) {
    return (
      <div className="h-full flex flex-col items-center justify-center gap-3 text-white/50">
        <MapPin className="h-10 w-10" />
        <p className="text-lg font-semibold">No location data for this run</p>
      </div>
    );
  }

  const w3wUrl = parseW3w(run.w3wJson);

  const addressLines = [
    run.LocationStreet,
    [run.LocationCity, run.LocationPostCode].filter(Boolean).join(", "),
    [run.LocationRegion, run.LocationCountry].filter(Boolean).join(", "),
  ].filter(Boolean);

  return (
    <div className="relative h-full w-full">
      <MapContainer
        center={[run.Latitude, run.Longitude]}
        zoom={15}
        style={{ height: "100%", width: "100%" }}
        zoomControl
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <RecenterMap lat={run.Latitude} lon={run.Longitude} />
        <Marker position={[run.Latitude, run.Longitude]} icon={pinIcon} />
      </MapContainer>

      {/* Address overlay */}
      <div className="absolute bottom-0 left-0 right-0 z-[1000] bg-black/70 backdrop-blur-sm px-4 py-3 space-y-0.5">
        {run.LocationOneLineDesc && (
          <p className="text-sm font-semibold text-white leading-snug">
            {run.LocationOneLineDesc}
          </p>
        )}
        {addressLines.map((line, i) => (
          <p key={i} className="text-xs text-white/70 leading-snug">
            {line}
          </p>
        ))}
        {w3wUrl && (
          <a
            href={w3wUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-block text-xs text-white/50 hover:text-white/80 transition-colors pt-0.5"
          >
            /// What3Words
          </a>
        )}
      </div>
    </div>
  );
}
