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

**Note**: When running via .NET Aspire (recommended), all Azure AD configuration is automatically injected as environment variables. You don't need to manually update `auth-config.ts` - just run the Aspire AppHost!

## ⚙️ For Standalone Development (Without Aspire)

If you're running the Angular app independently without Aspire orchestration, follow these steps:

### Step 1: Azure App Registration
1. Go to [Azure Portal](https://portal.azure.com) → Microsoft Entra ID → App registrations
2. Create new registration:
   - Redirect URI: `https://localhost:<YOUR_ANGULAR_DEV_PORT>` (type: SPA)
3. Copy these values:
   - Application (client) ID
   - Directory (tenant) ID

### Step 2: API Scope Configuration
In your app registration:
- Go to **Expose an API** → Add a scope
- Scope name: `access_as_user` (or your preferred scope name)
- Copy the full scope URI (format: `api://<CLIENT_ID>/access_as_user`)

### Step 3: Update auth-config.ts (Not needed with Aspire!)
```typescript
// File: src/app/auth-config.ts
export const AUTH_CONFIG = {
  CLIENT_ID: '<YOUR_ANGULAR_CLIENT_ID>',
  TENANT_ID: '<YOUR_TENANT_ID>',
  REDIRECT_URI: 'https://localhost:<YOUR_ANGULAR_DEV_PORT>',
  API_BASE_URL: '/api',
  API_SCOPE_URI: ['api://<YOUR_API_CLIENT_ID>/access_as_user'],
  POST_LOGOUT_REDIRECT_URI: 'https://localhost:<YOUR_ANGULAR_DEV_PORT>'
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
