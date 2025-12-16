# 🔒 SSL Certificate Setup for Angular Development

## ✅ What's Been Configured

Self-signed SSL certificates have been created and configured for HTTPS development on localhost.

### Frontend Certificates (Angular & React)
Shared certificates are used for the Angular and React development servers.

### Certificate Details
- **Location**: `../../ssl/` folder (shared with React app)
- **Files Created**:
  - `localhost.pfx` - Certificate with private key (password-protected)
  - `localhost.crt` - Public certificate
  - `localhost.key` - Private key (PEM format)
- **Thumbprint**: `B0A8535F087198296423B505861D93DAE83B99EC`
- **Validity**: 5 years
- **Password**: `dev-password` (for PFX file)

### Installation Status
✔️ Certificate created in LocalMachine\My store  
✔️ Certificate added to Trusted Root Certification Authorities  
✔️ Certificate files exported to ../../ssl/ folder  
✔️ Angular configured to use certificate (angular.json)  

### Backend Certificate (.NET API)
The ASP.NET backend API uses a separate .NET developer certificate:
- **Generated with**: `dotnet dev-certs https --trust`
- **Purpose**: HTTPS endpoint for the backend API (typically https://localhost:7258)
- **Storage**: Managed by .NET in the Windows certificate store
- **Validity**: 1 year (can be regenerated with the same command)  

## 🚀 Usage

### Running the Full Stack Application

**Start the backend API first:**
```bash
# Navigate to the API project directory
cd c:\repos\todo\Services\API
dotnet run
```
The API will run on `https://localhost:7258`

**Then start the Angular frontend:**
```bash
# Navigate to the Angular project directory
cd c:\repos\todo\Services\Web\Angular\todo
ng serve
```

The application will now run on:
- **Angular App**: `https://localhost:4200`
- **Backend API**: `https://localhost:7258`
- HTTP redirect configured via proxy

### Browser Trust

The certificate is installed in the Windows Trusted Root store, so:
- ✅ **Chrome/Edge**: Will trust the certificate automatically
- ✅ **Firefox**: May require manual trust (Firefox uses its own certificate store)

#### For Firefox:
1. Navigate to `https://localhost:4200`
2. Click "Advanced" on the warning page
3. Click "Accept the Risk and Continue"

## 🔧 Configuration Files

### angular.json
```json
"serve": {
  "builder": "@angular/build:dev-server",
  "options": {
    "proxyConfig": "proxy.conf.js",
    "ssl": true,
    "sslCert": "../../ssl/localhost.crt",
    "sslKey": "../../ssl/localhost.key"
  }
}
```

### auth-config.ts
Update the redirect URIs to use HTTPS:
```typescript
export const AUTH_CONFIG = {
  REDIRECT_URI: 'https://localhost:4200',
  POST_LOGOUT_REDIRECT_URI: 'https://localhost:4200'
  // ... other config
};
```

### Azure App Registration
Update your Azure app registration redirect URIs from:
- ❌ `http://localhost:4200`

To:
- ✅ `https://localhost:4200`

## 🔄 Certificate Management

### Frontend Certificates

#### View Installed Certificates
```powershell
# View certificate in Personal store
Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object { $_.FriendlyName -eq "Angular Dev Certificate" }

# View certificate in Trusted Root store
Get-ChildItem -Path "cert:\LocalMachine\Root" | Where-Object { $_.Thumbprint -eq "B0A8535F087198296423B505861D93DAE83B99EC" }
```

#### Remove Certificate (if needed)
```powershell
$thumbprint = "B0A8535F087198296423B505861D93DAE83B99EC"

# Remove from Personal store
Get-ChildItem -Path "cert:\LocalMachine\My\$thumbprint" | Remove-Item

# Remove from Trusted Root store
Get-ChildItem -Path "cert:\LocalMachine\Root\$thumbprint" | Remove-Item
```

#### Regenerate Certificate (if expired)
```powershell
# Run as Administrator
cd c:\repos\todo\Services\Web\ssl

# Create new certificate
$cert = New-SelfSignedCertificate -DnsName "localhost" `
    -CertStoreLocation "cert:\LocalMachine\My" `
    -FriendlyName "Angular Dev Certificate" `
    -KeyUsageProperty All `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -NotAfter (Get-Date).AddYears(5)

$thumbprint = $cert.Thumbprint
Write-Host "New certificate thumbprint: $thumbprint"

# Export to PFX
$pwd = ConvertTo-SecureString -String "dev-password" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "localhost.pfx" -Password $pwd

# Export to CRT
$certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
[System.IO.File]::WriteAllBytes((Join-Path $PWD "localhost.crt"), $certBytes)

# Export private key to PEM
$rsaKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
$keyBytes = $rsaKey.ExportRSAPrivateKey()
$keyBase64 = [System.Convert]::ToBase64String($keyBytes)
$keyPem = "-----BEGIN RSA PRIVATE KEY-----`n"
for($i = 0; $i -lt $keyBase64.Length; $i += 64) {
    $keyPem += $keyBase64.Substring($i, [Math]::Min(64, $keyBase64.Length - $i)) + "`n"
}
$keyPem += "-----END RSA PRIVATE KEY-----"
Set-Content -Path "localhost.key" -Value $keyPem

# Add to Trusted Root
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root","LocalMachine")
$store.Open("ReadWrite")
$store.Add($cert)
$store.Close()

Write-Host "Certificate regenerated successfully!"
```

### Backend Certificate (.NET API)

#### Regenerate/Trust Certificate
```bash
# Clean existing certificate and create a new trusted one
dotnet dev-certs https --trust
```

#### Check Certificate Status
```bash
# Verify the certificate exists
dotnet dev-certs https --check
```

#### Clean Certificate (if needed)
```bash
# Remove all HTTPS development certificates
dotnet dev-certs https --clean
```

#### View in Certificate Store
```powershell
# View .NET developer certificate
Get-ChildItem -Path "cert:\CurrentUser\My" | Where-Object { $_.Subject -like "*localhost*" -and $_.Issuer -like "*localhost*" }
```

## 🛡️ Security Notes

- ⚠️ **Development Only**: These certificates are for development purposes only
- ⚠️ **Never Commit**: The `../../ssl/` folder should be in `.gitignore`
- ⚠️ **Private Key**: Keep the private key secure and never share it
- ⚠️ **Password**: The PFX password (`dev-password`) is simple for development; change it for any sensitive use
- ⚠️ **Backend Certificate**: The .NET dev certificate is automatically managed and trusted by `dotnet dev-certs`

## ✅ Verification

After starting both the backend and frontend:

1. ✅ Backend API runs on `https://localhost:7258`
2. ✅ Frontend runs on `https://localhost:4200`
3. ✅ No certificate warnings in Chrome/Edge
4. ✅ Lock icon appears in the address bar for both
5. ✅ Azure Entra ID authentication works with HTTPS redirect URI
6. ✅ API calls from frontend to backend work without CORS/SSL errors

## 🔗 Related Files

- [AUTHENTICATION.md](./AUTHENTICATION.md) - Azure Entra ID setup guide
- [AUTH_SETUP.md](./AUTH_SETUP.md) - Quick authentication setup
- [auth-config.ts](./src/app/auth-config.ts) - Authentication configuration
- [angular.json](./angular.json) - Angular CLI configuration
