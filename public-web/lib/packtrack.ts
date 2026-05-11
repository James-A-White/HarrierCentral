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
    if (!res.ok) return null;
    return (await res.json()) as PackTrackPayload;
  } catch {
    return null;
  }
}
