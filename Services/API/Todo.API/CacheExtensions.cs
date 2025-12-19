using System.Text.Json;
using Microsoft.Extensions.Caching.Distributed;

namespace Todo.API;

public static class CacheExtensions
{
    public static async Task<T?> GetAsync<T>(this IDistributedCache cache, string key, CancellationToken cancellationToken = default)
    {
        try
        {
            var data = await cache.GetAsync(key, cancellationToken);
            if (data == null)
            {
                return default;
            }

            return JsonSerializer.Deserialize<T>(data);
        }
        catch (Exception ex)
        {
            // If cache is unavailable or misconfigured, swallow the exception and fall back to origin data
            Console.Error.WriteLine($"Cache GET failed for key '{key}': {ex.Message}");
            return default;
        }
    }

    public static async Task SetAsync<T>(this IDistributedCache cache, string key, T value, DistributedCacheEntryOptions options, CancellationToken cancellationToken = default)
    {
        try
        {
            var data = JsonSerializer.SerializeToUtf8Bytes(value);
            await cache.SetAsync(key, data, options, cancellationToken);
        }
        catch (Exception ex)
        {
            // If cache is unavailable, log and continue without failing the request
            Console.Error.WriteLine($"Cache SET failed for key '{key}': {ex.Message}");
        }
    }
}
