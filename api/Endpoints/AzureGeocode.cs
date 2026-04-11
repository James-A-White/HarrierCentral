using System.Net;

namespace HcWebApi.Endpoints
{
    public static class AzureGeocode
    {
        private static string SubscriptionKey =>
            Environment.GetEnvironmentVariable("AzureMapsSubscriptionKey")
            ?? throw new InvalidOperationException("AzureMapsSubscriptionKey is not set in the environment.");

        public static async Task<string> ReverseGeocode(string lat, string lon)
        {
            string subscriptionKey = SubscriptionKey;
            string url = $"https://atlas.microsoft.com/search/address/reverse/JSON" +
                         $"?subscription-key={subscriptionKey}&api-version=1.0&query={lat},{lon}&radius=1000";

            using HttpClient client = new();
            using HttpResponseMessage response = await client.GetAsync(url);
            using HttpContent content = response.Content;

            return await content.ReadAsStringAsync();
        }

        public static async Task<string> GeocodePlace(
            string placeName,
            string kennelLat,
            string kennelLon,
            string countryCodes)
        {
            string subscriptionKey = SubscriptionKey;
            string url = $"https://atlas.microsoft.com/search/fuzzy/JSON" +
                         $"?subscription-key={subscriptionKey}&api-version=1.0" +
                         $"&typeahead=false&limit=25&minFuzzyLevel=1&maxFuzzyLevel=4" +
                         $"&query={WebUtility.UrlEncode(placeName)}" +
                         $"&lat={kennelLat}&lon={kennelLon}&countrySet={countryCodes}";

            using HttpClient client = new();
            using HttpResponseMessage response = await client.GetAsync(url);

            if (!response.IsSuccessStatusCode) return "<no result>";

            using HttpContent content = response.Content;
            return await content.ReadAsStringAsync();
        }

