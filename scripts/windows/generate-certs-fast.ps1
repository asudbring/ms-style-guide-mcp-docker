# Fast certificate generation script for testing
# Skips DH parameters to avoid long wait times

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
    if (Get-Command "openssl" -ErrorAction SilentlyContinue) {
        $OPENSSL_PATH = "openssl"
    } else {
        Write-Host "ERROR: OpenSSL not found!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Using OpenSSL at: $OPENSSL_PATH" -ForegroundColor Gray
Write-Host "Generating self-signed certificates for $DOMAIN (fast mode)..." -ForegroundColor Green

# Create directory if not exists
if (-not (Test-Path $CERT_DIR)) {
    New-Item -ItemType Directory -Path $CERT_DIR -Force | Out-Null
}

# Generate private key
Write-Host "Generating private key..." -ForegroundColor Yellow
& $OPENSSL_PATH genrsa -out "$CERT_DIR\key.pem" 2048

# Generate certificate signing request
Write-Host "Generating certificate signing request..." -ForegroundColor Yellow
& $OPENSSL_PATH req -new -key "$CERT_DIR\key.pem" -out "$CERT_DIR\csr.pem" -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"

# Generate self-signed certificate (valid for 365 days)
Write-Host "Generating self-signed certificate..." -ForegroundColor Yellow
& $OPENSSL_PATH x509 -req -days 365 -in "$CERT_DIR\csr.pem" -signkey "$CERT_DIR\key.pem" -out "$CERT_DIR\cert.pem"

# Clean up
Remove-Item "$CERT_DIR\csr.pem" -Force

Write-Host "Certificates generated successfully!" -ForegroundColor Green
Write-Host "Certificate: $CERT_DIR\cert.pem" -ForegroundColor Cyan
Write-Host "Private Key: $CERT_DIR\key.pem" -ForegroundColor Cyan
Write-Host "Note: DH parameters skipped for faster generation" -ForegroundColor Gray
