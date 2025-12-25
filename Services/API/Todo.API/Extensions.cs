using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Identity.Web;
using Azure.Identity;
using Azure.Core;
using System.IdentityModel.Tokens.Jwt;

namespace Todo.API;

public static class Extensions
{
    public static async Task<WebApplicationBuilder> ConfigureAuth(this WebApplicationBuilder builder)
    {
        Console.WriteLine($"AzureAd:TenantId: {builder.Configuration["AzureAd:TenantId"]}");
        Console.WriteLine($"AzureAd:Audience: {builder.Configuration["AzureAd:Audience"]}");
        Console.WriteLine($"AzureAd:ClientId: {builder.Configuration["AzureAd:ClientId"]}");
        Console.WriteLine($"AzureAd:Instance: {builder.Configuration["AzureAd:Instance"]}");

        // 1. Initialize the credential
        var credential = new DefaultAzureCredential();

        // 2. Request a token for a standard scope (e.g., Azure Management)
        var tokenRequestContext = new TokenRequestContext(new[] { "management.azure.com" });
        var accessToken = await credential.GetTokenAsync(tokenRequestContext);

        // 3. Parse the JWT token to find the 'tid' (Tenant ID) claim
        var handler = new JwtSecurityTokenHandler();
        var jsonToken = handler.ReadJwtToken(accessToken.Token);
        var tenantId = jsonToken.Claims.FirstOrDefault(c => c.Type == "tid")?.Value;

        builder.Configuration["AzureAd:TenantId"] = tenantId;

        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddMicrosoftIdentityWebApi(
                jwtBearerOptions =>
                {
                    builder.Configuration.Bind("AzureAd", jwtBearerOptions);

                    // Accept both api://clientId and clientId as valid audiences
                    var audience = builder.Configuration["AzureAd:Audience"];
                    var clientId = builder.Configuration["AzureAd:ClientId"];
                    jwtBearerOptions.TokenValidationParameters.ValidAudiences = new[]
                    {
                        audience ?? clientId,
                        clientId
                    };
                },
                microsoftIdentityOptions => builder.Configuration.Bind("AzureAd", microsoftIdentityOptions));

        builder.Services.AddAuthorization(options =>
        {
            options.FallbackPolicy = new AuthorizationPolicyBuilder()
                .RequireAuthenticatedUser()
                .Build();
        });

        return builder;
    }
}