        public static async Task<GeocodeResult?> Geocode(
            string  address,
            string  kennelLat,
            string  kennelLon,
            bool    reverse,
            string  countryCode,
            decimal maxLat = 90m,
            decimal minLat = -90m,
            decimal maxLon = 180m,
            decimal minLon = -180m)
        {
            string subscriptionKey = SubscriptionKey;
            string url = reverse
                ? $"https://atlas.microsoft.com/search/address/reverse/JSON" +
                  $"?subscription-key={subscriptionKey}&api-version=1.0&query={address}&radius=1000"
                : $"https://atlas.microsoft.com/search/fuzzy/JSON" +
                  $"?subscription-key={subscriptionKey}&api-version=1.0" +
                  $"&typeahead=false&limit=25&minFuzzyLevel=1&maxFuzzyLevel=4" +
                  $"&query={WebUtility.UrlEncode(address)}" +
                  $"&lat={kennelLat}&lon={kennelLon}&countrySet={countryCode}";

            const double scoreThreshold = 0.25;

            using HttpClient client = new();
            using HttpResponseMessage response = await client.GetAsync(url);
            using HttpContent content = response.Content;

            string result = await content.ReadAsStringAsync();

            if (!reverse)
            {
                var places = Newtonsoft.Json.JsonConvert.DeserializeObject<AzureFuzzyPlace>(result);
                if (places?.results == null) return null;

                var geoResults = new List<GeocodeResult>();
                double highScore = 10000;

                for (int i = 0; i < places.results.Count; i++)
                {
                    var r = places.results[i];

                    // Skip results outside the bounding box
                    if (r.position.lat != null && r.position.lon != null)
                    {
                        if ((decimal)r.position.lat < minLat || (decimal)r.position.lat > maxLat) continue;
                        if ((decimal)r.position.lon < minLon || (decimal)r.position.lon > maxLon) continue;
                    }

                    if (i == 0) highScore = r.score;
                    if (highScore > r.score + scoreThreshold) continue;

                    double score = r.score;
                    if (r.poi != null)                                   score += 0.06;
                    if (!string.IsNullOrWhiteSpace(r.poi?.name))         score += 0.04;
                    if (!string.IsNullOrWhiteSpace(r.poi?.phone))        score += 0.02;
                    if (!string.IsNullOrWhiteSpace(r.poi?.url))          score += 0.02;
                    if (r.address != null)                               score += 0.05;
                    if (!string.IsNullOrWhiteSpace(r.address?.streetName)) score += 0.03;
                    if (r.address?.postalCode != null)                   score += (r.address.postalCode.Length * 0.005);

                    var geo = new GeocodeResult
                    {
                        PlaceName      = places.summary.query?.Replace("'", "''") ?? "",
                        ResolvedName   = (r.poi?.name ?? r.address?.freeformAddress ?? "<No resolved name>").Replace("'", "''"),
                        FreeformAddress = r.address?.freeformAddress?.Replace("'", "''") ?? "",
                        City           = r.address?.municipality?.Replace("'", "''") ?? "",
                        Country        = r.address?.country?.Replace("'", "''") ?? "",
                        SubRegion      = r.address?.countrySecondarySubdivision?.Replace("'", "''") ?? "",
                        Region         = (r.address?.countrySubdivisionName ?? r.address?.countrySubdivision ?? "").Replace("'", "''"),
                        Street         = ((r.address?.streetNumber?.Replace("'", "''") ?? "") + " " +
                                          (r.address?.streetName?.Replace("'", "''") ?? "")).Trim(),
                        Zip            = r.address?.extendedPostalCode?.Replace("'", "''")
                                         ?? r.address?.postalCode?.Replace("'", "''") ?? "",
                        Latitude       = r.position.lat ?? -1000.0,
                        Longitude      = r.position.lon ?? -1000.0,
                        internalScore  = score,
                    };

                    // Normalise US ZIP+4 codes (API returns 9 digits, no dash)
                    if (r.address?.countryCode == "US" && geo.Zip != null)
                    {
                        geo.Zip = geo.Zip.Replace("-", "");
                        if (geo.Zip.Length == 9)
                            geo.Zip = geo.Zip[..5] + "-" + geo.Zip[5..];
                    }

                    geoResults.Add(geo);
                }

                if (geoResults.Count == 0) return null;

                geoResults.Sort(new GeoSorter());
                return geoResults.First();
            }
            else
            {
                var places = Newtonsoft.Json.JsonConvert.DeserializeObject<AzureAddressPlace>(result);
                if (places == null || !places.addresses.Any()) return null;

                var a = places.addresses[0].address;
                return new GeocodeResult
                {
                    PlaceName = address,
                    City      = a.municipality?.Replace("'", "''") ?? "",
                    Country   = a.country?.Replace("'", "''") ?? "",
                    Region    = (a.countrySubdivision ?? "").Replace("'", "''"),
                    Street    = ((a.streetNumber?.Replace("'", "''") ?? "") + " " +
                                 (a.streetName?.Replace("'", "''") ?? "")).Trim(),
                    Zip       = a.extendedPostalCode?.Replace("'", "''")
                                ?? a.postalCode?.Replace("'", "''") ?? "",
                };
            }
        }

        // ---------------------------------------------------------------------------
        // Sort helper
        // ---------------------------------------------------------------------------

        public class GeoSorter : IComparer<GeocodeResult>
        {
            public int Compare(GeocodeResult? c1, GeocodeResult? c2) =>
                (c2?.internalScore ?? 0).CompareTo(c1?.internalScore ?? 0);
        }

        // ---------------------------------------------------------------------------
        // Result DTO
        // ---------------------------------------------------------------------------

        public class GeocodeResult
        {
            public string? PlaceName       { get; set; }
            public string? ResolvedName    { get; set; }
            public string? FreeformAddress { get; set; }
            public string? City            { get; set; }
            public string? Country         { get; set; }
            public string? Region          { get; set; }
            public string? SubRegion       { get; set; }
            public string? Street          { get; set; }
            public string? Zip             { get; set; }
            public double  Latitude        { get; set; }
            public double  Longitude       { get; set; }
            public double  internalScore   { get; set; }
        }

        // ---------------------------------------------------------------------------
        // Azure Maps fuzzy-search response DTOs
        // ---------------------------------------------------------------------------

        public class Summary
        {
            public string? query        { get; set; }
            public string? queryType    { get; set; }
            public int     queryTime    { get; set; }
            public int     numResults   { get; set; }
            public int     offset       { get; set; }
            public int     totalResults { get; set; }
            public int     fuzzyLevel   { get; set; }
            public GeoBias? geoBias     { get; set; }
        }

        public class GeoBias
        {
            public double lat { get; set; }
            public double lon { get; set; }
        }

