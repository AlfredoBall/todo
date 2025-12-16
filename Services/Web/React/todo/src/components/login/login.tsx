import './login.css';
import { useMsal } from '@azure/msal-react';
import { loginRequest, AUTH_CONFIG } from '../../auth-config';
import { useEffect, useState } from 'react';

export default function Login() {
  const { instance, accounts, inProgress } = useMsal();
  const [userDisplayName, setUserDisplayName] = useState<string>('');
  
  const isAuthenticated = accounts.length > 0;

  useEffect(() => {
    if (isAuthenticated) {
      const activeAccount = instance.getActiveAccount() || accounts[0];

      if (!instance.getActiveAccount()) {
        instance.setActiveAccount(activeAccount);
      }

      setUserDisplayName(activeAccount?.name || activeAccount?.username || 'User');
    }
  }, [accounts, instance, isAuthenticated]);

  const handleLogin = () => {
    instance.loginRedirect(loginRequest).catch((error) => console.error(error));
  };

  const handleLogout = () => {
    instance.logoutRedirect({
      postLogoutRedirectUri: AUTH_CONFIG.POST_LOGOUT_REDIRECT_URI
    }).catch((error) => console.error(error));
  };

  // Don't render anything while authentication is in progress
  if (inProgress !== 'none') {
    return null;
  }

  return (
    <div className="login-container">
      {isAuthenticated ? (
        <div className="user-info">
          <span className="user-name">{userDisplayName}</span>
          <button className="btn btn-logout" onClick={handleLogout}>
            Sign Out
          </button>
        </div>
      ) : (
        <button className="btn btn-login" onClick={handleLogin}>
          Sign In
        </button>
      )}
    </div>
  );
}