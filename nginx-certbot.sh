#!/bin/bash

# Update and install dependencies
echo "Updating and installing dependencies..."
sudo apt update -y
sudo apt install -y nginx certbot python3-certbot-nginx

# Define domain
DOMAIN="example.com"

# Generate Let's Encrypt Wildcard Certificate using Certbot
echo "Generating wildcard SSL certificate for *.$DOMAIN..."
sudo certbot certonly --manual --preferred-challenges=dns --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d *.$DOMAIN -d $DOMAIN

# Check if certbot succeeded
if [ $? -eq 0 ]; then
    echo "Certificate generated successfully."
else
    echo "Error generating certificate. Exiting."
    exit 1
fi

# Configure Nginx for the main domain
echo "Configuring Nginx for $DOMAIN..."

# Create Nginx config for main domain
cat <<EOF | sudo tee /etc/nginx/sites-available/$DOMAIN
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # Add your additional SSL config here
    # Other SSL configurations
}
EOF

# Configure Nginx for wildcard subdomains
echo "Configuring Nginx for *.${DOMAIN}..."

# Create Nginx config for wildcard subdomains
cat <<EOF | sudo tee /etc/nginx/sites-available/wildcard.$DOMAIN
server {
    listen 80;
    listen [::]:80;
    server_name *.${DOMAIN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name *.${DOMAIN};

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # Add your additional SSL config here
    # Other SSL configurations
}
EOF

# Enable the Nginx configurations
echo "Enabling Nginx server blocks..."
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/wildcard.$DOMAIN /etc/nginx/sites-enabled/

# Test and reload Nginx
echo "Testing Nginx configuration..."
sudo nginx -t
if [ $? -eq 0 ]; then
    echo "Nginx configuration is valid. Reloading Nginx..."
    sudo systemctl reload nginx
else
    echo "Nginx configuration is invalid. Please check the error above."
    exit 1
fi

# Set up automatic certificate renewal
echo "Setting up automatic certificate renewal..."
sudo crontab -l | { cat; echo "0 0 * * * /usr/bin/certbot renew --quiet --post-hook \"systemctl reload nginx\""; } | sudo crontab -

echo "SSL wildcard certificate setup complete! Your site is now secured with HTTPS."
