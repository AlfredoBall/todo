using System.Diagnostics;
using Aspire.Hosting.ApplicationModel;
using Projects;

var builder = DistributedApplication.CreateBuilder(args);

// Because this is a demo app, a real database with migrations will not be part of this orchestration.
// In order to leverage the Azure Free Tier, an in memory database will be used instead of a real SQL Server instance.
// This also greatly improves the developer experience as no database uptime is required to run Aspire.

var cache = builder.AddRedis("cache").WithRedisCommander();

var redisInsight = cache.WithRedisInsight(x =>
{
    x.OnResourceReady((r, evt, ct) =>
    {
        Task.Delay(TimeSpan.FromSeconds(20))
        .ContinueWith(t => System.Diagnostics.Process.Start(new ProcessStartInfo
        {
            FileName = "cmd.exe",
            // Assuming Chrome is installed
            Arguments = $"/c start chrome {r.PrimaryEndpoint.Url}", // Adjust port
            UseShellExecute = true
        }));
        
        return Task.CompletedTask;
    });
});

var api = builder.AddProject<Todo_API>("API")
                        .WithReference(cache)
                        .WaitFor(cache);

builder.AddNpmApp("Todo-Angular", "../../Web/Angular/todo")
        .WithReference(api)
        .WaitFor(api);

builder.AddNpmApp("Todo-React", "../../Web/React/todo", "dev")
        .WithReference(api)
        .WaitFor(api);

await builder.Build().RunAsync();