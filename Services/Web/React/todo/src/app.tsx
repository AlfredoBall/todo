import './app.css'

import Home from './pages/home/home'
import Navbar from './components/navbar/navbar'
import { Route, BrowserRouter as Router, Routes, Link, useLocation } from 'react-router-dom'
import { About } from './pages/about/about'
import { SnackbarProvider } from './components/snackbar/snackbar'
import { MsalProvider } from '@azure/msal-react'
import PrivacyPolicy from './pages/privacy-policy/privacy-policy'
import TermsOfUse from './pages/terms-of-use/terms-of-use'
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
  return (
    <MsalProvider instance={msalInstance}>
      <SnackbarProvider>
        <Router>
          <ScrollToTop />
          <Navbar />
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/about" element={<About />} />
            <Route path="/privacy-policy" element={<PrivacyPolicy />} />
            <Route path="/terms-of-use" element={<TermsOfUse />} />
          </Routes>
          <footer style={{ textAlign: 'center', margin: '2rem 0 1rem 0', fontSize: '1.05em' }}>
            <Link to="/privacy-policy" style={{ marginRight: '2rem' }}>Privacy Policy</Link>
            <Link to="/terms-of-use">Terms of Use</Link>
          </footer>
        </Router>
      </SnackbarProvider>
    </MsalProvider>
  )
}

export default App
