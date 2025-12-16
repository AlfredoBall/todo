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
                .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

            builder.Services.AddAuthorization(options =>
            {
                // Configure the fallback policy to require an authenticated user
                options.FallbackPolicy = new AuthorizationPolicyBuilder()
                    .RequireAuthenticatedUser()
                    .Build();
            });
        }

        return builder;
    }
}
