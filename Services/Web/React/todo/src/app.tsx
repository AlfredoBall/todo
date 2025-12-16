import './app.css'
import Home from './pages/home/home'
import Navbar from './components/navbar/navbar'
import { Route, BrowserRouter as Router, Routes } from 'react-router-dom'
import { About } from './pages/about/about'
import { SnackbarProvider } from './components/snackbar/snackbar'
import { MsalProvider } from '@azure/msal-react'
import type { IPublicClientApplication } from '@azure/msal-browser'

interface AppProps {
  msalInstance: IPublicClientApplication
}

function App({ msalInstance }: AppProps) {
  return (
    <MsalProvider instance={msalInstance}>
      <SnackbarProvider>
        <Router>
          <Navbar />
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/about" element={<About />} />
          </Routes>
        </Router>
      </SnackbarProvider>
    </MsalProvider>
  )
}

export default App
