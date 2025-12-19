using System.Reflection;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using Todo.API;
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
    builder.Services.AddStackExchangeRedisCache(options =>
    {
        options.Configuration = cacheConnection;
        options.InstanceName = "TodoApp_";
    });
}
else
{
    // Fallback to in-memory distributed cache when Redis is not configured
    builder.Services.AddDistributedMemoryCache();
}

builder.Services.AddDbContext<Context>(options =>
{
    // For the Azure Free Tier. This is just a demo app and Azure charges for a SQL Server uptime.
    options.UseInMemoryDatabase("TodoDB");
});

builder.Services.AddSingleton<ClipboardService>();
builder.Services.AddSingleton<ItemService>();

// Configure CORS to allow Static Web Apps
var reactUrl = builder.Configuration["REACT_URL"] ?? throw new InvalidOperationException("REACT_URL configuration is required");
var angularUrl = builder.Configuration["ANGULAR_URL"] ?? throw new InvalidOperationException("ANGULAR_URL configuration is required");

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(reactUrl, angularUrl)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

builder.ConfigureAuth(Boolean.TryParse(builder.Configuration["RunWithAuth"], out bool runWithAuth) ? runWithAuth : false);

var app = builder.Build();

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

if (runWithAuth)
{
    app.UseAuthentication();
    app.UseAuthorization();
}

// TODO: Implement scopes, var scopeRequiredByApi = app.Configuration["AzureAd:Scopes"] ?? "";

#region Item Endpoints

app.MapGet("api/items/{clipboardId}", async (HttpContext httpContext, IDistributedCache cache, ItemService itemService, Context context, int clipboardId) =>
{
    //httpContext.VerifyUserHasAnyAcceptedScope(scopeRequiredByApi);

    string cacheKey = "items" + clipboardId;
    var cachedItems = await cache.GetAsync<IList<Todo.Data.Access.Item>>(cacheKey);

    if (cachedItems != null)
    {
        // Data found in cache
        return Results.Ok(cachedItems);
    }

    var items = await itemService.GetItems(context, clipboardId);

    var options = new DistributedCacheEntryOptions()
        .SetSlidingExpiration(TimeSpan.FromSeconds(10)) // Remove if not accessed for 10 seconds
        .SetAbsoluteExpiration(TimeSpan.FromHours(1)); // Max 1 hour storage

    await cache.SetAsync(cacheKey, items, options);

    return Results.Ok(items);
})
.WithName("GetItems");

app.MapPost("api/item", async (HttpContext httpContext, IDistributedCache cache, ItemService itemService, Context context, int clipboardId, string name) =>
{
    var result = await itemService.AddItem(context, clipboardId, name.Trim());
    
    if (result != null)
    {
        // Invalidate cache for this clipboard
        await cache.RemoveAsync("items" + clipboardId);
    }

    return result == null ? Results.BadRequest() : Results.Ok(result);
})
.WithName("AddItem");

app.MapDelete("api/item/{id}", async (HttpContext httpContext, IDistributedCache cache, ItemService itemService, Context context, int id) =>
{
    // Get the item to find its clipboard before deleting
    var item = await context.Items.FindAsync(id);
    var result = await itemService.DeleteItem(context, id);

    if (result && item != null)
    {
        // Invalidate cache for this clipboard
        await cache.RemoveAsync("items" + item.ClipboardID);
    }
    
    return result ? Results.Ok() : Results.NotFound();
})
.WithName("DeleteItem");

app.MapPost("api/item/{id}/complete", async (HttpContext httpContext, IDistributedCache cache, ItemService itemService, Context context, int id) =>
{
    // Get the item to find its clipboardS
    var item = await context.Items.FindAsync(id);
    var result = await itemService.CompleteItem(context, id);
    
    if (result && item != null)
    {
        // Invalidate cache for this clipboard
        await cache.RemoveAsync("items" + item.ClipboardID);
    }
    
    return result ? Results.Ok() : Results.NotFound();
})
.WithName("CompleteItem");

app.MapPost("api/item/{id}/unfinish", async (HttpContext httpContext, IDistributedCache cache, ItemService itemService, Context context, int id) =>
{
    // Get the item to find its clipboard
    var item = await context.Items.FindAsync(id);
    var result = await itemService.UnfinishItem(context, id);
    
    if (result && item != null)
    {
        // Invalidate cache for this clipboard
        await cache.RemoveAsync("items" + item.ClipboardID);
    }
    
    return result ? Results.Ok() : Results.NotFound();
})
.WithName("UnfinishItem");

app.MapPatch("api/item/{id}", async (HttpContext httpContext, IDistributedCache cache, ItemService itemService, Context context, int id, string name) =>
{
    // Get the item to find its clipboard
    var item = await context.Items.FindAsync(id);
    var result = await itemService.EditItem(context, id, name);
    
    if (result && item != null)
    {
        // Invalidate cache for this clipboard
        await cache.RemoveAsync("items" + item.ClipboardID);
    }
    
    return result ? Results.Ok() : Results.BadRequest();
})
.WithName("EditItem");

#endregion

#region Clipboard Endpoints

app.MapGet("api/clipboards", async (HttpContext httpContext, IDistributedCache cache, ClipboardService clipboardService, Context context) =>
{
    // TODO: httpContext.VerifyUserHasAnyAcceptedScope(scopeRequiredByApi);

    string cacheKey = "clipboards";
    var cachedClipboards = await cache.GetAsync<IList<Todo.Data.Access.Clipboard>>(cacheKey);

    if (cachedClipboards != null)
    {
        // Data found in cache
        return Results.Ok(cachedClipboards);
    }

    var clipboards = await clipboardService.GetClipboards(context);

    var options = new DistributedCacheEntryOptions()
        .SetSlidingExpiration(TimeSpan.FromSeconds(10)) // Remove if not accessed for 10 seconds
        .SetAbsoluteExpiration(TimeSpan.FromHours(1)); // Max 1 hour storage

    await cache.SetAsync(cacheKey, clipboards, options);

    return Results.Ok(clipboards);
})
.WithName("GetClipboards");

app.MapPost("api/clipboard", async (HttpContext httpContext, ClipboardService clipboardService, Context context, string name) =>
{
    var result = await clipboardService.AddClipboard(context, name.Trim());

    return result == null ? Results.BadRequest() : Results.Ok(result);
})
.WithName("AddClipboard");

app.MapPatch("api/clipboard/{id}", async (HttpContext httpContext, ClipboardService clipboardService, Context context, int id, string name) =>
{
    var result = await clipboardService.EditClipboard(context, id, name);
    return result ? Results.Ok() : Results.BadRequest();
})
.WithName("EditClipboard");

app.MapDelete("api/clipboard/{id}", async (HttpContext httpContext, ClipboardService clipboardService, Context context, int id) =>
{
    var result = await clipboardService.DeleteClipboard(context, id);
    return result ? Results.Ok() : Results.NotFound();
})
.WithName("DeleteClipboard");

#endregion

app.Run();
