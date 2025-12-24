# Azure Entra ID Authentication Setup (React + Vite)

This React application is configured to use Azure Entra ID (formerly Azure AD) for authentication using MSAL (MSAL React / msal-browser).

## Quick summary
- Dev server: https://localhost:<REACT_DEV_PORT>
- Config file: `src/auth-config.ts` (reads Vite env variables)
- Env file: `Services/Web/React/todo/.env` (Vite `VITE_` prefixed variables)

## 1. Azure App Registrations (two apps)
You need two app registrations:

1. The **.NET API** (protected resource)
2. The **React SPA** (frontend)

### 1a. Register the .NET API
1. Azure Portal → Microsoft Entra ID → App registrations → New registration
2. Name: e.g. `Todo API`
3. Supported account types: choose as needed
4. Redirect URI: leave empty for APIs
5. Note the **Application (client) ID** and **Directory (tenant) ID**

Expose an API scope for your API (Microsoft Entra ID → App registrations → select your API → Expose an API):
- Application ID URI: accept default `api://<api-client-id>` or set custom URI
- Add a scope (e.g. scope = `scope`) and copy the full scope URI: `api://<api-client-id>/scope`

### 1b. Register the React SPA
1. Azure Portal → App registrations → New registration
2. Name: e.g. `React Todo App`
3. Supported account types: choose as needed
4. Redirect URI: Platform = Single-page application (SPA) → `https://localhost:<REACT_DEV_PORT>`
5. In Authentication settings add the front-channel logout and set post-logout redirect URI if desired
6. Note the **Application (client) ID** and **Directory (tenant) ID**

## 2. API Permissions (React app)
1. In your React app registration → API permissions → Add a permission
2. (Optional) Microsoft Graph → Delegated permissions → `User.Read` (if you want profile info)
3. APIs my organization uses → find your `Todo API` registration → select the `scope` you created
4. (Optional) Grant admin consent for the tenant

## 3. Configure React app (.env)
Update `Services/Web/React/todo/.env` (Vite picks up `VITE_` variables). Example values:

```
VITE_CLIENT_ID=<YOUR_REACT_CLIENT_ID>
VITE_TENANT_ID=<YOUR_TENANT_ID>
VITE_REDIRECT_URI=https://localhost:<REACT_DEV_PORT>
VITE_POST_LOGOUT_REDIRECT_URI=https://localhost:<REACT_DEV_PORT>
VITE_API_BASE_URL=/api
VITE_API_SCOPE_URI=["api://<YOUR_API_CLIENT_ID>/scope"]
```

## 4. React config file
The app reads configuration from `src/auth-config.ts`. Replace the placeholder values or set the `.env` values above.

Key variables used in code:
- `AUTH_CONFIG.CLIENT_ID` → `VITE_CLIENT_ID`
- `AUTH_CONFIG.TENANT_ID` → `VITE_TENANT_ID`
- `AUTH_CONFIG.REDIRECT_URI` → `VITE_REDIRECT_URI`
- `AUTH_CONFIG.API_BASE_URL` → `VITE_API_BASE_URL`
- `AUTH_CONFIG.API_SCOPE_URI` → `VITE_API_SCOPE_URI`

## 5. How authentication works
1. User clicks Sign In (MSAL React triggers a redirect or popup)
2. Azure Entra ID authenticates the user
3. The SPA receives ID and access tokens at the configured redirect URI
4. MSAL stores tokens (configured in `src/auth-config.ts`) and the app uses them to call your protected API

## 6. Backend (.NET API) configuration
Same as for Angular — your API must validate tokens issued by Azure Entra ID.
Install `Microsoft.Identity.Web` and configure your API (in `Program.cs` and `appsettings.json`) to use the API's `ClientId` / `TenantId` and `Audience` (`api://<api-client-id>`).

Typical `appsettings.json` snippet:

```json
"AzureAd": {
  "Instance": "https://login.microsoftonline.com/",
  "TenantId": "YOUR_TENANT_ID",
  "ClientId": "YOUR_API_CLIENT_ID",
  "Audience": "api://YOUR_API_CLIENT_ID"
}
```

And in `Program.cs`:

```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

app.UseAuthentication();
app.UseAuthorization();
```

## 7. Development tips
- Dev server runs at `https://localhost:<REACT_DEV_PORT>` (Vite). Ensure Azure redirect URI exactly matches this origin plus path if used.

## 8. Troubleshooting
- AADSTS50011: redirect URI mismatch — ensure the redirect URI in Azure matches `VITE_REDIRECT_URI` exactly.
- Consent errors — add required API permissions and grant admin consent if needed.
- Tokens not sent — verify `VITE_API_BASE_URL` matches the API endpoint and `VITE_API_SCOPE_URI` contains the API scope.

## 9. Useful links
- MSAL React: https://github.com/AzureAD/microsoft-authentication-library-for-js/tree/dev/lib/msal-react
- Azure Entra ID docs: https://learn.microsoft.com/en-us/entra/identity-platform/

## Next steps
1. Create the two app registrations and expose your API scope.
2. Populate `Services/Web/React/todo/.env` with real values.

Enjoy! 🎯

