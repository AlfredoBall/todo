# Azure Entra ID Authentication Setup for React Todo App

## Overview
This document outlines the Azure Entra ID authentication implementation in the React Todo application using MSAL (Microsoft Authentication Library).

**Note**: When running via .NET Aspire (recommended), all Azure AD configuration is automatically injected as environment variables. You don't need to manually configure anything - just run the Aspire AppHost and it handles everything!

## For Standalone Development (Without Aspire)

If you're running the React app independently without Aspire orchestration, follow these steps:

## Prerequisites
- Azure subscription with an Entra ID tenant
- App registration in Azure Entra ID admin center
- Node.js and npm installed

## Step 1: Install Required Packages

✅ **COMPLETED** - Run the following commands in the React project directory:

```bash
npm install @azure/msal-browser @azure/msal-react
```

## Step 2: Configuration Files

✅ **COMPLETED** - Created: `src/authConfig.ts`

This file contains the MSAL configuration with Azure app registration values:
- `CLIENT_ID`: Application (client) ID from Azure
- `TENANT_ID`: Directory (tenant) ID from Azure
- `REDIRECT_URI`: Must match the redirect URI in Azure (e.g., https://localhost:<YOUR_PORT>)
- `API_SCOPES`: Custom scopes for your .NET API
- `BYPASS_AUTHENTICATION`: Set to true to bypass auth during development

## Step 3: Update Main Entry Point

✅ **COMPLETED** - Updated `src/main.tsx` to:
1. Create MSAL instance outside component tree
2. Set up event callbacks for LOGIN_SUCCESS
3. Set active account on page load if available
4. Pass MSAL instance to App component

## Step 4: Update App Component

✅ **COMPLETED** - Updated `src/app.tsx` to:
1. Accept msalInstance as prop
2. Wrap application with MsalProvider
3. Enable authentication context for all components

## Step 5: Create Login Component

✅ **COMPLETED** - Created `src/components/login/login.tsx` to:
1. Display user information when logged in
2. Provide sign-in/sign-out buttons using redirect flow
3. Use `useMsal` hook to access MSAL instance
4. Show user's display name or username

✅ **COMPLETED** - Created `src/components/login/login.css` with:
1. Material Design button styles
2. Proper spacing and layout
3. Blue sign-in and red sign-out buttons

## Step 6: Update API Service

✅ **COMPLETED** - Updated `src/services/api.ts` to:
1. Accept and store MSAL instance via `setMsalInstance()`
2. Acquire access tokens before API calls using `acquireTokenSilent()`
3. Include tokens in Authorization header as Bearer token
4. Handle authentication bypass flag
5. All API methods now include authentication headers

## Step 7: Update Navbar

✅ **COMPLETED** - Updated `src/components/navbar/navbar.tsx` to:
1. Import and render Login component
2. Display authentication UI in navbar

## Step 8: Update Home Component

✅ **COMPLETED** - Updated `src/pages/home/home.tsx` to:
1. Import `useMsal` from @azure/msal-react
2. Get MSAL instance from hook
3. Set MSAL instance on API service using useEffect

## Step 9: Azure App Registration Setup

In the Azure Entra admin center:
1. Register the React SPA application
2. Add redirect URI: `https://localhost:<YOUR_REACT_PORT>`
3. Configure platform as "Single-page application"
4. Add scope `access_as_user` under "Expose an API"
5. Note the Client ID and Tenant ID
6. Update values in `authConfig.ts`

## Step 10: Testing

1. Start the dev server: `npm run dev`
2. Navigate to `https://localhost:<YOUR_REACT_PORT>`
3. Click "Sign In" button in navbar
4. Authenticate with Azure credentials
5. Verify API calls include bearer tokens in Authorization header
6. Click "Sign Out" to test logout flow

## Implementation Details

### Authentication Flow
1. User clicks "Sign In" → `loginRedirect()` is called
2. User is redirected to Microsoft login page
3. After successful auth, redirected back to app
4. LOGIN_SUCCESS event fires → active account is set
5. Login component displays user name and "Sign Out" button

### Token Acquisition
1. Before each API call, `getAuthHeaders()` is invoked
2. Method calls `acquireTokenSilent()` to get access token
3. Token is cached by MSAL for subsequent requests
4. Token is included as `Bearer {token}` in Authorization header
5. If token refresh fails, user must sign in again

### Security Features
- Session storage for token caching (more secure than localStorage)
- Redirect flow instead of popup (better security)
- Token automatically refreshed by MSAL
- BYPASS_AUTHENTICATION flag for development
- Active account tracking across page loads

## Important Notes

- The `BYPASS_AUTHENTICATION` flag in `authConfig.ts` can be set to true to bypass authentication during development
- Session storage is used by default for security (better than localStorage)
- MSAL automatically handles token refresh
- The app uses redirect authentication (not popup) for better security
- MSAL instance is created outside component tree to prevent re-instantiation

## Troubleshooting

### Token not included in requests
- Ensure `apiService.setMsalInstance(instance)` is called in Home component
- Check that user is authenticated before making API calls
- Verify BYPASS_AUTHENTICATION is false

### Login redirect fails
- Verify redirect URI in Azure matches exactly: `https://localhost:<YOUR_REACT_PORT>`
- Check that platform is set to "Single-page application" in Azure
- Ensure CLIENT_ID and TENANT_ID are correct in authConfig.ts

### API returns 401 Unauthorized
- Verify API_SCOPES matches the exposed API scope in Azure
- Check that API is configured to validate the token
- Ensure API accepts tokens from your tenant

### User not staying logged in
- Check that session storage is enabled in browser
- Verify MSAL cache configuration in authConfig.ts
- Ensure event callback for LOGIN_SUCCESS is setting active account

## Status: ✅ Implementation Complete

All authentication components have been implemented and integrated into the React application. The app is ready for testing once Azure app registration values are configured in `authConfig.ts`.

