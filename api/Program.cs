using System;
using Azure.Data.Tables;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;

var builder = FunctionsApplication.CreateBuilder(args);

// This sets up all existing Function triggers, routing, JSON settings, etc.
builder.ConfigureFunctionsWebApplication();

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
