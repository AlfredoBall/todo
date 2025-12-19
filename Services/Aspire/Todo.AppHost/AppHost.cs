using System.Diagnostics;
using System.Text.Json;
using System.Text.Json.Nodes;
using Projects;

var builder = DistributedApplication.CreateBuilder(args);

// Setup Terraform for development environment
var terraformDir = Path.GetFullPath(Path.Combine(builder.AppHostDirectory, "../../../DevOps/Infrastructure/Terraform-Dev"));

// Get tenant ID from configuration
var tenantId = builder.Configuration["Azure:TenantId"]
    ?? throw new InvalidOperationException("Azure:TenantId configuration is required. Set it in User Secrets, appsettings.development.json, or environment variables.");

// Initialize Terraform
var terraformInit = builder.AddExecutable("terraform-init", "terraform", terraformDir, "init")
    .WithEnvironment("TF_CLI_ARGS", "-no-color");

// Add Terraform as an executable resource with environment variables
var terraformApply = builder.AddExecutable("terraform-setup", "terraform", terraformDir, "apply", "-auto-approve")
    .WaitForCompletion(terraformInit)
    .WithEnvironment("TF_CLI_ARGS", "-no-color")
    .WithEnvironment("TF_VAR_tenant_id", tenantId)
    .WithEnvironment("TF_VAR_api_redirect_uri", "https://localhost:7258/")
    .WithEnvironment("TF_VAR_react_redirect_uri", "https://localhost:5173/")
    .WithEnvironment("TF_VAR_angular_redirect_uri", "https://localhost:4200/");
    // Note: GitHub OIDC variables are NOT needed for local development
    // GitHub Actions integration is configured in the production Terraform directory

var cache = builder.AddRedis("cache")
    .WithRedisCommander();

var redisInsight = cache.WithRedisInsight(x =>
{
    x.OnResourceReady((r, evt, ct) =>
    {
        Task.Delay(TimeSpan.FromSeconds(20))
        .ContinueWith(t => System.Diagnostics.Process.Start(new ProcessStartInfo
        {
            FileName = "cmd.exe",
            Arguments = $"/c start chrome {r.PrimaryEndpoint.Url}",
            UseShellExecute = true
        }));

        return Task.CompletedTask;
    });
});

TerraformOutputs? cachedOutputs = null;

var api = builder.AddProject<Todo_API>("API")
    .WithReference(cache)
    .WaitFor(cache)
    .WaitForCompletion(terraformApply, 0) // Wait for terraform to complete
    .WithEnvironment(async context =>
    {
        Console.WriteLine("⏳ API starting, waiting for Terraform outputs...");

        cachedOutputs ??= await GetTerraformOutputs(terraformDir);

        Console.WriteLine("✓ Terraform outputs available, configuring API...");
        context.EnvironmentVariables["AzureAd__ClientId"] = cachedOutputs.ApiClientId;
        context.EnvironmentVariables["AzureAd__TenantId"] = cachedOutputs.TenantId;
        context.EnvironmentVariables["AzureAd__Audience"] = cachedOutputs.ApiAudience;
    });

builder.AddNpmApp("Todo-Angular", "../../Web/Angular/todo")
   .WithReference(api)
   .WaitFor(api)
   .WithEnvironment(async context =>
   {
        cachedOutputs ??= await GetTerraformOutputs(terraformDir);
        
        context.EnvironmentVariables["NG_APP_AzureAd__ClientID"] = cachedOutputs.AngularClientId;
        context.EnvironmentVariables["NG_APP_AzureAd__TenantId"] = cachedOutputs.TenantId;
        context.EnvironmentVariables["NG_APP_apiScopes"] = cachedOutputs.ApiScope;
        context.EnvironmentVariables["NG_APP_AzureAd__Audience"] = cachedOutputs.ApiAudience;
        context.EnvironmentVariables["NG_APP_AzureAd__Instance"] = "https://login.microsoftonline.com/";
        context.EnvironmentVariables["NG_APP_RedirectUri"] = "https://localhost:4200";
        context.EnvironmentVariables["NG_APP_PostLogoutRedirectUri"] = "https://localhost:4200";
        context.EnvironmentVariables["NG_APP_apiBaseUrl"] = "https://localhost:4200/api/*";
        context.EnvironmentVariables["NG_APP_API_BASE_URL"] = "/api";
        context.EnvironmentVariables["NG_APP_AzureAd__Scopes"] = "access_as_user";
        context.EnvironmentVariables["NG_APP_bypassAuthInDev"] = "false";
        context.EnvironmentVariables["NG_APP_production"] = "false";
   });

builder.AddNpmApp("Todo-React", "../../Web/React/todo", "dev")
   .WithReference(api)
   .WaitFor(api)
   .WithEnvironment(async context =>
   {
        context.EnvironmentVariables["VITE_CLIENT_ID"] = cachedOutputs.ReactClientId;
        context.EnvironmentVariables["VITE_TENANT_ID"] = cachedOutputs.TenantId;
        context.EnvironmentVariables["VITE_API_SCOPES"] = $"[\"{cachedOutputs.ApiScope}\"]";
        context.EnvironmentVariables["VITE_REDIRECT_URI"] = "https://localhost:5173";
        context.EnvironmentVariables["VITE_POST_LOGOUT_REDIRECT_URI"] = "https://localhost:5173";
        context.EnvironmentVariables["VITE_API_BASE_URL"] = "/api";
        context.EnvironmentVariables["VITE_BYPASS_AUTH_IN_DEV"] = "false";
   });

await builder.Build().RunAsync();

static async Task<TerraformOutputs> GetTerraformOutputs(string terraformDir)
{
    var outputJson = await RunCommand("terraform", "output -json", terraformDir);
    var json = JsonNode.Parse(outputJson)!;

    return new TerraformOutputs
    {
        ApiClientId = json["api_client_id"]!["value"]!.GetValue<string>(),
        ReactClientId = json["react_client_id"]!["value"]!.GetValue<string>(),
        AngularClientId = json["angular_client_id"]!["value"]!.GetValue<string>(),
        TenantId = json["tenant_id"]!["value"]!.GetValue<string>(),
        ApiScope = json["api_scope"]!["value"]!.GetValue<string>(),
        ApiAudience = json["api_audience"]!["value"]!.GetValue<string>()
    };
}

static async Task<string> RunCommand(string fileName, string arguments, string? workingDirectory = null)
{
    var startInfo = new ProcessStartInfo
    {
        FileName = fileName,
        Arguments = arguments,
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        CreateNoWindow = true
    };

    if (workingDirectory is not null)
    {
        startInfo.WorkingDirectory = workingDirectory;
    }

    var process = Process.Start(startInfo)
        ?? throw new Exception($"Failed to start process: {fileName}");

    var output = await process.StandardOutput.ReadToEndAsync();
    var error = await process.StandardError.ReadToEndAsync();
    await process.WaitForExitAsync();

    if (process.ExitCode != 0)
    {
        throw new Exception($"{fileName} failed: {error}");
    }

    return output.Trim();
}

record TerraformOutputs
{
    public required string ApiClientId { get; init; }
    public required string ReactClientId { get; init; }
    public required string AngularClientId { get; init; }
    public required string TenantId { get; init; }
    public required string ApiScope { get; init; }
    public required string ApiAudience { get; init; }
}