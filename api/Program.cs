using System;
using Azure.Data.Tables;
using Microsoft.Azure.Functions.Worker;            // ConfigureFunctionsApplicationInsights
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;

var builder = FunctionsApplication.CreateBuilder(args);

// This sets up all existing Function triggers, routing, JSON settings, etc.
builder.ConfigureFunctionsWebApplication();

// Application Insights for the ISOLATED WORKER (2026-09-18).
//
// The packages alone are not enough and neither is the connection string
// alone. Without these two calls the worker process sends nothing, which is
// why roughly 1 request in 1,000 has been failing with an EMPTY 500 and no
// record anywhere of the exception behind it.
//
// ConfigureFunctionsApplicationInsights() is the one people miss: it attaches
// the worker's ILogger to the telemetry pipeline so an unhandled exception in
// a Function body is actually reported.
builder.Services
    .AddApplicationInsightsTelemetryWorkerService()
    .ConfigureFunctionsApplicationInsights();

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
