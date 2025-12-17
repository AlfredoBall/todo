using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Identity.Web;

namespace Todo.API;

public static class Extensions
{
    public static WebApplicationBuilder ConfigureAuth(this WebApplicationBuilder builder, bool runWithAuth)
    {
        if (runWithAuth)
        {
            builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddMicrosoftIdentityWebApi(options =>
                {
                    builder.Configuration.Bind("AzureAd", options);
                    
                    // Accept both api://clientId and clientId as valid audiences
                    var audience = builder.Configuration["AzureAd:Audience"];
                    var clientId = builder.Configuration["AzureAd:ClientId"];
                    options.TokenValidationParameters.ValidAudiences = new[] 
                    { 
                        audience ?? clientId,
                        clientId
                    };
                }, options => builder.Configuration.Bind("AzureAd", options));

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
