#!/bin/bash

# Certificate generation script
CERT_DIR="docker/nginx/ssl"
DOMAIN="localhost"

echo "Generating self-signed certificates for $DOMAIN..."

# Create directory if not exists
mkdir -p $CERT_DIR

# Generate private key
openssl genrsa -out $CERT_DIR/key.pem 4096

# Generate certificate signing request
openssl req -new -key $CERT_DIR/key.pem -out $CERT_DIR/csr.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"

# Generate self-signed certificate (valid for 365 days)
openssl x509 -req -days 365 -in $CERT_DIR/csr.pem \
    -signkey $CERT_DIR/key.pem -out $CERT_DIR/cert.pem

# Generate DH parameters for additional security
openssl dhparam -out $CERT_DIR/dhparam.pem 2048

# Clean up
rm $CERT_DIR/csr.pem

# Set permissions
chmod 600 $CERT_DIR/key.pem
chmod 644 $CERT_DIR/cert.pem
chmod 644 $CERT_DIR/dhparam.pem

echo "Certificates generated successfully!"
echo "Certificate: $CERT_DIR/cert.pem"
echo "Private Key: $CERT_DIR/key.pem"
echo "DH Params: $CERT_DIR/dhparam.pem"