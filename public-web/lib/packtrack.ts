export interface TrackPoint {
  lat: number;
  lng: number;
  acc: number;
  timestampMs: number;
  type?: string;
}

export interface UserTrack {
  id: string;
  positions: TrackPoint[];
}

export interface PackTrackPayload {
  eventId: string;
  latestServerTimestampMs?: string;
  users: UserTrack[];
}

export async function fetchPackTrack(eventId: string): Promise<PackTrackPayload | null> {
  try {
    const res = await fetch(`/api/packtrack?eventId=${encodeURIComponent(eventId)}`);
    if (!res.ok) {
      console.error(`[packtrack] client fetch failed: ${res.status}`, await res.text());
      return null;
    }
    const data = await res.json() as PackTrackPayload;
    console.log(`[packtrack] eventId=${eventId} users=${data.users?.length ?? 0}`, data);
    return data;
  } catch (err) {
    console.error("[packtrack] client fetch error:", err);
    return null;
  }
}
