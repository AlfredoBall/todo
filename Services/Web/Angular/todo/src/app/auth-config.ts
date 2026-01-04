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
    return getEnv().FRONTEND_REDIRECT_URI;
  },
  get POST_LOGOUT_REDIRECT_URI() {
    return getEnv().FRONTEND_POST_LOGOUT_REDIRECT_URI;
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