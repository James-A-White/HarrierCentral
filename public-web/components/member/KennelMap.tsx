"use client";

/**
 * The app's kennel page map (kennel_admin_main._buildMapAndInfoSection):
 * 300 px high, centred on the kennel's city with the hash-foot pin. The
 * app has a yellow zoom slider; the browser's map has its own controls.
 */
import dynamic from "next/dynamic";

const Inner = dynamic(() => import("./KennelMapInner"), {
  ssr: false,
  loading: () => <div className="h-[300px] w-full animate-pulse bg-black/30" />,
});

export function KennelMap({ lat, lon, name }: { lat: number; lon: number; name: string }) {
  return (
    <div className="h-[300px] w-full overflow-hidden">
      <Inner lat={lat} lon={lon} name={name} />
    </div>
  );
}
