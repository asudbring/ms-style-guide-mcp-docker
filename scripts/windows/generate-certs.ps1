# Certificate generation script
# PowerShell equivalent of generate-certs.sh

$CERT_DIR = "docker\nginx\ssl"
$DOMAIN = "localhost"

# Find OpenSSL executable
$OPENSSL_PATH = $null
$gitOpenSSLPaths = @(
    "C:\Program Files\Git\usr\bin\openssl.exe",
    "C:\Program Files (x86)\Git\usr\bin\openssl.exe"
)

foreach ($path in $gitOpenSSLPaths) {
    if (Test-Path $path) {
        $OPENSSL_PATH = $path
        break
    }
}

if (-not $OPENSSL_PATH) {
    # Try to find openssl in PATH
    if (Get-Command "openssl" -ErrorAction SilentlyContinue) {
        $OPENSSL_PATH = "openssl"
    } else {
        Write-Host "ERROR: OpenSSL not found!" -ForegroundColor Red
        Write-Host "Please install Git for Windows or OpenSSL" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Using OpenSSL at: $OPENSSL_PATH" -ForegroundColor Gray
Write-Host "Generating self-signed certificates for $DOMAIN..." -ForegroundColor Green

# Create directory if not exists
if (-not (Test-Path $CERT_DIR)) {
    New-Item -ItemType Directory -Path $CERT_DIR -Force | Out-Null
}

# Generate private key (using 2048 for faster generation)
Write-Host "Generating private key..." -ForegroundColor Yellow
& $OPENSSL_PATH genrsa -out "$CERT_DIR\key.pem" 2048

# Generate certificate signing request
Write-Host "Generating certificate signing request..." -ForegroundColor Yellow
& $OPENSSL_PATH req -new -key "$CERT_DIR\key.pem" -out "$CERT_DIR\csr.pem" -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"

# Generate self-signed certificate (valid for 365 days)
Write-Host "Generating self-signed certificate..." -ForegroundColor Yellow
& $OPENSSL_PATH x509 -req -days 365 -in "$CERT_DIR\csr.pem" -signkey "$CERT_DIR\key.pem" -out "$CERT_DIR\cert.pem"

# Generate DH parameters for additional security (optional for development)
Write-Host "Skipping DH parameters for faster generation (fine for development)" -ForegroundColor Gray
# Uncomment the next lines if you need DH parameters for production:
# Write-Host "Generating DH parameters (this may take a moment)..." -ForegroundColor Yellow
# & $OPENSSL_PATH dhparam -out "$CERT_DIR\dhparam.pem" 1024

# Clean up
Remove-Item "$CERT_DIR\csr.pem" -Force

# Note: Windows doesn't have chmod, but we can set file permissions using icacls if needed
# For basic usage, the default permissions should be sufficient

Write-Host "Certificates generated successfully!" -ForegroundColor Green
Write-Host "Certificate: $CERT_DIR\cert.pem" -ForegroundColor Cyan
Write-Host "Private Key: $CERT_DIR\key.pem" -ForegroundColor Cyan
