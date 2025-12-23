import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './app.tsx'
import { PublicClientApplication, EventType } from '@azure/msal-browser';
import { msalConfig } from './auth-config.ts';

/**
 * MSAL should be instantiated outside of the component tree to prevent it from being re-instantiated on re-renders.
 * For more, visit: https://github.com/AzureAD/microsoft-authentication-library-for-js/blob/dev/lib/msal-react/docs/getting-started.md
 */
let msalInstance: PublicClientApplication;

// Initialize MSAL instance only once to avoid StrictMode double-initialization warnings
if (!(window as any).msalInstance) {
  msalInstance = new PublicClientApplication(msalConfig);
  (window as any).msalInstance = msalInstance;
} else {
  msalInstance = (window as any).msalInstance;
}

// Initialize MSAL and render the app
msalInstance.initialize().then(() => {
  // Default to using the first account if no account is active on page load
  if (!msalInstance.getActiveAccount() && msalInstance.getAllAccounts().length > 0) {
    // Account selection logic is app dependent. Adjust as needed for different use cases.
    msalInstance.setActiveAccount(msalInstance.getAllAccounts()[0]);
  }

  // Listen for sign-in event and set active account

  msalInstance.addEventCallback((event) => {
    if (event.eventType === EventType.LOGIN_SUCCESS && event.payload) {
      const account = (event.payload as any).account;
      msalInstance.setActiveAccount(account);
    }
    if (event.eventType === EventType.LOGIN_FAILURE && event.error) {
      // Show a user-friendly error (replace with Snackbar if you want)
      alert("Sign-in failed");
      // Log full error for debugging
      console.error("MSAL LOGIN_FAILURE", event.error);
    }
  });

  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <App msalInstance={msalInstance} />
    </StrictMode>,
  );
});
