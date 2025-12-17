# Authentication Setup Guide

This document details the Azure AD authentication configuration for the Todo API and provides troubleshooting guidance.

## Overview

The Todo API uses Azure AD (Microsoft Entra ID) for authentication via JWT Bearer tokens. The authentication is implemented using `Microsoft.Identity.Web` and can be toggled on/off using the `RunWithAuth` configuration setting.

## Configuration

### Required Azure AD Settings

The following configuration values are required when authentication is enabled:

| Setting | Description | Example |
|---------|-------------|---------|
| `AzureAd:ClientId` | Application (client) ID of the API app registration | `{your-api-client-id}` |
| `AzureAd:TenantId` | Azure AD tenant ID | `{your-tenant-id}` |
| `AzureAd:Instance` | Azure AD instance URL | `https://login.microsoftonline.com/` |
| `AzureAd:Audience` | Expected audience in tokens (typically `api://{ClientId}`) | `api://{your-api-client-id}` |

### Configuration Sources (Priority Order)

ASP.NET Core loads configuration in the following order (later sources override earlier ones):

1. **appsettings.json** - Base configuration (committed to source control)
2. **appsettings.Development.json** - Environment-specific overrides (committed to source control)
3. **User Secrets** - Local development secrets (not committed)
4. **Environment Variables** - System/user environment variables
5. **Command Line Arguments** - Runtime arguments

### Option 1: Environment Variables (Recommended for Local Development)

Set user environment variables using PowerShell:

```powershell
[Environment]::SetEnvironmentVariable("AzureAd__ClientId", "{your-api-client-id}", "User")
[Environment]::SetEnvironmentVariable("AzureAd__TenantId", "{your-tenant-id}", "User")
[Environment]::SetEnvironmentVariable("AzureAd__Instance", "https://login.microsoftonline.com/", "User")
[Environment]::SetEnvironmentVariable("AzureAd__Audience", "api://{your-api-client-id}", "User")
```

**Important:** 
- Note the double underscore (`__`) in environment variable names, which maps to the colon (`:`) in JSON configuration
- After setting environment variables, restart Visual Studio or your IDE
- Verify variables are set: `[Environment]::GetEnvironmentVariable("AzureAd__ClientId", "User")`

### Option 2: appsettings.json

Add the `AzureAd` section to your appsettings files:

```json
{
  "RunWithAuth": true,
  "AzureAd": {
    "ClientId": "{your-api-client-id}",
    "TenantId": "{your-tenant-id}",
    "Instance": "https://login.microsoftonline.com/",
    "Audience": "api://{your-api-client-id}"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

**Warning:** Do not commit sensitive values to source control. Use environment variables or User Secrets for local development.

### Option 3: User Secrets (Local Development)

```bash
dotnet user-secrets init
dotnet user-secrets set "AzureAd:ClientId" "{your-api-client-id}"
dotnet user-secrets set "AzureAd:TenantId" "{your-tenant-id}"
dotnet user-secrets set "AzureAd:Instance" "https://login.microsoftonline.com/"
dotnet user-secrets set "AzureAd:Audience" "api://{your-api-client-id}"
```

## Azure AD App Registration Setup

### API App Registration

The API app registration must be configured with the following settings (managed via Terraform in `app_registration_api.tf`):

```terraform
resource "azuread_application" "api_app_registration" {
  display_name     = "To Do API"
  sign_in_audience = "AzureADMyOrg"
  identifier_uris  = ["api://{client_id}"]

  api {
    oauth2_permission_scope {
      admin_consent_description  = "Allow the app to access the To Do API on behalf of the signed-in user."
      admin_consent_display_name = "Access To Do API"
      id                         = "{your-scope-id}"
      type                       = "User"
      value                      = "access_as_user"
    }
    
    # CRITICAL: This ensures tokens have api:// prefix in audience claim
    requested_access_token_version = 2
  }
}
```

**Key Points:**
- `identifier_uris` should be `["api://{client_id}"]` - this is what appears in the token's `aud` claim
- `requested_access_token_version = 2` ensures v2.0 tokens with the correct audience format
- The scope `access_as_user` must be granted to client applications

### Client App Registrations

Frontend apps (Angular/React) must request access to the API:

```terraform
required_resource_access {
  resource_app_id = azuread_application.api_app_registration.client_id

  resource_access {
    id   = "{your-scope-id}"  # access_as_user scope ID
    type = "Scope"
  }
}
```

## The Audience Validation Issue

### Problem

The most common authentication error is:

```
Error: IDX10214: Audience validation failed. Audiences: 'api://{your-api-client-id}'. 
Did not match: validationParameters.ValidAudience: '{your-api-client-id}' or validationParameters.ValidAudiences: null.
```

### Root Cause

When an Azure AD app registration has `requested_access_token_version = 2`, tokens contain the audience as `api://{client_id}`. However, by default, `Microsoft.Identity.Web` only validates against the `ClientId` itself (without the `api://` prefix).

