using System.Diagnostics;
using System.Net.Mime;
using System.Text.Json;
using System.Text.Json.Nodes;
using Aspire.Hosting;
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
    .WithEnvironment("TF_CLI_ARGS", "-no-color");

TerraformOutputs? cachedOutputs = null;

var api = builder.AddProject<Todo_API>("API").OnResourceEndpointsAllocated(async (r, evt, ct) =>
    {
        Console.WriteLine($"✓ API is running at: {r.GetEndpoint("https").Url}");
    })
//    .WithReference(cache)
//    .WaitFor(cache)
   .WaitForCompletion(terraformApply, 0) // Wait for terraform to complete
   .WithEnvironment(async context =>
   {
       Console.WriteLine("⏳ API starting, waiting for Terraform outputs...");

       cachedOutputs ??= await GetTerraformOutputs(terraformDir);

       Console.WriteLine("✓ Terraform outputs available, configuring API...");
       context.EnvironmentVariables["AzureAd__ClientId"] = cachedOutputs.ApiClientId;
       context.EnvironmentVariables["AzureAd__TenantId"] = tenantId;
       context.EnvironmentVariables["AzureAd__Audience"] = cachedOutputs.ApiAudience;
       context.EnvironmentVariables["AzureAD__Instance"] = "https://login.microsoftonline.com/";
       // Required for CORS since they are differen't ports than the API
       context.EnvironmentVariables["ANGULAR_URL"] = "https://localhost:4200/";
       context.EnvironmentVariables["REACT_URL"] = "https://localhost:5173/";
   });

// Generate environment.development.ts for Angular from Terraform outputs before building/serving Angular app
var generateAngularEnv = builder.AddExecutable(
    "generate-angular-env",
    "pwsh",
    "-File",
    Path.GetFullPath(Path.Combine(builder.AppHostDirectory, "../../../DevOps/Scripts/generate-angular-dev-env.ps1")),
    "-TerraformDir", terraformDir,
    "-EnvPath", Path.GetFullPath(Path.Combine(builder.AppHostDirectory, "../../../Services/Web/Angular/todo/src/environments/environment.development.ts"))
).WithWorkingDirectory(Path.GetFullPath(Path.Combine(builder.AppHostDirectory, "../../../DevOps/Scripts"))).WaitForCompletion(terraformApply);

// For the Angular and React Apps, .WaitforCompletion(terraformApply) is necessary,
// even though the API waits for completion of the terraformApply resource and the Web App's resource waits for the API.
// WaitFor only means it waits for the API resource to be configured, not that the terraformApply resource itself has completed.

var angular = builder.AddJavaScriptApp("Todo-Angular", "../../Web/Angular/todo", "build").WithPnpm().WithBuildScript("watch")
    .WithReference(api)
    .WaitForCompletion(terraformApply)
    .WaitFor(api)
    .WaitForCompletion(generateAngularEnv);

var react = builder.AddJavaScriptApp("Todo-React", "../../Web/React/todo", "build").WithPnpm().WithBuildScript("watch")
    .WithReference(api)
    .WaitForCompletion(terraformApply)
    .WaitFor(api)
    .WithEnvironment(async context =>
    {
        // context.EnvironmentVariables["OUTPUT_DIR"] = Path.GetFullPath(Path.Combine(builder.AppHostDirectory, "../../../DevOps/Container/react"));
        context.EnvironmentVariables["VITE_CLIENT_ID"] = cachedOutputs.FrontendClientId;
        context.EnvironmentVariables["VITE_TENANT_ID"] = tenantId;
        context.EnvironmentVariables["VITE_API_SCOPE_URI"] = $"[\"{cachedOutputs.ApiScopeUri}\"]";
        context.EnvironmentVariables["VITE_REDIRECT_URI"] = "https://localhost:5173";
        context.EnvironmentVariables["VITE_POST_LOGOUT_REDIRECT_URI"] = "https://localhost:5173";
        context.EnvironmentVariables["VITE_API_BASE_URL"] = "/api";
    });

var frontend = builder.AddDockerfile("todo-frontend", "../../../DevOps/Infrastructure", "Dockerfile.local")
    .WithHttpEndpoint(targetPort: 8080)
    .WithBindMount("../../Web/Angular/todo/dist", "/usr/share/nginx/html/angular")
    .WithBindMount("../../Web/React/todo/dist", "/usr/share/nginx/html/react")
    .WithBindMount("../../Web/shared/policies", "/usr/share/nginx/html/shared/policies")
    .WithBindMount("../../../DevOps/Infrastructure/nginx.template.conf", "/etc/nginx/nginx.template.conf")
    .WithEnvironment(async context =>
    {  
        context.EnvironmentVariables["API_BASE_URL"] = api.GetEndpoint("https").Url;
        context.EnvironmentVariables["ASPNETCORE_ENVIRONMENT"] = builder.Environment;
    })
    .WaitForCompletion(angular).WaitForCompletion(react).WaitFor(api).WithReference(api)
    .OnResourceReady((r, evt, ct) =>
    {
        Task.Delay(TimeSpan.FromSeconds(5))
        .ContinueWith(t => System.Diagnostics.Process.Start(new ProcessStartInfo
        {
            FileName = "cmd.exe",
            Arguments = $"/c start chrome {r.GetEndpoint("http").Url}/todo/react/",
            UseShellExecute = true
        }));

        return Task.CompletedTask;
    });

await builder.Build().RunAsync();

static async Task<TerraformOutputs> GetTerraformOutputs(string terraformDir)
{
    var outputJson = await RunCommand("terraform", "output -json", terraformDir);
    var json = JsonNode.Parse(outputJson)!;

    return new TerraformOutputs
    {
        ApiClientId = json["api_app_registration_client_id"]!["value"]!.GetValue<string>(),
        FrontendClientId = json["frontend_app_registration_client_id"]!["value"]!.GetValue<string>(),
        ApiScopeUri = json["api_scope_uri"]!["value"]!.GetValue<string>(),
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
    public required string FrontendClientId { get; init; }
    public required string ApiScopeUri { get; init; }
    public required string ApiAudience { get; init; }
}