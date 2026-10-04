namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Where a runner's track came from, as recorded on
    /// HC.HasherEventMap.TrackSource and returned per runner by GetPositions
    /// (James, 2026-10-04: "record the source of the track … PackTrack
    /// native, Strava, Garmin etc." and "I want this to be displayable").
    ///
    /// A short lowercase key, never free text, so every client can map it to
    /// a label: packtrack (the app's own live recording), strava, garmin,
    /// fitbit, apple, coros, suunto, polar, wahoo, komoot, or file when an
    /// imported file does not say what made it.
    /// </summary>
    public static class TrackSources
    {
        public const string PackTrack = "packtrack";
        public const string Strava = "strava";
        public const string File = "file";

        /// <summary>
        /// From a GPX <c>creator</c> attribute or a TCX <c>&lt;Creator&gt;&lt;Name&gt;</c>:
        /// "StravaGPX", "Garmin Connect", "Fitbit", "Apple Health Export",
        /// "Harrier Central" (our own GPX export) …
        /// </summary>
        public static string? FromCreator(string? creator)
        {
            if (string.IsNullOrWhiteSpace(creator)) return null;
            string c = creator.ToLowerInvariant();
            if (c.Contains("harrier central")) return PackTrack;
            if (c.Contains("strava")) return Strava;
            if (c.Contains("garmin") || c.Contains("forerunner") || c.Contains("fenix") || c.Contains("edge ")) return "garmin";
            if (c.Contains("fitbit")) return "fitbit";
            if (c.Contains("apple") || c.Contains("healthfit") || c.Contains("workoutdoors")) return "apple";
            if (c.Contains("coros")) return "coros";
            if (c.Contains("suunto")) return "suunto";
            if (c.Contains("polar")) return "polar";
            if (c.Contains("wahoo")) return "wahoo";
            if (c.Contains("komoot")) return "komoot";
            return null;
        }

        /// <summary>A FIT file_id manufacturer code (FIT profile).</summary>
        public static string? FromFitManufacturer(int code) => code switch
        {
            1 or 15 or 13 => "garmin",   // garmin, dynastream, dynastream_oem
            23 => "suunto",
            123 => "polar",
            32 => "wahoo",
            265 => Strava,
            294 => "coros",
            _ => null,
        };
    }
}
