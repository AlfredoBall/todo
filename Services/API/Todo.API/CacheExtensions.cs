using System.Text.Json;
using Microsoft.Extensions.Caching.Distributed;

namespace Todo.API;

public static class CacheExtensions
{
    public static async Task<T?> GetAsync<T>(this IDistributedCache cache, string key, CancellationToken cancellationToken = default)
    {
        var data = await cache.GetAsync(key, cancellationToken);
        if (data == null)
        {
            return default;
        }

        return JsonSerializer.Deserialize<T>(data);
    }

    public static async Task SetAsync<T>(this IDistributedCache cache, string key, T value, DistributedCacheEntryOptions options, CancellationToken cancellationToken = default)
    {
        var data = JsonSerializer.SerializeToUtf8Bytes(value);
        await cache.SetAsync(key, data, options, cancellationToken);
    }
}
