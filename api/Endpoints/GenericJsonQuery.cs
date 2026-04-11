using HtmlAgilityPack;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace HcWebApi.Endpoints
{
    public static class GenericJsonQuery
    {
        // In-process caches — persist across timer invocations for the lifetime of the host.
        private static Dictionary<string, string>       _jsonResultHashValues            = new();
        private static Dictionary<string, ParsedResult> _urlToLatLong                   = new();
        private static Dictionary<string, long>         _recordLastUpdatedForIntegration = new();

        public const string GoogleUrlShortener    = "https://goo.gl/maps/";
        public const string GooglePageUrlShortener = "https://g.page/";
        public const string GoogleDir             = "https://www.google.com/maps/dir/";
        public const string GooglePlace           = "https://www.google.com/maps/place/";
        public const string GoogleMapsQ           = "http://maps.google.com/maps?q=";
        public const string GoogleMapsQs          = "https://maps.google.com/maps?q=";
        public const string BingMaps              = "https://www.bing.com/maps?";
        public const string GoogleAppsMaps        = "https://maps.app.goo.gl/WXNeK";

        public class ParsedResult
        {
            public double  pinLat       = -99;
            public double  pinLon       = -999;
            public double  mapCenterLat = -99;
            public double  mapCenterLon = -999;
            public string? originalUrl;
            public string? address;
            public string? originalUrlMD5;
            public string? location;
            public string? geoJson;

            public bool isComplete    => !string.IsNullOrEmpty(address) && pinLat != -99 && pinLon != -999;
            public bool isNotComplete => !isComplete;
        }

        private static string DecodeUrlString(string url)
        {
            string newUrl;
            while ((newUrl = Uri.UnescapeDataString(url)) != url)
                url = newUrl;
            while ((newUrl = WebUtility.HtmlDecode(url)) != url)
                url = newUrl;
            return newUrl.Replace("\t", "");
        }

        public static string RemoveHTML(string text)
        {
            text = text.Replace("&nbsp;", " ").Replace("<br>", "\n");
            return Regex.Replace(text, "<[^>]+>", string.Empty).Replace("\t", "");
        }

        public static async Task<object[]> ImportEvents(
            string  connectionStr,
            ILogger log,
            string  query,
            string  integrationId,
            string  integrationName,
            DateTime baseTime,
            decimal maxLat,
            decimal minLat,
            decimal maxLon,
            decimal minLon)
        {
            int errorCount    = 0;
            int recordsRead   = 0;
            int recordsWritten = 0;

            // On first run for this integration, assume any records updated in the last 30 days
            // may need processing. Subsequent runs use the timestamp returned by the DB.
            if (!_recordLastUpdatedForIntegration.ContainsKey(integrationId))
                _recordLastUpdatedForIntegration[integrationId] =
                    DateTimeOffset.Now.AddDays(-30).ToUnixTimeSeconds();

            // Replace the timestamp token in the query URL with the actual Unix timestamp minus
            // one second, ensuring the last-seen record is always returned on each call.
            query = query.Replace(
                "<last_update_unix_timestamp>",
                (_recordLastUpdatedForIntegration[integrationId] - 1).ToString());

            RecordErrorInDB(log, connectionStr, "INFO",
                integrationName ?? "<no integration specified>",
                "Generic JSON import triggered", "Generic JSON import triggered", 32302);

            try
            {
                using HttpClient client = new();
                using HttpResponseMessage response = await client.GetAsync(query);
                using HttpContent content = response.Content;

                string result = await content.ReadAsStringAsync();
                result = result.Replace(@"\.", ".").Replace(@"\'", "'").Replace("'", "''");

                string queryMd5  = CreateMD5(query);
                string resultMd5 = CreateMD5(result);

                bool updateSqlDb = true;

                if (_jsonResultHashValues.TryGetValue(queryMd5, out string? cachedHash))
                {
                    if (cachedHash == resultMd5)
                        updateSqlDb = false;
                    else
                        _jsonResultHashValues[queryMd5] = resultMd5;
                }
                else
                {
                    _jsonResultHashValues[queryMd5] = resultMd5;
                }

                if (updateSqlDb)
                {
                    // Integration 3 is the San Diego kennel group — requires map-link
                    // reverse-geocoding before the JSON is persisted to the DB.
                    if (int.Parse(integrationId) == 3)
                    {
                        var data = JToken.Parse("[" + result + "]");

                        for (int i = 0; i < data.Count(); i++)
                        {
                            char          webQueryExecuted = 'N';
                            ParsedResult? tryLatLon        = null;

                            try
                            {
                                string kennelName = data[i].SelectToken("kennelname")!.ToString();
                                string maplink    = data[i].SelectToken("maplink")!.ToString();
                                string eventName  = data[i].SelectToken("run_name")?.ToString()
                                                    ?? kennelName + " Run";
                                string location   = data[i].SelectToken("location")!.ToString();
                                string maplinkMD5 = CreateMD5(maplink);

                                recordsRead++;

                                if (string.IsNullOrWhiteSpace(eventName))
                                    eventName = kennelName + " Run";

                                bool doSaveInDb = true;

                                if (_urlToLatLong.TryGetValue(maplinkMD5, out ParsedResult? cached))
                                {
                                    tryLatLon = cached;
                                }
                                else
                                {
                                    tryLatLon = new ParsedResult
                                    {
                                        originalUrl    = maplink,
                                        originalUrlMD5 = maplinkMD5,
                                        location       = RemoveHTML(DecodeUrlString(location ?? "")),
                                    };
                                }

                                // Check the DB cache before making any external HTTP calls
                                if (tryLatLon.isNotComplete)
                                {
                                    var dbContent = GetImmutableGeoUrlFromDb(log, connectionStr, maplinkMD5);
                                    if (dbContent?.Count > 0)
                                    {
                                        if (dbContent.ContainsKey("PinLat"))       tryLatLon.pinLat       = dbContent["PinLat"];
                                        if (dbContent.ContainsKey("PinLon"))       tryLatLon.pinLon       = dbContent["PinLon"];
                                        if (dbContent.ContainsKey("MapCenterLat")) tryLatLon.mapCenterLat = dbContent["MapCenterLat"];
                                        if (dbContent.ContainsKey("MapCenterLon")) tryLatLon.mapCenterLon = dbContent["MapCenterLon"];
                                        if (dbContent.ContainsKey("Address"))      tryLatLon.address      = dbContent["Address"];
                                        doSaveInDb = false;
                                    }
                                }

                                // Expand shortened Google/other URLs to get a resolvable map link
                                if (tryLatLon.isNotComplete
                                    && !(maplink.Contains(GoogleDir)
                                      || maplink.Contains(GooglePlace)
                                      || maplink.Contains(GoogleMapsQ)
                                      || maplink.Contains(GoogleMapsQs)
                                      || maplink.Contains(BingMaps)))
                                {
                                    string shortLink = maplink;

                                    if (maplink.StartsWith(GoogleUrlShortener) || maplink.StartsWith(GooglePageUrlShortener))
                                    {
                                        shortLink = maplink.EndsWith("?share")
                                            ? maplink + "&Key=AIzaSyAPljuP6vKKhTWqMJ9Z8zggxZBt69jyBLc"
                                            : maplink + "?Key=AIzaSyAPljuP6vKKhTWqMJ9Z8zggxZBt69jyBLc";
                                    }

                                    if (Uri.TryCreate(shortLink, UriKind.Absolute, out Uri? uriResult)
                                        && (uriResult.Scheme == Uri.UriSchemeHttp || uriResult.Scheme == Uri.UriSchemeHttps))
                                    {
                                        try
                                        {
                                            using HttpClient clientx = new();
                                            using HttpResponseMessage resp = await clientx.GetAsync(uriResult);
                                            string mapResult = await resp.Content.ReadAsStringAsync();

                                            webQueryExecuted = 'Y';

                                            var document = new HtmlDocument();
                                            document.LoadHtml(mapResult);

                                            HtmlNode? node = document.DocumentNode
                                                .SelectSingleNode("(//div[contains(@class,'signin')]//a)[1]");
                                            if (node == null)
                                                node = document.DocumentNode
                                                    .SelectSingleNode("(//input[contains(@name,'continue')])[1]");

                                            if (node != null)
                                            {
                                                string s = DecodeUrlString(node.OuterHtml ?? "");
                                                if      (s.Contains(GooglePlace))  maplink = CleanString(GooglePlace,   s) ?? maplink;
                                                else if (s.Contains(GoogleDir))    maplink = CleanString(GoogleDir,    s) ?? maplink;
                                                else if (s.Contains(GoogleMapsQ))  maplink = CleanString(GoogleMapsQ,  s) ?? maplink;
                                                else if (s.Contains(GoogleMapsQs)) maplink = CleanString(GoogleMapsQs, s) ?? maplink;
                                            }
                                        }
                                        catch (Exception ex)
                                        {
                                            errorCount++;
                                            log.LogWarning("URL expansion failed for {Url}: {Message}", shortLink, ex.Message);
                                        }
                                    }
                                }

                                Regex regexMapCenter = new(@"(?<=\/@)(.*?)(?=\/)");

                                if (tryLatLon.isNotComplete && maplink.StartsWith(GooglePlace))
                                {
                                    string address = new Regex(@"(?<=place\/)(.*?)(?=\/@)").Match(maplink).Value;
                                    if (address == "")
                                        address = new Regex(@"(?<=place\/)(.*?)(?=\/)").Match(maplink).Value;

                                    address = address.Replace("+", " ");

                                    string   mapLatLon  = regexMapCenter.Match(maplink).Value;
                                    string   pinLatStr  = new Regex(@"(?<=!3d)(.*?)(?=[^-0-9.])").Match(maplink).Value;
                                    string   pinLonStr  = new Regex(@"(?<=!4d)(.*?)(?=[^-0-9.])").Match(maplink + "x").Value;
                                    string[] mapLlArray = mapLatLon.Split(",");
                                    double   d;

                                    if (!string.IsNullOrWhiteSpace(address))                             tryLatLon.address      = address;
                                    if (double.TryParse(pinLatStr,       out d))                         tryLatLon.pinLat       = d;
                                    if (double.TryParse(pinLonStr,       out d))                         tryLatLon.pinLon       = d;
                                    if (mapLlArray.Length >= 2 && double.TryParse(mapLlArray[0], out d)) tryLatLon.mapCenterLat = d;
                                    if (mapLlArray.Length >= 2 && double.TryParse(mapLlArray[1], out d)) tryLatLon.mapCenterLon = d;
                                }

                                if (tryLatLon.isNotComplete && maplink.StartsWith(GoogleDir))
                                {
                                    string   ad       = new Regex(@"(?<=dir\/)(.*?)(?=\/@)").Match(maplink).Value;
                                    string[] add      = ad.Split("/");
                                    string?  address  = null;
                                    string?  pinLatStr = null;
                                    string?  pinLonStr = null;

                                    if (add.Length >= 2)
                                    {
                                        string[] latlonAr = add[0].Split(",");
                                        address = add[1];
                                        if (latlonAr.Length >= 2)
                                        {
                                            pinLatStr = latlonAr[0];
                                            pinLonStr = latlonAr[1];
                                        }
                                    }

                                    string   mapLatLon  = regexMapCenter.Match(maplink).Value;
                                    string[] mapLlArray = mapLatLon.Split(",");
                                    double   d;

                                    if (!string.IsNullOrWhiteSpace(address))                             tryLatLon.address      = address.Replace("+", " ");
                                    if (mapLlArray.Length >= 2 && double.TryParse(mapLlArray[0], out d)) tryLatLon.mapCenterLat = d;
                                    if (mapLlArray.Length >= 2 && double.TryParse(mapLlArray[1], out d)) tryLatLon.mapCenterLon = d;
                                    if (!string.IsNullOrWhiteSpace(pinLatStr) && double.TryParse(pinLatStr, out d)) tryLatLon.pinLat = d;
                                    if (!string.IsNullOrWhiteSpace(pinLonStr) && double.TryParse(pinLonStr, out d)) tryLatLon.pinLon = d;
                                }

                                if (tryLatLon.isNotComplete
                                    && (maplink.StartsWith(GoogleMapsQ) || maplink.StartsWith(GooglePageUrlShortener)))
                                {
                                    string address = RemoveHTML(DecodeUrlString(
                                        maplink.Replace(GoogleMapsQ, "").Replace(GooglePageUrlShortener, "")));
                                    if (address.EndsWith("?share")) address = address.Replace("?share", "");
                                    address = address.Replace("+", " ");
                                    if (address.IndexOf("&") >= 0)
                                        address = address[..address.IndexOf("&")];

                                    var geo = await AzureGeocode.Geocode(
                                        address,
                                        ((minLat + maxLat) / 2m).ToString(), ((minLon + maxLon) / 2m).ToString(),
                                        false, "US,CA,MX", maxLat, minLat, maxLon, minLon);

                                    if (geo != null)
                                    {
                                        tryLatLon.address  = geo.FreeformAddress ?? geo.ResolvedName ?? "";
                                        tryLatLon.pinLat   = tryLatLon.mapCenterLat = geo.Latitude;
                                        tryLatLon.pinLon   = tryLatLon.mapCenterLon = geo.Longitude;
                                        tryLatLon.geoJson  = Newtonsoft.Json.JsonConvert.SerializeObject(geo);
                                    }
                                }

                                if (tryLatLon.isNotComplete && maplink.StartsWith(GoogleMapsQs))
                                {
                                    string address = RemoveHTML(DecodeUrlString(maplink.Replace(GoogleMapsQs, "")));
                                    address = address.Replace("+", " ");
                                    if (address.IndexOf("&") >= 0)
                                        address = address[..address.IndexOf("&")];

                                    var geo = await AzureGeocode.Geocode(
                                        address,
                                        ((minLat + maxLat) / 2m).ToString(), ((minLon + maxLon) / 2m).ToString(),
                                        false, "US,CA,MX", maxLat, minLat, maxLon, minLon);

                                    if (geo != null)
                                    {
                                        tryLatLon.address  = geo.FreeformAddress ?? geo.ResolvedName ?? "";
                                        tryLatLon.pinLat   = tryLatLon.mapCenterLat = geo.Latitude;
                                        tryLatLon.pinLon   = tryLatLon.mapCenterLon = geo.Longitude;
                                        tryLatLon.geoJson  = Newtonsoft.Json.JsonConvert.SerializeObject(geo);
                                    }
                                }

                                if (tryLatLon.isNotComplete && !string.IsNullOrWhiteSpace(location) && location.Length > 8)
                                {
                                    var geo = await AzureGeocode.Geocode(
                                        location,
                                        ((minLat + maxLat) / 2m).ToString(), ((minLon + maxLon) / 2m).ToString(),
                                        false, "US,CA,MX", maxLat, minLat, maxLon, minLon);

                                    if (geo != null)
                                    {
                                        tryLatLon.address  = geo.FreeformAddress ?? geo.ResolvedName ?? "";
                                        tryLatLon.pinLat   = tryLatLon.mapCenterLat = geo.Latitude;
                                        tryLatLon.pinLon   = tryLatLon.mapCenterLon = geo.Longitude;
                                        tryLatLon.geoJson  = Newtonsoft.Json.JsonConvert.SerializeObject(geo);
                                    }
                                }

                                if (tryLatLon.isNotComplete)
                                    log.LogInformation("{Exec} - INCOMPLETE - {Md5} - {Lat}/{Lon} - {Address}",
                                        webQueryExecuted, tryLatLon.originalUrlMD5,
                                        tryLatLon.pinLat, tryLatLon.pinLon, tryLatLon.address);
                                else
                                    log.LogInformation("{Exec} - {Md5} - {Lat}/{Lon} - {Address}",
                                        webQueryExecuted, tryLatLon.originalUrlMD5,
                                        tryLatLon.pinLat, tryLatLon.pinLon, tryLatLon.address);

                                if (doSaveInDb)
                                {
                                    // Run a final geocode if we have an address but no GeoJSON yet,
                                    // so the DB record includes the full Azure Maps response.
                                    if (string.IsNullOrWhiteSpace(tryLatLon.geoJson)
                                        && (!string.IsNullOrWhiteSpace(tryLatLon.address)
                                            || !string.IsNullOrWhiteSpace(tryLatLon.location)))
                                    {
                                        decimal centerLat = (minLat + maxLat) / 2m;
                                        decimal centerLon = (minLon + maxLon) / 2m;

                                        AzureGeocode.GeocodeResult? geo1 = null, geo2 = null;

                                        if (!string.IsNullOrWhiteSpace(tryLatLon.address))
                                            geo1 = await AzureGeocode.Geocode(
                                                tryLatLon.address,
                                                centerLat.ToString(), centerLon.ToString(),
                                                false, "US,CA,MX", maxLat, minLat, maxLon, minLon);

                                        if (!string.IsNullOrWhiteSpace(tryLatLon.location))
                                            geo2 = await AzureGeocode.Geocode(
                                                tryLatLon.location,
                                                centerLat.ToString(), centerLon.ToString(),
                                                false, "US,CA,MX", maxLat, minLat, maxLon, minLon);

                                        if (geo1 != null || geo2 != null)
                                        {
                                            var best = (geo1?.internalScore ?? -1) > (geo2?.internalScore ?? -1)
                                                ? geo1 : geo2;
                                            tryLatLon.geoJson = Newtonsoft.Json.JsonConvert.SerializeObject(best);
                                        }
                                    }

                                    SaveImmutableGeoUrl(log, connectionStr, tryLatLon);
                                }
                            }
                            catch (Exception ex)
                            {
                                errorCount++;
                                log.LogWarning("Record {Index} failed: {Type} — {Message}",
                                    i, ex.GetType().Name, ex.Message);
                            }
                        }
                    }

                    log.LogInformation("Processing inbound integration started at {Date} {Time}",
                        DateTime.Now.ToShortDateString(), DateTime.Now.ToShortTimeString());

                    // WARNING: The two SP calls below use string interpolation — SQL-injection risk
                    // inherited from HC5. Do not expand this pattern; refactor to parameterised calls
                    // before this integration handles untrusted kennel data.

                    using (SqlConnection conn3 = new(connectionStr))
                    {
                        result = result.Replace("\t", "");
                        log.LogInformation("JSON length = {Length}", result.Length);

                        string writeCmd = $"EXEC HC.nonApi_writeInboundIntegrationJsonToDb " +
                                          $"@integrationId='{integrationId}', @sourceJson=N'{result}', @localJson=N''";

                        using SqlCommand cmd3 = new(writeCmd, conn3);
                        await conn3.OpenAsync();

                        try
                        {
                            using SqlDataReader rows3 = await cmd3.ExecuteReaderAsync();
                            while (await rows3.ReadAsync())
                                log.LogInformation("{Result}", rows3.GetValue(0));
                        }
                        catch (Exception ex)
                        {
                            errorCount++;
                            log.LogWarning("nonApi_writeInboundIntegrationJsonToDb failed: {Type} — {Message}",
                                ex.GetType().Name, ex.Message);
                        }
                    }

                    using (SqlConnection conn4 = new(connectionStr))
                    {
                        string processCmd = $"EXEC [HC].[nonApi_processInboundJson] @integrationId='{integrationId}'";

                        using SqlCommand cmd4 = new(processCmd, conn4);
                        await conn4.OpenAsync();

                        try
                        {
                            using SqlDataReader rows4 = await cmd4.ExecuteReaderAsync();
                            while (await rows4.ReadAsync())
                            {
                                string sqlResult = rows4.GetValue(0).ToString() ?? "";

                                try { recordsWritten += int.Parse(sqlResult.Replace("Records updated = ", "")); }
                                catch { /* non-integer result rows are informational only */ }

                                log.LogInformation("{Result}", sqlResult);

                                // The SP returns the source timestamp of the most recently updated
                                // record so we know exactly where to resume from next time.
                                string lastUpdatedStr = rows4.GetValue(1).ToString() ?? "";
                                if (DateTime.TryParse(lastUpdatedStr, out DateTime lastUpdate))
                                    _recordLastUpdatedForIntegration[integrationId] =
                                        ((DateTimeOffset)lastUpdate).ToUnixTimeSeconds();
                            }
                        }
                        catch (Exception ex)
                        {
                            errorCount++;
                            log.LogWarning("nonApi_processInboundJson failed: {Type} — {Message}",
                                ex.GetType().Name, ex.Message);
                        }
                    }

                    log.LogInformation("Finished runs import at {Date} {Time}",
                        DateTime.Now.ToShortDateString(), DateTime.Now.ToShortTimeString());
                }

                log.LogInformation("Processing inbound integration ended at {Date} {Time}",
                    DateTime.Now.ToShortDateString(), DateTime.Now.ToShortTimeString());
            }
            catch (Exception ex)
            {
                errorCount++;
                log.LogError("GenericJsonQuery.ImportEvents failed at {Date} {Time}: {Message}",
                    DateTime.Now.ToShortDateString(), DateTime.Now.ToShortTimeString(), ex.Message);

                RecordErrorInDB(log, connectionStr, ex.Message,
                    "GenericJsonQuery.ImportEvents query failed",
                    "GenericJsonQuery.ImportEvents", query, 43920);
            }

            return new object[] { recordsRead, recordsWritten, "", "", errorCount, "", 0, "", 0, "" };
        }

        private static string? CleanString(string pattern, string s)
        {
            int idx = s.IndexOf(pattern);
            if (idx < 0) return null;
            s = s[idx..];
            s = DecodeUrlString(s);
            return WebUtility.HtmlDecode(s);
        }

        private static Dictionary<string, dynamic>? GetImmutableGeoUrlFromDb(
            ILogger log, string connectionStr, string md5)
        {
            var ll = new Dictionary<string, dynamic>();

            // md5 is hex-only (A-F 0-9) so inline interpolation is safe here
            string sql = $@"
                SELECT PinLat, PinLon, MapCenterLat, MapCenterLon, Address
                FROM [EXT].[ImmutableGeoLink]
                WHERE [ImmutableGeoLinkId] = '{md5}'";

            using SqlConnection conn = new(connectionStr);
            using SqlCommand    cmd  = new(sql, conn);
            conn.Open();

            try
            {
                using SqlDataReader rows = cmd.ExecuteReader();
                while (rows.Read())
                {
                    string pinLatStr       = rows.GetValue(0).ToString() ?? "";
                    string pinLonStr       = rows.GetValue(1).ToString() ?? "";
                    string mapCenterLatStr = rows.GetValue(2).ToString() ?? "";
                    string mapCenterLonStr = rows.GetValue(3).ToString() ?? "";
                    string address         = rows.GetValue(4).ToString() ?? "";
                    double d;

                    if (double.TryParse(pinLatStr,       out d)) ll["PinLat"]       = d;
                    if (double.TryParse(pinLonStr,       out d)) ll["PinLon"]       = d;
                    if (double.TryParse(mapCenterLatStr, out d)) ll["MapCenterLat"] = d;
                    if (double.TryParse(mapCenterLonStr, out d)) ll["MapCenterLon"] = d;
                    if (!string.IsNullOrWhiteSpace(address))     ll["Address"]      = address;
                }
            }
            catch (Exception ex)
            {
                log.LogWarning("GetImmutableGeoUrlFromDb failed: {Type} — {Message}",
                    ex.GetType().Name, ex.Message);
            }

            return ll;
        }

        private static void SaveImmutableGeoUrl(ILogger log, string connectionStr, ParsedResult pr)
        {
            // Replace("'","''") is used as escaping here — acceptable because these values
            // come from geocoding API responses, not direct user input.
            string sql = $@"
                EXEC EXT.InsertImmutableGeoLink
                    @ImmutableGeoLinkId = N'{pr.originalUrlMD5}',
                    @OriginalUrl        = N'{pr.originalUrl}',
                    @PinLat             = {pr.pinLat},
                    @PinLon             = {pr.pinLon},
                    @MapCenterLat       = {pr.mapCenterLat},
                    @MapCenterLon       = {pr.mapCenterLon},
                    @HtmlFragment       = '<none>',
                    @PlaceName          = N'{(pr.location ?? "").Replace("'", "''")}',
                    @Address            = N'{(pr.address  ?? "").Replace("'", "''")}',
                    @GeoJson            = N'{(pr.geoJson  ?? "").Replace("'", "''")}'";

            using SqlConnection conn = new(connectionStr);
            using SqlCommand    cmd  = new(sql, conn);
            conn.Open();

            try
            {
                using SqlDataReader rows = cmd.ExecuteReader();
                while (rows.Read())
                    log.LogInformation("{Result}", rows.GetValue(0));
            }
            catch (Exception ex)
            {
                log.LogWarning("SaveImmutableGeoUrl failed: {Type} — {Message}",
                    ex.GetType().Name, ex.Message);
            }
        }

        private static void RecordErrorInDB(
            ILogger log,
            string  connectionStr,
            string  errorType,
            string  message,
            string  method,
            string  inputText,
            int     errorCode = 0,
            string  string2   = "",
            string  string3   = "",
            string  string4   = "")
        {
            string sql = $"EXEC HC.nonApi_logError " +
                         $"@errorType=N'{errorType}', @message=N'{message}', " +
                         $"@location=N'{method}', @inputText=N'{inputText}', " +
                         $"@errorCode={errorCode}, @string_2=N'{string2}', " +
                         $"@string_3=N'{string3}', @string_4=N'{string4}'";

            using SqlConnection conn = new(connectionStr);
            using SqlCommand    cmd  = new(sql, conn);
            conn.Open();

            try
            {
                using SqlDataReader rows = cmd.ExecuteReader();
                while (rows.Read())
                    log.LogInformation("{Result}", rows.GetValue(0));
            }
            catch (Exception ex)
            {
                log.LogWarning("RecordErrorInDB failed: {Type} — {Message}",
                    ex.GetType().Name, ex.Message);
            }
        }

        public static string CreateMD5(string input)
        {
            byte[] inputBytes = Encoding.ASCII.GetBytes(input);
            byte[] hashBytes  = MD5.HashData(inputBytes);
            return Convert.ToHexString(hashBytes); // uppercase hex — matches original X2 format
        }
    }
}
