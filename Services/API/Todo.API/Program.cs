using System.Reflection;
using System.Security.Claims;
using Microsoft.ApplicationInsights;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Identity.Web;
using Todo.API;
using Todo.Data.Access;
using Todo.Data.Entity;
using Todo.Data.Service;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddAutoMapper(cfg => { }, Assembly.Load("Todo.Data.Service"));

var cacheConnection = builder.Configuration.GetConnectionString("cache");
if (!string.IsNullOrEmpty(cacheConnection))
{
    Console.WriteLine("Configuring Redis cache with provided connection string.");
    builder.Services.AddStackExchangeRedisCache(options =>
    {
        options.Configuration = cacheConnection;
        options.InstanceName = "TodoApp_";
    });
}
else
{
    // Fallback to in-memory distributed cache when Redis is not configured
    Console.WriteLine("No Redis connection string configured; using in-memory distributed cache.");
    builder.Services.AddDistributedMemoryCache();
}

builder.Services.AddDbContext<Context>(options =>
{
    // For the Azure Free Tier. This is just a demo app and Azure charges for a SQL Server uptime.
    options.UseInMemoryDatabase("TodoDB");
});

builder.Services.AddSingleton<ClipboardService>();
builder.Services.AddSingleton<ItemService>();

// Configure CORS
// TODO Fix this if it's decided that the local development will host nginx for a combined frontend
//var reactUrl = builder.Configuration["REACT_URL"] ?? throw new InvalidOperationException("REACT_URL configuration is required");
//var angularUrl = builder.Configuration["ANGULAR_URL"] ?? throw new InvalidOperationException("ANGULAR_URL configuration is required");
var frontendURL = builder.Configuration["FRONTEND_URL"] ?? throw new InvalidOperationException("FRONTEND_URL configuration is required");

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(frontendURL)
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials();
    });
});

// The Connection String is setup in terraform and injected as an environment variable
builder.Services.AddApplicationInsightsTelemetry();


// Middleware to log selected headers to Application Insights
builder.Services.AddSingleton<TelemetryClient>();

var app = builder.Build();

// Log selected headers (e.g., Authorization) to Application Insights as a trace
app.Use(async (context, next) =>
{
    var telemetryClient = context.RequestServices.GetService<TelemetryClient>();
    if (telemetryClient != null)
    {
        var headersToLog = new[] { "Authorization", "X-Forwarded-For", "X-ARR-LOG-ID" };
        foreach (var header in headersToLog)
        {
            if (context.Request.Headers.TryGetValue(header, out var value))
            {
                telemetryClient.TrackTrace($"Header: {header} = {value}",
                    new Dictionary<string, string> { { "Header", header }, { "Value", value } });
            }
        }
    }
    await next();
});

// Ensure database is created and seeded
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<Context>();
    context.Database.EnsureCreated();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Todo API V1");
        c.DocumentTitle = "Todo API - Swagger UI";
    });
}

app.UseCors();

app.UseHttpsRedirection();

app.UseForwardedHeaders();

app.UseAuthentication();
app.UseAuthorization();

// TODO: Implement scopes, var scopeRequiredByApi = app.Configuration["AzureAd:Scopes"] ?? "";

#region Item Endpoints

app.MapGet("api/items/{clipboardId}", async (HttpContext httpContext, ClaimsPrincipal user, IDistributedCache cache, ItemService itemService, Context context, int clipboardId) =>
{
    //httpContext.VerifyUserHasAnyAcceptedScope(scopeRequiredByApi);

    string cacheKey = "items" + clipboardId;
    var cachedItems = await cache.GetAsync<IList<Todo.Data.Access.Item>>(cacheKey);

    if (cachedItems != null)
    {
        // Data found in cache
        return Results.Ok(cachedItems);
    }

    // TODO: Check for ArgumentException or UnauthorizedAccessException
    var items = await itemService.GetItems(context, clipboardId, Guid.Parse(user.GetObjectId()!));

    var options = new DistributedCacheEntryOptions()
        .SetSlidingExpiration(TimeSpan.FromSeconds(10)) // Remove if not accessed for 10 seconds
        .SetAbsoluteExpiration(TimeSpan.FromHours(1)); // Max 1 hour storage

    await cache.SetAsync(cacheKey, items, options);

    return Results.Ok(items);
})
.WithName("GetItems");

// Handle ArgumentException for invalid clipboard ID or unauthorized access
app.MapPost("api/item", async (HttpContext httpContext, ClaimsPrincipal user, IDistributedCache cache, ItemService itemService, Context context, int clipboardId, string name) =>
{
    try
    {
        var items = await itemService.AddItem(context, name.Trim(), clipboardId, Guid.Parse(user.GetObjectId()!));

        if (items != null)
        {
            // Invalidate cache for this clipboard
            await cache.RemoveAsync("items" + clipboardId);
        }

        return Results.Ok(items);
    }
    catch (Exception ex)
    {
        // TODO: Maybe return different types of errors
        return Results.BadRequest();
    }
})
.WithName("AddItem");

