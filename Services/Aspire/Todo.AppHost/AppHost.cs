using System.Diagnostics;
using System.Net.Mime;
using System.Text.Json;
using System.Text.Json.Nodes;
using Aspire.Hosting;
using Projects;

var builder = DistributedApplication.CreateBuilder(args);

// Setup Terraform for development environment
var terraformDir = Path.GetFullPath(Path.Combine(builder.AppHostDirectory, "../../../DevOps/Infrastructure/Terraform.local"));

// Get tenant ID from configuration
var tenantId = builder.Configuration["Azure:TenantId"]
    ?? throw new InvalidOperationException("Azure:TenantId configuration is required. Set it in User Secrets, appsettings.development.json, or environment variables.");

string externalFrontendPort = "8443";

TerraformOutputs? terraformOutputs = null;
SPAInputs? spaInputs = null;

// Initialize Terraform
var terraformInit = builder.AddExecutable("terraform-init", "terraform", terraformDir, "init");

var api = builder.AddProject<Todo_API>("API");

var terraformApply = builder.AddExecutable("terraform-setup", "terraform", terraformDir, "apply", "-auto-approve")
    .WaitForCompletion(terraformInit)
    .WithEnvironment(context =>
    {
        context.EnvironmentVariables["TF_VAR_redirect_uri"] = $"https://localhost:{externalFrontendPort}";

        terraformOutputs = GetTerraformOutputs(terraformDir);
        spaInputs = new SPAInputs
        {
            TENANT_ID = tenantId,
            FRONTEND_APP_REGISTRATION_CLIENT_ID = terraformOutputs.FRONTEND_APP_REGISTRATION_CLIENT_ID,
            FRONTEND_REDIRECT_URI = $"https://localhost:{externalFrontendPort}",
            FRONTEND_POST_LOGOUT_REDIRECT_URI = $"https://localhost:{externalFrontendPort}",
            API_SCOPE_URI = terraformOutputs.API_SCOPE_URI,
            API_BASE_URL = api.GetEndpoint("https")!.Url
        };

        return Task.CompletedTask;
    });

var spaDir = Path.GetFullPath(
    Path.Combine(builder.AppHostDirectory, "../../../DevOps/Build/Web/SPA")
);

builder.AddExecutable("generate-spa-env", "pwsh", spaDir)
    .WithArgs(context =>
    {
        context.Args.Add("-File");
        context.Args.Add("generate-spa-env.ps1");

        context.Args.Add("-OutputPath");
        context.Args.Add("../../../../Services/Web/shared/env.js");

        context.Args.Add("-InputJson");
        context.Args.Add(JsonSerializer.Serialize(spaInputs));
    })
    .WaitForCompletion(terraformApply);

api
   .WaitForCompletion(terraformApply, 0) // Wait for terraform to complete
   .WithEnvironment(async context =>
   {
       context.EnvironmentVariables["AzureAd__TenantId"] = tenantId;
       context.EnvironmentVariables["AzureAd__ClientId"] = terraformOutputs.API_APP_REGISTRATION_CLIENT_ID;
       context.EnvironmentVariables["AzureAd__Audience"] = terraformOutputs.API_AUDIENCE;
       context.EnvironmentVariables["AzureAD__Instance"] = "https://login.microsoftonline.com/";
       // Required for CORS since they are differen't ports than the API
       context.EnvironmentVariables["FRONTEND_URL"] = $"https://localhost:{externalFrontendPort}";
   });

var angular = builder.AddJavaScriptApp("Todo-Angular", "../../Web/Angular/todo", "build").WithPnpm().WithBuildScript("watch")
    .WaitForCompletion(terraformApply)
    .WaitFor(api);

var react = builder.AddJavaScriptApp("Todo-React", "../../Web/React/todo", "build").WithPnpm().WithBuildScript("watch")
    .WaitForCompletion(terraformApply)
    .WaitFor(api);

var frontend = builder.AddDockerfile("todo-frontend", "../../../", "DevOps/Build/Web/SPA/Dockerfile.local")
    .WithHttpsEndpoint(int.Parse(externalFrontendPort), 443)
    .WithBindMount("../../Web/Angular/todo/dist", "/usr/share/nginx/html/angular")
    .WithBindMount("../../Web/React/todo/dist", "/usr/share/nginx/html/react")
    .WithBindMount("../../Web/shared", "/usr/share/nginx/html/shared")
    .WithBindMount("../../../DevOps/Build/Web/SPA/nginx.template.local.conf", "/etc/nginx/nginx.template.local.conf")
    .WithEnvironment(context =>
    {
        context.EnvironmentVariables["API_BASE_URL"] = api.GetEndpoint("https")!.Url;
        return Task.CompletedTask;
    })
    .WaitForCompletion(terraformApply)
    .WaitFor(api).WaitFor(angular).WaitFor(react)
    .OnResourceReady((r, evt, ct) =>
    {
        Task.Delay(TimeSpan.FromSeconds(5))
        .ContinueWith(t => System.Diagnostics.Process.Start(new ProcessStartInfo
        {
            FileName = "cmd.exe",
            Arguments = $"/c start chrome https://localhost:{externalFrontendPort}/todo/react/",
            UseShellExecute = true
        }));

        return Task.CompletedTask;
    });

await builder.Build().RunAsync();

static TerraformOutputs GetTerraformOutputs(string terraformDir)
{
    var outputJson = RunCommand("terraform", "output -json", terraformDir).Result;
    var json = JsonNode.Parse(outputJson)!;

    return new TerraformOutputs
    {
        FRONTEND_APP_REGISTRATION_CLIENT_ID = json["frontend_app_registration_client_id"]!["value"]!.GetValue<string>(),
        API_APP_REGISTRATION_CLIENT_ID = json["api_app_registration_client_id"]!["value"]!.GetValue<string>(),
        API_SCOPE_URI = json["api_scope_uri"]!["value"]!.GetValue<string>(),
        API_AUDIENCE = json["api_audience"]!["value"]!.GetValue<string>()
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
    public string FRONTEND_APP_REGISTRATION_CLIENT_ID { get; init; }
    public string API_APP_REGISTRATION_CLIENT_ID { get; init; }
    public string API_SCOPE_URI { get; init; }
    public string API_AUDIENCE { get; init; }
}

record SPAInputs : TerraformOutputs
{
    public string TENANT_ID { get; init; }
    public string FRONTEND_REDIRECT_URI { get; init; }
    public string FRONTEND_POST_LOGOUT_REDIRECT_URI { get; init; }
    public string API_BASE_URL { get; init; }
}