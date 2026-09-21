"use client";

import { MapContainer, TileLayer, Marker } from "react-leaflet";
import L from "leaflet";
import "@/lib/leaflet-teardown";

const pinIcon = L.icon({
  iconUrl: "/images/map_pin_foot.png",
  iconSize: [56, 67],
  iconAnchor: [28, 67],
});

export default function KennelMapInner({ lat, lon, name }: { lat: number; lon: number; name: string }) {
  return (
    <MapContainer center={[lat, lon]} zoom={11} style={{ height: "100%", width: "100%" }} zoomControl scrollWheelZoom={false}>
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <Marker position={[lat, lon]} icon={pinIcon} title={name} />
    </MapContainer>
  );
}