app.MapDelete("api/item/{itemID}", async (HttpContext httpContext, ClaimsPrincipal user, IDistributedCache cache, ItemService itemService, Context context, int itemID) =>
{
    try
    {
        var item = await itemService.DeleteItem(context, itemID, Guid.Parse(user.GetObjectId()!));

        await cache.RemoveAsync("items" + item.ClipboardID);

        return Results.Ok(item);
    }
    catch (Exception ex)
    {
        // TODO: Maybe return different types of errors
        return Results.BadRequest();
    }
})
.WithName("DeleteItem");

app.MapPost("api/item/{itemID}/complete", async (HttpContext httpContext, ClaimsPrincipal user, IDistributedCache cache, ItemService itemService, Context context, int itemID) =>
{
    try
    {
        var item = await itemService.CompleteItem(context, itemID, Guid.Parse(user.GetObjectId()!));

        await cache.RemoveAsync("items" + item.ClipboardID);

        return Results.Ok(item);
    }
    catch (Exception ex)
    {
        // TODO: Maybe return different types of errors
        return Results.BadRequest();
    }
})
.WithName("CompleteItem");

app.MapPost("api/item/{id}/unfinish", async (HttpContext httpContext, ClaimsPrincipal user, IDistributedCache cache, ItemService itemService, Context context, int id) =>
{
    try
    {
        var item = await itemService.UnfinishItem(context, id, Guid.Parse(user.GetObjectId()!));

        await cache.RemoveAsync("items" + item.ClipboardID);

        return Results.Ok();
    }
    catch (Exception ex)
    {
        // TODO: Maybe return different types of errors
        return Results.BadRequest();
    }
})
.WithName("UnfinishItem");

app.MapPatch("api/item/{id}", async (HttpContext httpContext, ClaimsPrincipal user, IDistributedCache cache, ItemService itemService, Context context, int id, string name) =>
{
    try
    {
        var item = await itemService.EditItem(context, id, name, Guid.Parse(user.GetObjectId()!));

        await cache.RemoveAsync("items" + item.ClipboardID);

        return Results.Ok(item);
    }
    catch (Exception ex)
    {
        // TODO: Maybe return different types of errors
        return Results.BadRequest();
    }
})
.WithName("EditItem");

#endregion

#region Clipboard Endpoints

app.MapGet("api/clipboards", async (HttpContext httpContext, TelemetryClient telemetryClient, ClaimsPrincipal user, IDistributedCache cache, ClipboardService clipboardService, Context context) =>
{
    string cacheKey = "clipboards";
    var cachedClipboards = await cache.GetAsync<IList<Todo.Data.Access.Clipboard>>(cacheKey);

    if (cachedClipboards != null)
    {
        // Data found in cache
        return Results.Ok(cachedClipboards);
    }

    try
    {
        var clipboards = await clipboardService.GetClipboards(context, Guid.Parse(user.GetObjectId()!));

        var options = new DistributedCacheEntryOptions()
            .SetSlidingExpiration(TimeSpan.FromSeconds(10)) // Remove if not accessed for 10 seconds
            .SetAbsoluteExpiration(TimeSpan.FromHours(1)); // Max 1 hour storage

        await cache.SetAsync(cacheKey, clipboards, options);

        return Results.Ok(clipboards);
    }
    catch (Exception ex)
    {
        telemetryClient.TrackException(ex);
        
        return Results.BadRequest();
    }
    
})
.WithName("GetClipboards");

app.MapPost("api/clipboard", async (HttpContext httpContext, ClaimsPrincipal user, ClipboardService clipboardService, Context context, string name) =>
{
    try
    {
        var clipboard = await clipboardService.AddClipboard(context, name, Guid.Parse(user.GetObjectId()!));

        return Results.Ok(clipboard);
    }
    catch (Exception ex)
    {
        // TODO: Maybe return different types of errors
        return Results.BadRequest();
    }
})
.WithName("AddClipboard");

app.MapPatch("api/clipboard/{clipboardID}", async (HttpContext httpContext, ClaimsPrincipal user, ClipboardService clipboardService, Context context, int clipboardID, string name) =>
{
    try
    {
        var clipboard = await clipboardService.EditClipboard(context, clipboardID, name, Guid.Parse(user.GetObjectId()!));

        return Results.Ok(clipboard);
    }
    catch (Exception ex)
    {
        // TODO: Maybe return different types of errors
        return Results.BadRequest();
    }
})
.WithName("EditClipboard");

app.MapDelete("api/clipboard/{clipboardID}", async (HttpContext httpContext, ClaimsPrincipal user, ClipboardService clipboardService, Context context, int clipboardID) =>
{
    try
    {
        var clipboard = await clipboardService.DeleteClipboard(context, clipboardID, Guid.Parse(user.GetObjectId()!));

        return Results.Ok(clipboard);
    }
    catch (Exception ex)
    {
        // TODO: Maybe return different types of errors
        return Results.BadRequest();
    }
})
.WithName("DeleteClipboard");

#endregion

app.Run();
