using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Identity.Web;

namespace Todo.API;

public static class Extensions
{
    public static WebApplicationBuilder ConfigureAuth(this WebApplicationBuilder builder, bool runWithAuth)
    {
        Console.WriteLine($"AzureAd:TenantId: {builder.Configuration["AzureAd:TenantId"]}");
        Console.WriteLine($"AzureAd:Audience: {builder.Configuration["AzureAd:Audience"]}");
        Console.WriteLine($"AzureAd:ClientId: {builder.Configuration["AzureAd:ClientId"]}");
        Console.WriteLine($"AzureAd:Instance: {builder.Configuration["AzureAd:Instance"]}");

        if (runWithAuth)
        {
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
        }

        return builder;
    }
}
