# SSL Setup for React Todo App

This document explains the SSL/HTTPS configuration for the React Todo application.

## Overview

The React app is configured to run with HTTPS during development using self-signed certificates. This is necessary for:
- Testing authentication flows that require secure contexts
- Matching production-like environments
- Enabling secure cookies and modern browser APIs

**Two types of certificates are used:**
1. **Frontend Certificate** (shared with Angular) - Used by Vite dev server
2. **Backend Certificate** (.NET dev-certs) - Used by the ASP.NET API

## SSL Certificates

### Frontend Certificate (React & Angular)
The SSL certificates are located in the shared `../../ssl/` directory (at `Services/Web/ssl/`):
- `localhost.key` - Private key
- `localhost.crt` - Self-signed certificate

**Note**: These certificates are shared between both the Angular and React applications.

### Backend Certificate (.NET API)
The ASP.NET backend API uses a separate .NET developer certificate:
- **Generated with**: `dotnet dev-certs https --trust`
- **Purpose**: HTTPS endpoint for the backend API (typically https://localhost:7258)
- **Storage**: Managed by .NET in the Windows certificate store
- **Validity**: 1 year (can be regenerated with the same command)

## Vite Configuration

The HTTPS setup is configured in `vite.config.ts`:

```typescript
server: {
  https: {
    key: fs.readFileSync(path.resolve(__dirname, '../../ssl/localhost.key')),
    cert: fs.readFileSync(path.resolve(__dirname, '../../ssl/localhost.crt')),
  },
  port: 5173,
  // ... other settings
}
```

## Generating New Certificates

If you need to regenerate the SSL certificates, navigate to the shared ssl directory:

### Windows (PowerShell)

```powershell
# Navigate to the shared ssl directory
cd ..\..\ssl

# Generate a new private key and certificate
openssl req -x509 -newkey rsa:4096 -keyout localhost.key -out localhost.crt -days 365 -nodes -subj "/CN=localhost"
```

### Linux/macOS

```bash
# Navigate to the shared ssl directory
cd ../../ssl

# Generate a new private key and certificate
openssl req -x509 -newkey rsa:4096 -keyout localhost.key -out localhost.crt -days 365 -nodes -subj "/CN=localhost"
```

### Alternative: Using mkcert (Recommended)

For a better development experience, you can use [mkcert](https://github.com/FiloSottile/mkcert) which creates locally-trusted certificates:

```bash
# Install mkcert (one-time setup)
# Windows (using Chocolatey): choco install mkcert
# macOS: brew install mkcert
# Linux: Follow instructions at https://github.com/FiloSottile/mkcert

# Install the local CA
mkcert -install

# Generate certificates in the shared ssl directory
cd ../../ssl
mkcert localhost 127.0.0.1 ::1

# Rename the generated files
mv localhost+2.pem localhost.crt
mv localhost+2-key.pem localhost.key
```

## Browser Trust Issues

### Chrome/Edge

If you see security warnings:
1. Click "Advanced" on the warning page
2. Click "Proceed to localhost (unsafe)"

Or add the certificate to your trusted root certificates:
1. Open Chrome Settings → Privacy and Security → Security → Manage Certificates
2. Import `../../ssl/localhost.crt` into "Trusted Root Certification Authorities"

### Firefox

1. Click "Advanced" on the warning page
2. Click "Accept the Risk and Continue"

Or permanently add the exception:
1. Go to `about:preferences#privacy`
2. Scroll to "Certificates" → "View Certificates"
3. Import `../../ssl/localhost.crt` into "Authorities"

## Running the Application

### Full Stack Setup

**Start the backend API first:**
```bash
# Navigate to the API project directory
cd c:\repos\todo\Services\API
dotnet run
```
The API will run on `https://localhost:7258`

**Then start the React frontend:**
```bash
# Navigate to the React project directory
cd c:\repos\todo\Services\Web\React\todo
npm run dev
```

The application will be available at:
- **React App**: `https://localhost:5173`
- **Backend API**: `https://localhost:7258`

## Security Note

⚠️ **Important**: These are self-signed certificates for **development only**. Never use these certificates in production. For production, use proper certificates from a trusted Certificate Authority (CA) like Let's Encrypt.

- **Frontend Certificates**: The shared `../../ssl/` folder should be in `.gitignore`
- **Backend Certificate**: The .NET dev certificate is automatically managed and trusted by `dotnet dev-certs`
- **Private Keys**: Keep all private keys secure and never share them

## Backend Certificate Management

The .NET API requires its own developer certificate.

### Generate/Trust Backend Certificate
```bash
# Clean existing certificate and create a new trusted one
dotnet dev-certs https --trust
```

### Check Certificate Status
```bash
# Verify the certificate exists
dotnet dev-certs https --check
```

### Clean Certificate (if needed)
```bash
# Remove all HTTPS development certificates
dotnet dev-certs https --clean
```

### View in Certificate Store
```powershell
# View .NET developer certificate
Get-ChildItem -Path "cert:\CurrentUser\My" | Where-Object { $_.Subject -like "*localhost*" -and $_.Issuer -like "*localhost*" }
```

## Troubleshooting

### Certificate Expired
If the certificate has expired (after 365 days), regenerate it using the commands above.

### Port Already in Use
If port 5173 is already in use, you can change it in `vite.config.ts` or specify a different port:
```bash
npm run dev -- --port 5174
```

### Module Not Found Errors
Ensure the `fs` and `path` modules are available (they are Node.js built-in modules, so no installation needed).

### Backend API Certificate Errors
If you see "Unable to configure HTTPS endpoint" from the .NET API:
```bash
dotnet dev-certs https --trust
```

## Verification

After starting both the backend and frontend:

1. ✅ Backend API runs on `https://localhost:7258`
2. ✅ Frontend runs on `https://localhost:5173`
3. ✅ No certificate warnings in Chrome/Edge
4. ✅ Lock icon appears in the address bar for both
5. ✅ Azure Entra ID authentication works with HTTPS redirect URI
6. ✅ API calls from frontend to backend work without CORS/SSL errors
Ensure the `fs` and `path` modules are available (they are Node.js built-in modules, so no installation needed).
