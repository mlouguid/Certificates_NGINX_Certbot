# Certificates_NGINX_Certbot
Create Let’s Encrypt Wildcard Certificates in NGINX Certbot
visit the blog for more details : https://setupvm.com/ssl-certbot/

                                  **Create Let’s Encrypt Wildcard Certificates in NGINX**

                                                
Let’s Encrypt is a free, automated, and open certificate authority (CA) that provides SSL/TLS certificates for enabling HTTPS on your website. Let’s Encrypt wildcard certificates allow you to secure unlimited subdomains under a base domain (e.g. *.example.com).

In this tutorial, we will show you how to use Certbot to generate Let’s Encrypt wildcard certificates and set up HTTPS on an Nginx web server.

Prerequisites
Before following this guide, you’ll need:

A server running Ubuntu 20.04 with a public IPv4 address and a regular non-root user with sudo privileges.
Domain names pointing to your server’s public IP. In our examples, we will use example.com and *.example.com.
Ports 80 and 443 open on your server’s firewall.
Nginx installed on your server. If you don’t have it yet, you can install it with:

$ sudo apt install nginx

Certbot installed on your server. If it’s not already installed, you can install it with:

$ sudo apt install certbot python3-certbot-nginx

Once you have met all the prerequisites, let’s move on to generating wildcard certificates.

Step 1 — Generating Wildcard Certificates
Certbot includes a certonly command for obtaining SSL/TLS certificates. To generate a wildcard certificate for *.example.com, run:

$ sudo certbot certonly --manual --preferred-challenges=dns --server https://setupvm.com/ssl-certbot/ --agree-tos -d *.example.com

This tells Certbot to:

Use the “manual” plugin for obtaining certificates
Use the “dns” challenge to validate domain ownership
Use Let’s Encrypt’s ACME v2 API endpoint
Agree to Let’s Encrypt’s Terms of Service
Obtain a certificate for *.example.com
You will be prompted to enter an email address for certificate expiration notifications. Enter your email and press Enter.

Next, Certbot will provide TXT records that need to be created in your domain’s DNS to validate control over the domain. Create these TXT records in your DNS control panel, then press Enter to continue.

Certbot will wait for the DNS changes to propagate globally and verify the TXT records. If successful, the wildcard certificate (fullchain.pem) and private key (privkey.pem) will be saved under /etc/letsencrypt/live/example.com/.

Step 2 – Configuring Nginx
With the wildcard certificate generated, we can now configure Nginx.

First, create a new Nginx server block for the main example.com domain:

$ sudo nano /etc/nginx/sites-available/example.com

Add the following configuration:

server {
listen80;
listen [::]:80;
server_name example.com;
return301 https://$host$request_uri;
}
server {
listen443 ssl http2;
listen [::]:443 ssl http2;
server_name example.com;
ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
# Other SSL config
...
}
This configures HTTPS using the Let’s Encrypt certificate and redirects HTTP traffic to HTTPS.

Next, create a server block for the wildcard subdomain *.example.com:

$ sudo nano /etc/nginx/sites-available/wildcard.example.com
server {
listen80;
listen [::]:80;
server_name*.example.com;
return301 https://$host$request_uri;
}
server {
listen443 ssl http2;
listen [::]:443 ssl http2;

server_name*.example.com;
ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

Other SSL config
...
}
This wil handle all subdomains using the same wildcard certificate.

Activate the server blocks:

$ sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
$ sudo ln -s /etc/nginx/sites-available/wildcard.example.com /etc/nginx/sites-enabled/

Finally, test the Nginx configuration and reload it if successful:

$ sudo nginx -t
$ sudo systemctl reload nginx

Your wildcard certificate should now be working! Try accessing your site over HTTPS and various subdomains to confirm.

Automating Renewal
Let’s Encrypt certificates expire after 90 days, so you’ll need to renew them regularly.

You can automate renewal using Certbot’s renew command. Create a cron job to run daily:

$ sudo crontab -e
Add this line which will run Certbot daily and renew if certificates are expiring in less than 30 days:

0 0 * * * /usr/bin/certbot renew --quiet --post-hook "systemctl reload nginx"

This will renew your certificates automatically before they expire!

Conclusion
That’s it! You should now have Let’s Encrypt wildcard certificates issued by Certbot set up for your domain. This allows you to enable HTTPS across your main domain and any subdomains with just a single certificate.

The certificates will renew automatically, providing ongoing HTTPS protection for your site. This offers your visitors security, trust, and SEO benefits.

As Let’s Encrypt issues trusted certificates for free, there’s no reason not to use HTTPS everywhere with wildcard certificates. Enjoy your secured site!
