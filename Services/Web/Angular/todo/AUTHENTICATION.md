# Azure Entra ID Authentication Setup

This Angular 21 application is configured to use Azure Entra ID (formerly Azure AD) for authentication using MSAL (Microsoft Authentication Library).

## 🔧 Configuration Required

### 1. Azure App Registrations (2 Required)

You need **two separate app registrations**:
1. One for your **Angular frontend** (client application)
2. One for your **.NET API** (protected resource)

#### 1a. Register the .NET API App

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Microsoft Entra ID** > **App registrations** > **New registration**
3. Configure:
   - **Name**: Your API name (e.g., "Todo API")
   - **Supported account types**: Choose based on your needs
   - **Redirect URI**: Leave empty (APIs don't need redirect URIs)
4. After registration, note down:
   - **Application (client) ID** (you'll need this for your .NET API configuration)
   - **Directory (tenant) ID**

#### 1b. Expose an API Scope (Required for API to appear in permissions)

1. In your **Todo API** app registration, go to **Expose an API**
2. Click **Add a scope**
3. For **Application ID URI**, accept the default `api://<your-api-client-id>` or customize it
4. Configure the scope:
   - **Scope name**: `scope`
   - **Who can consent**: Admins and users
   - **Admin consent display name**: "Access the Todo API"
   - **Admin consent description**: "Allows the app to access the Todo API on behalf of the signed-in user"
   - **User consent display name**: "Access your todos"
   - **User consent description**: "Allows the app to access your todos"
5. Click **Add scope**
6. **Important**: Copy the full scope URI (e.g., `api://<api-client-id>/scope`) - you'll need this for the Angular configuration

#### 1c. Register the Angular Frontend App

1. Navigate to **Microsoft Entra ID** > **App registrations** > **New registration**
2. Configure:
   - **Name**: Your app name (e.g., "Angular Todo App")
   - **Supported account types**: Choose based on your needs (typically "Accounts in this organizational directory only")
   - **Redirect URI**: Select "Single-page application (SPA)" and enter `https://localhost:<YOUR_ANGULAR_DEV_PORT>`
3. After registration, note down:
   - **Application (client) ID** (you'll need this for Angular configuration)
   - **Directory (tenant) ID** (same as API, but verify)
4. Go to **Authentication** and add:
   - **Front-channel logout URL**: `https://localhost:<YOUR_ANGULAR_DEV_PORT>`

### 2. Configure API Permissions (Angular App)

Now configure permissions in your **Angular app registration** to call your .NET API:

1. Go to your **Angular Todo App** registration
2. Go to **API permissions** > **Add a permission**
3. For Microsoft Graph (optional, if you want user profile):
   - Select **Microsoft Graph** > **Delegated permissions**
   - Add `User.Read`
4. For your .NET API (required):
   - Click **APIs my organization uses** tab
   - Find your **Todo API** registration (it should now appear!)
   - Select it and check the `scope` scope
   - Click **Add permissions**
5. (Optional) Click **Grant admin consent** to pre-approve permissions

### 3. Update Angular Configuration File
Edit `src/app/auth-config.ts` and replace the placeholder values:

```typescript
export const AUTH_CONFIG = {
  // Replace these with your ANGULAR app registration values
  CLIENT_ID: '<YOUR_ANGULAR_CLIENT_ID>',
  TENANT_ID: '<YOUR_TENANT_ID>',
  REDIRECT_URI: 'https://localhost:<YOUR_ANGULAR_DEV_PORT>',
  
  // Your .NET API configuration
  API_BASE_URL: '/api',
  // Use the full scope URI from your API's "Expose an API" section
  API_SCOPE_URI: ['api://<YOUR_API_CLIENT_ID>/scope'],
  
  POST_LOGOUT_REDIRECT_URI: 'https://localhost:<YOUR_ANGULAR_DEV_PORT>'
};
```

**Important**: Replace:
- `<YOUR_ANGULAR_CLIENT_ID>` with your **Angular app's** Application (client) ID
- `<YOUR_TENANT_ID>` with your Directory (tenant) ID
- `<YOUR_API_CLIENT_ID>` with your **.NET API app's** Application (client) ID (in the scope URI)

## 🔐 How Authentication Works

### Authentication Flow
1. User clicks "Sign In" button in navbar
2. Browser redirects to Azure Entra ID login page
3. User authenticates with their credentials
4. Azure redirects back to app with authentication tokens
5. MSAL stores tokens in browser localStorage
6. Protected routes are now accessible

### Token Handling
- **MSAL Interceptor**: Automatically adds Bearer tokens to HTTP requests for protected API endpoints
- **Tokens stored**: In browser localStorage (configurable)
- **Token refresh**: Handled automatically by MSAL
- **Token validation**: Your .NET API validates the JWT token

## 📁 Files Created/Modified

### New Files
- `src/app/auth-config.ts` - Authentication configuration
- `src/app/guards/auth.guard.ts` - Route guard for protected pages
- `src/app/components/login/login.ts` - Login component
- `src/app/components/login/login.html` - Login template
- `src/app/components/login/login.css` - Login styles

### Modified Files
- `src/app/app.config.ts` - Added MSAL providers and interceptor
- `src/app/app.routes.ts` - Added auth guard to protected routes
- `src/app/app.ts` - Added MSAL initialization logic
- `src/app/components/navbar/navbar.ts` - Imported login component
- `src/app/components/navbar/navbar.html` - Added login component to navbar
- `src/index.html` - Added `<app-redirect>` for MSAL redirects
- `package.json` - Added MSAL dependencies

## 🔧 Backend API Configuration

Your .NET API needs to be configured to validate tokens from Azure Entra ID:

1. Install NuGet package: `Microsoft.Identity.Web`
2. Configure in `Program.cs`:

```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

builder.Services.AddAuthorization();

// Add this before app.Run()
app.UseAuthentication();
app.UseAuthorization();
```

3. Add to `appsettings.json`:

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "YOUR_TENANT_ID",
    "ClientId": "YOUR_API_CLIENT_ID",
    "Audience": "api://YOUR_API_CLIENT_ID"
  }
}
```

4. Protect your API endpoints with `[Authorize]` attribute

## 📝 Usage

### Sign In / Sign Out
The login component in the navbar automatically handles:
- Displaying "Sign In" button when not authenticated
- Showing user's display name when authenticated
- Providing "Sign Out" button
- Showing dev mode warning when auth is bypassed

### Accessing Protected Routes
- When auth is enabled, navigating to protected routes triggers login flow
- After successful authentication, user is redirected to requested page
- Tokens are automatically included in API requests

### Token in API Calls
MSAL Interceptor automatically adds the Bearer token to requests matching:
- `api-base-url*` (your API base URL)

No manual header manipulation needed!

## 🐛 Troubleshooting

### "AADSTS50011: The redirect URI does not match"
- Ensure redirect URI in Azure app registration matches exactly: `angular-redirect-uri`
- Must be configured as "Single-page application (SPA)" platform

### "AADSTS65001: The user or administrator has not consented"
- Add API permissions in Azure app registration
- Grant admin consent if required by your tenant

### "Correlation ID errors"
- Clear browser cache and localStorage
- Ensure `CLIENT_ID` and `TENANT_ID` are correct

### Token not added to API requests
- Check `API_BASE_URL` matches your actual API URL
- Verify `API_SCOPE_URI` are configured correctly
- Ensure interceptor is configured in `app.config.ts`

## 📚 Resources

- [MSAL Angular Documentation](https://github.com/AzureAD/microsoft-authentication-library-for-js/tree/dev/lib/msal-angular)
- [Azure Entra ID Documentation](https://learn.microsoft.com/en-us/entra/identity-platform/)
- [Tutorial: Angular SPA with Azure AD](https://learn.microsoft.com/en-us/entra/identity-platform/tutorial-single-page-apps-angular-prepare-app)

## 🎮 Next Steps

1. **Complete Azure app registration** (see instructions above)
2. **Update auth-config.ts** with your Azure values
3. **Configure your .NET API** to validate tokens
5. **Test the authentication flow** by clicking "Sign In"

Enjoy your game! The authentication is ready when you are! 🎯
