using System;
using System.IO.Compression;
using Azure.Data.Tables;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;

var builder = FunctionsApplication.CreateBuilder(args);

// This sets up all existing Function triggers, routing, JSON settings, etc.
// Compression is scoped to HC6 endpoints only via UseWhen — HC5 endpoints
// (AppApi, PortalApi, etc.) are untouched.
builder.ConfigureFunctionsWebApplication(app =>
{
    app.UseWhen(
        ctx => ctx.Request.Path.StartsWithSegments("/api/AppApiHC6") ||
               ctx.Request.Path.StartsWithSegments("/api/PortalApiHC6"),
        branch => branch.UseResponseCompression()
    );
});

// Compress all JSON responses — covers every function in this host.
// EnableForHttps: Azure Functions is always HTTPS; without this flag the
// middleware skips compression entirely.
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<BrotliCompressionProvider>();
    options.Providers.Add<GzipCompressionProvider>();
});
builder.Services.Configure<BrotliCompressionProviderOptions>(options =>
{
    options.Level = CompressionLevel.Fastest;
});
builder.Services.Configure<GzipCompressionProviderOptions>(options =>
{
    options.Level = CompressionLevel.Fastest;
});

// Register the IHttpClientFactory for BoxProxyFunctions
builder.Services.AddHttpClient();

// Register TableClient for Azure Table Storage
// Read the connection string from configuration or environment variables
var storageConn = builder.Configuration["AzureWebJobsStorage"]
                  ?? Environment.GetEnvironmentVariable("AzureWebJobsStorage")
                  ?? throw new InvalidOperationException("AzureWebJobsStorage connection string is not configured.");
var tableName = builder.Configuration["DOS_TOKENS_TABLE_NAME"] ?? "BoxTokens";

builder.Services.AddSingleton(sp =>
{
    var client = new TableClient(storageConn, tableName);
    client.CreateIfNotExists();
    return client;
});

// Build and run the host
builder.Build().Run();
