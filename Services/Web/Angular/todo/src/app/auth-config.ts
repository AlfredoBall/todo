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
 * - API_SCOPES: The custom scopes for your .NET API (format: api://<CLIENT_ID>/<scope>)
 */

const env = (import.meta && import.meta.env) || {};

export const AUTH_CONFIG = {
  // Set to true to bypass authentication in development (reads from environment)
  BYPASS_AUTH_IN_DEV: env['NG_APP_bypassAuthInDev'] === 'false',
  
  // Azure AD Configuration (read from environment with fallbacks)
  CLIENT_ID: env['NG_APP_AzureAd__ClientID'],
  TENANT_ID: env['NG_APP_AzureAd__TenantId'],
  REDIRECT_URI: env['NG_APP_RedirectUri'],
  
  // API Configuration
  API_BASE_URL: env['NG_APP_apiBaseUrl'],
  API_SCOPES: env['NG_APP_apiScopes']?.split(',').map((s: string) => s.trim()) || [],
  
  // Optional: Post logout redirect URI
  POST_LOGOUT_REDIRECT_URI: env['NG_APP_PostLogoutRedirectUri']
};

console.log('AUTH_CONFIG:', AUTH_CONFIG);
