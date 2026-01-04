import { LogLevel } from '@azure/msal-browser';

function _parseArray(val: any, def: any[] = []) {
  if (val === undefined || val === null) return def;
  if (Array.isArray(val)) return val;
  try {
    return JSON.parse(String(val));
  } catch {
    return String(val).split(',').map((s) => s.trim()).filter(Boolean);
  }
}

// Could be improved, but this will do for now since env.js is loaded after this file.
function getEnv() {
  return (window as any).__ENV__ || {};
}

export const AUTH_CONFIG = {
  get CLIENT_ID() {
    return getEnv().FRONTEND_APP_REGISTRATION_CLIENT_ID;
  },
  get TENANT_ID() {
    return getEnv().TENANT_ID;
  },
  get REDIRECT_URI() {
    return getEnv().FRONTEND_REDIRECT_URI + '/todo/react';
  },
  get POST_LOGOUT_REDIRECT_URI() {
    return getEnv().FRONTEND_POST_LOGOUT_REDIRECT_URI + '/todo/react';
  },

  // API
  get API_BASE_URL() {
    return getEnv().API_BASE_URL;
  },
  get API_SCOPE_URI() {
    return _parseArray(getEnv().API_SCOPE_URI);
  }
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
  scopes: [...AUTH_CONFIG.API_SCOPE_URI],
};

/**
 * Scopes for calling protected APIs
 */
export const protectedResources = {
  apiTodoList: {
    endpoint: AUTH_CONFIG.API_BASE_URL,
    scopes: AUTH_CONFIG.API_SCOPE_URI,
  },
};
