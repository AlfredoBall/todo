
import { environment } from '../environments/environment';
/**
 * Azure Entra ID Authentication Configuration
 * 
 * Configuration values are loaded from the environment files:
 * - environment.development.ts for local development
 * - environment.ts for production builds
 * 
 * Values include:
 * - CLIENT_ID: Application (client) ID from Azure app registration
 * - TENANT_ID: Directory (tenant) ID from Azure app registration
 * - REDIRECT_URI: Must match the redirect URI configured in Azure
 * - API_SCOPE_URI: The custom scopes for your .NET API (format: api://<CLIENT_ID>/<scope>)
 * - API_BASE_URL: The base URL for your protected API
 * - POST_LOGOUT_REDIRECT_URI: Where to redirect after logout
 */

export const AUTH_CONFIG = {
  // Azure AD Configuration (read from environment with fallbacks)
  CLIENT_ID: environment.NG_APP_AzureAd__ClientID,
  TENANT_ID: environment.NG_APP_AzureAd__TenantId,
  REDIRECT_URI: environment.NG_APP_RedirectUri,

  // API Configuration
  API_BASE_URL: environment.NG_APP_API_BASE_URL,
  API_SCOPE_URI: environment.NG_APP_apiScopes?.split(',').map((s: string) => s.trim()) || [],

  // Optional: Post logout redirect URI
  POST_LOGOUT_REDIRECT_URI: environment.NG_APP_PostLogoutRedirectUri
};

console.log('AUTH_CONFIG:', AUTH_CONFIG);