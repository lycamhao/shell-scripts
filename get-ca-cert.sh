#!/bin/bash

# URL and Port
URL="rsv01.oncall.vn"
PORT=8887

# Get the SSL certificate
echo "Fetching certificate from $URL:$PORT..."
CERTIFICATE=$(echo | openssl s_client -servername "$URL" -connect "$URL:$PORT" 2>/dev/null | openssl x509)

# Display the certificate
echo "Certificate:"
echo "$CERTIFICATE"

# Optionally save the certificate to a file
CERT_FILE="certificate.pem"
echo "$CERTIFICATE" > "$CERT_FILE"
echo "Certificate saved to $CERT_FILE"