        public class Address
        {
            public string? streetNumber                  { get; set; }
            public string? streetName                    { get; set; }
            public string? municipalitySubdivision       { get; set; }
            public string? municipality                  { get; set; }
            public string? countrySecondarySubdivision   { get; set; }
            public string? countryTertiarySubdivision    { get; set; }
            public string? countrySubdivision            { get; set; }
            public string? postalCode                    { get; set; }
            public string? extendedPostalCode            { get; set; }
            public string? countryCode                   { get; set; }
            public string? country                       { get; set; }
            public string? countryCodeISO3               { get; set; }
            public string? freeformAddress               { get; set; }
            public string? countrySubdivisionName        { get; set; }
        }

        public class Position
        {
            public double? lat { get; set; }
            public double? lon { get; set; }
        }

        public class TopLeftPoint  { public double lat { get; set; } public double lon { get; set; } }
        public class BtmRightPoint { public double lat { get; set; } public double lon { get; set; } }

        public class Viewport
        {
            public TopLeftPoint?  topLeftPoint  { get; set; }
            public BtmRightPoint? btmRightPoint { get; set; }
        }

        public class Position2    { public double lat { get; set; } public double lon { get; set; } }
        public class EntryPoint   { public string? type { get; set; } public Position2? position { get; set; } }
        public class From         { public double lat   { get; set; } public double lon { get; set; } }
        public class To           { public double lat   { get; set; } public double lon { get; set; } }

        public class AddressRanges
        {
            public string? rangeLeft  { get; set; }
            public string? rangeRight { get; set; }
            public From?   from       { get; set; }
            public To?     to         { get; set; }
        }

        public class Poi
        {
            public string?           name            { get; set; }
            public List<CategorySet>? categorySet    { get; set; }
            public string?           url             { get; set; }
            public List<string>?     categories      { get; set; }
            public List<Classification>? classifications { get; set; }
            public string?           phone           { get; set; }
        }

        public class CategorySet     { public int id { get; set; } }
        public class Name            { public string? nameLocale { get; set; } public string? name { get; set; } }
        public class Classification  { public string? code { get; set; } public List<Name>? names { get; set; } }

        public class DataSources
        {
            public List<PoiDetail>? poiDetails { get; set; }
            public Geometry?        geometry   { get; set; }
        }

        public class PoiDetail { public string? id { get; set; } public string? sourceName { get; set; } }
        public class Geometry  { public string? id { get; set; } }

        public class FuzzyResult
        {
            public string?            type        { get; set; }
            public string?            id          { get; set; }
            public double             score       { get; set; }
            public double             dist        { get; set; }
            public Poi?               poi         { get; set; }
            public Address?           address     { get; set; }
            public Position           position    { get; set; } = new();
            public Viewport?          viewport    { get; set; }
            public List<EntryPoint>?  entryPoints { get; set; }
            public DataSources?       dataSources { get; set; }
        }

        public class AzureFuzzyPlace
        {
            public Summary            summary { get; set; } = new();
            public List<FuzzyResult>? results { get; set; }
        }

        // ---------------------------------------------------------------------------
        // Azure Maps reverse-geocode response DTOs
        // ---------------------------------------------------------------------------

        public class AapSummary { public int queryTime { get; set; } public int numResults { get; set; } }

        public class AapBoundingBox
        {
            public string? northEast { get; set; }
            public string? southWest { get; set; }
            public string? entity    { get; set; }
        }

        public class AapAddress2
        {
            public string?           buildingNumber          { get; set; }
            public string?           streetNumber            { get; set; }
            public List<object>?     routeNumbers            { get; set; }
            public string?           street                  { get; set; }
            public string?           streetName              { get; set; }
            public string?           streetNameAndNumber     { get; set; }
            public string?           countryCode             { get; set; }
            public string?           countrySubdivision      { get; set; }
            public string?           municipality            { get; set; }
            public string?           postalCode              { get; set; }
            public string?           municipalitySubdivision { get; set; }
            public string?           country                 { get; set; }
            public string?           countryCodeISO3         { get; set; }
            public string?           freeformAddress         { get; set; }
            public AapBoundingBox?   boundingBox             { get; set; }
            public string?           extendedPostalCode      { get; set; }
            public string?           localName               { get; set; }
            public string?           streetNumber2           { get; set; }
        }

        public class AapAddress
        {
            public AapAddress2 address  { get; set; } = new();
            public string?     position { get; set; }
        }

        public class AzureAddressPlace
        {
            public AapSummary?      summary   { get; set; }
            public List<AapAddress> addresses { get; set; } = new();
        }
    }
}