### Solution

The `Extensions.ConfigureAuth()` method explicitly configures valid audiences to accept both formats:

```csharp
options.TokenValidationParameters.ValidAudiences = new[] 
{ 
    audience ?? clientId,  // api://{your-api-client-id}
    clientId               // {your-api-client-id}
};
```

This allows the API to accept tokens regardless of whether the audience claim includes the `api://` prefix or not.

## Verification Steps

### 1. Verify Configuration is Loaded

When the API starts, it should successfully bind the AzureAd configuration. Add temporary logging if needed:

```csharp
var clientId = builder.Configuration["AzureAd:ClientId"];
var audience = builder.Configuration["AzureAd:Audience"];
Console.WriteLine($"ClientId: {clientId}");
Console.WriteLine($"Audience: {audience}");
```

### 2. Verify Azure AD App Registration

Use Azure CLI or PowerShell to verify the app registration:

```powershell
# From Terraform directory
terraform show -json | ConvertFrom-Json | 
  Select-Object -ExpandProperty values | 
  Select-Object -ExpandProperty root_module | 
  Select-Object -ExpandProperty resources | 
  Where-Object { $_.address -eq 'azuread_application.api_app_registration' } | 
  Select-Object -ExpandProperty values | 
  Select-Object client_id, identifier_uris
```

Verify:
- `client_id` matches your `AzureAd:ClientId` configuration
- `identifier_uris` contains `api://{client_id}`

### 3. Test Authentication

Use the Todo.API.http file or a tool like Postman:

```http
GET https://localhost:5001/todos
Authorization: Bearer {token}
```

A valid token should:
- Have `aud` claim matching `api://{client_id}` or `{client_id}`
- Have `tid` claim matching your tenant ID
- Include the `scp` claim with `access_as_user` scope

### 4. Decode and Inspect Tokens

Use [jwt.ms](https://jwt.ms) to decode tokens and verify claims:

Required claims:
- `aud`: `api://{your-api-client-id}` (or just the GUID)
- `tid`: `{your-tenant-id}`
- `scp`: `access_as_user`
- `iss`: `https://sts.windows.net/{your-tenant-id}/` or `https://login.microsoftonline.com/{your-tenant-id}/v2.0`

## Troubleshooting

### Issue: "IDX10214: Audience validation failed"

**Solution:** Verify that:
1. The `AzureAd:Audience` configuration matches the `identifier_uris` in the app registration
2. The `ValidAudiences` is set in `Extensions.ConfigureAuth()` to accept both formats
3. The token's `aud` claim matches one of the valid audiences

### Issue: "Configuration values are null"

**Solution:**
1. Verify environment variables are set and spelled correctly (use `__` not `:`)
2. Restart Visual Studio after setting environment variables
3. Check environment variable scope (User vs System)
4. Verify appsettings.json is being loaded (check build output)

### Issue: "IDX10501: Signature validation failed"

**Solution:**
1. Verify `AzureAd:TenantId` is correct
2. Verify `AzureAd:Instance` is set to `https://login.microsoftonline.com/`
3. Check that the token hasn't expired
4. Ensure the signing keys can be retrieved from Azure AD

### Issue: Changes not taking effect

**Solution:**
1. Completely stop and restart Visual Studio (not just stop debugging)
2. Clean and rebuild the solution
3. Clear browser cache or use incognito mode
4. Verify environment variables in a new PowerShell window

## Frontend Configuration

Frontend applications must request tokens with the correct scope:

```typescript
// MSAL configuration
const msalConfig = {
  auth: {
    clientId: "{frontend_app_client_id}",
    authority: "https://login.microsoftonline.com/{tenant_id}",
    redirectUri: "https://localhost:4200/"
  }
};

// Request token with API scope
const tokenRequest = {
  scopes: ["api://{your-api-client-id}/access_as_user"]
};
```

The scope format must be: `api://{api_client_id}/{scope_name}`

## Additional Resources

- [Microsoft Identity Web documentation](https://learn.microsoft.com/en-us/azure/active-directory/develop/microsoft-identity-web)
- [Azure AD app registration](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [JWT token reference](https://learn.microsoft.com/en-us/azure/active-directory/develop/access-tokens)
- [Token validation](https://learn.microsoft.com/en-us/azure/active-directory/develop/access-tokens#validate-tokens)

## Summary Checklist

- [ ] Azure AD app registrations created and configured via Terraform
- [ ] `requested_access_token_version = 2` set in API app registration
- [ ] `identifier_uris` set to `["api://{client_id}"]`
- [ ] Environment variables set with double underscore notation
- [ ] Visual Studio/IDE restarted after setting environment variables
- [ ] `RunWithAuth` set to `true` in appsettings
- [ ] `ValidAudiences` configured in `Extensions.ConfigureAuth()`
- [ ] Frontend apps configured to request correct API scope
- [ ] Admin consent granted for API permissions (if required)
