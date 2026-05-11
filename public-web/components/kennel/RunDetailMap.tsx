"use client";

import { useEffect } from "react";
import { MapContainer, TileLayer, Marker, useMap } from "react-leaflet";
import L from "leaflet";

const pinIcon = L.icon({
  iconUrl: "/images/map_pin_foot.png",
  iconSize: [74, 88],
  iconAnchor: [37, 88],
});

function RecenterMap({ lat, lon }: { lat: number; lon: number }) {
  const map = useMap();
  useEffect(() => { map.setView([lat, lon], 15); }, [map, lat, lon]);
  return null;
}

export default function RunDetailMap({ lat, lon }: { lat: number; lon: number }) {
  return (
    <MapContainer
      center={[lat, lon]}
      zoom={15}
      style={{ height: "100%", width: "100%" }}
      zoomControl
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <RecenterMap lat={lat} lon={lon} />
      <Marker position={[lat, lon]} icon={pinIcon} />
    </MapContainer>
  );
}
