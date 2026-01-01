import './app.css'

import Home from './pages/home/home'
import Navbar from './components/navbar/navbar'
import { Route, BrowserRouter, Routes, Link, useLocation } from 'react-router-dom'
import { About } from './pages/about/about'
import { SnackbarProvider } from './components/snackbar/snackbar'
import { MsalProvider } from '@azure/msal-react'
import DynamicHtmlLoader from './components/dynamic-html-loader/dynamic-html-loader'
import type { IPublicClientApplication } from '@azure/msal-browser'
import { useEffect } from 'react';

interface AppProps {
  msalInstance: IPublicClientApplication
}


function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);
  return null;
}

function App({ msalInstance }: AppProps) {
  const basename = "/todo/react";

  return (
    <MsalProvider instance={msalInstance}>
      <SnackbarProvider>
        <BrowserRouter basename={basename}>
          <div className="app-content">
            <ScrollToTop />
            <Navbar />
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/about" element={<About />} />
              <Route path="/privacy-policy" element={<DynamicHtmlLoader filePath="/policies/privacy-policy.html" />} />
              <Route path="/terms-of-use" element={<DynamicHtmlLoader filePath="/policies/terms-of-use.html" />} />
              <Route path="/delete-data" element={<DynamicHtmlLoader filePath="/policies/delete-data.html" />} />
            </Routes>
          </div>
          <footer className="footer">
            <Link to="/privacy-policy" style={{ marginRight: '2rem' }}>Privacy Policy</Link>
            <Link to="/terms-of-use" style={{ marginRight: '2rem' }}>Terms of Use</Link>
            <Link to="/delete-data">Delete Data</Link>
          </footer>
        </BrowserRouter>
      </SnackbarProvider>
    </MsalProvider>
  );
}

export default App
