# 🎯 Azure Entra ID Authentication - Quick Setup

## ✅ What's Been Done

All the code is ready! The app is configured with:

✔️ MSAL packages installed  
✔️ Authentication configuration file created  
✔️ MSAL providers configured in app.config.ts  
✔️ Auth guard protecting routes  
✔️ Login component in navbar  
✔️ HTTP interceptor for automatic token injection  
✔️ Development mode bypass option (currently ENABLED)  

## ⚙️ Configuration Needed (3 Steps)

### Step 1: Azure App Registration
1. Go to [Azure Portal](https://portal.azure.com) → Microsoft Entra ID → App registrations
2. Create new registration:
   - Redirect URI: `angular-redirect-uri` (type: SPA)
3. Copy these values:
   - Application (client) ID
   - Directory (tenant) ID

### Step 2: API Scope Configuration
In your app registration:
- Go to **Expose an API** → Add a scope
- Scope name: `scope-name`
- Copy the full scope URI (format: `api://<CLIENT_ID>/scope-name`)

### Step 3: Update auth-config.ts
```typescript
// File: src/app/auth-config.ts
export const AUTH_CONFIG = {
  BYPASS_AUTH_IN_DEV: false,  // ← Change to false to enable auth
  CLIENT_ID: 'paste-your-client-id-here',
  TENANT_ID: 'paste-your-tenant-id-here',
  REDIRECT_URI: 'paste-the-angular-redirect-uri-here',
  API_BASE_URL: 'paste-the-api-base-url-here',
  API_SCOPES: ['api://paste-your-client-id-here/scope-name'],
  POST_LOGOUT_REDIRECT_URI: 'paste-the-angular-redirect-uri-here'
};
```

## 🚀 Testing

### With Auth Bypassed (Current State)
```bash
ng serve
```
- App works normally
- No Azure connection needed
- Warning in navbar: "⚠️ Auth Disabled (Dev Mode)"

### With Auth Enabled
1. Complete Steps 1-3 above
2. Run: `ng serve`
3. Click "Sign In" in navbar
4. Authenticate with Azure
5. Access protected pages

## 🔧 Backend API Setup

Your .NET API needs to validate the tokens. Quick config:

```csharp
// Program.cs
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

app.UseAuthentication();
app.UseAuthorization();
```

```json
// appsettings.json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "YOUR_TENANT_ID",
    "ClientId": "YOUR_API_CLIENT_ID"
  }
}
```

## 📝 Summary

**Current State**: ✅ Code complete, auth bypassed for development  
**To Enable Auth**: Update 3 values in `auth-config.ts` and set bypass flag to false  
**Protected Routes**: Home page, clipboard pages  
**Public Routes**: About page  

See **AUTHENTICATION.md** for detailed documentation!

Happy gaming! 🎮
