import { LogLevel } from '@azure/msal-browser';

/**
 * Azure Entra ID Authentication Configuration
 * 
 * TODO: Replace these placeholder values with your actual Azure app registration values:
 * - CLIENT_ID: Application (client) ID from Azure app registration
 * - TENANT_ID: Directory (tenant) ID from Azure app registration
 * - REDIRECT_URI: Must match the redirect URI configured in Azure (e.g., https://localhost:<YOUR_PORT>)
 * - API_SCOPES: The custom scopes for your .NET API (format: api://<CLIENT_ID>/<scope>)
 */

const _env = (import.meta && (import.meta as any).env) || {};

function _parseBool(val: any, def = false) {
  if (val === undefined || val === null) return def;
  return String(val).toLowerCase() === 'true';
}

function _parseArray(val: any, def: any[] = []) {
  if (val === undefined || val === null) return def;
  if (Array.isArray(val)) return val;
  try {
    return JSON.parse(String(val));
  } catch {
    return String(val).split(',').map((s) => s.trim()).filter(Boolean);
  }
}

export const AUTH_CONFIG = {
  // Set to true to bypass authentication in development (reads Vite env)
  BYPASS_AUTH_IN_DEV: _parseBool(_env.VITE_BYPASS_AUTH_IN_DEV, false),

  // Azure AD Configuration (read from Vite env with fallbacks)
  CLIENT_ID: _env.VITE_CLIENT_ID,
  TENANT_ID: _env.VITE_TENANT_ID,
  REDIRECT_URI: _env.VITE_REDIRECT_URI,

  // API Configuration
  API_BASE_URL: _env.VITE_API_BASE_URL,
  API_SCOPES: _parseArray(_env.VITE_API_SCOPES),

  // Optional: Post logout redirect URI
  POST_LOGOUT_REDIRECT_URI: _env.VITE_POST_LOGOUT_REDIRECT_URI,
};

console.log('AUTH_CONFIG:', AUTH_CONFIG);

/**
 * Configuration object to be passed to MSAL instance on creation. 
 * For a full list of MSAL.js configuration parameters, visit:
 * https://github.com/AzureAD/microsoft-authentication-library-for-js/blob/dev/lib/msal-browser/docs/configuration.md 
 */
export const msalConfig = {
  auth: {
    clientId: AUTH_CONFIG.CLIENT_ID,
    authority: `https://login.microsoftonline.com/${AUTH_CONFIG.TENANT_ID}`,
    redirectUri: AUTH_CONFIG.REDIRECT_URI,
    postLogoutRedirectUri: AUTH_CONFIG.POST_LOGOUT_REDIRECT_URI,
    navigateToLoginRequestUrl: false,
  },
  cache: {
    cacheLocation: "sessionStorage", // "sessionStorage" is more secure, but "localStorage" gives you SSO between tabs.
    storeAuthStateInCookie: false, // Set this to "true" if you are having issues on IE11 or Edge
  },
  system: {
    loggerOptions: {
      loggerCallback: (level: LogLevel, message: string, containsPii: boolean) => {
        if (containsPii) {
          return;
        }
        switch (level) {
          case LogLevel.Error:
            console.error(message);
            return;
          case LogLevel.Info:
            // console.info(message);
            return;
          case LogLevel.Verbose:
            console.debug(message);
            return;
          case LogLevel.Warning:
            console.warn(message);
            return;
          default:
            return;
        }
      },
    },
  },
};

/**
 * Scopes you add here will be prompted for user consent during sign-in.
 * By default, MSAL.js will add OIDC scopes (openid, profile, email) to any login request.
 * For more information about OIDC scopes, visit: 
 * https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent#openid-connect-scopes
 */
export const loginRequest = {
  scopes: [...AUTH_CONFIG.API_SCOPES],
};

/**
 * Scopes for calling protected APIs
 */
export const protectedResources = {
  apiTodoList: {
    endpoint: AUTH_CONFIG.API_BASE_URL,
    scopes: AUTH_CONFIG.API_SCOPES,
  },
};
