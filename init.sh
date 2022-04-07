#!/bin/bash

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

## Fixing permissions for entrypoint.sh script
chmod +x confs/certbot/entrypoint.sh

read -p "Enter your domain, like nexus.example.com: " nexus_domain

domains=($nexus_domain www.$nexus_domain)
rsa_key_size=4096
data_path="./confs/certbot"
read -p "Enter your email (adding a valid address is strongly recommended): " email # Adding a valid address is strongly recommended
read -p "Select mode: 1 or 0 (1- testing)/(0 - actual deploy): " staging # Set to 1 if you're testing your setup to avoid hitting request limits

if [ -d "$data_path" ]; then
  sed -i 's/DOMAINNAME/'$domains'/g' ./confs/nginx/nginx.conf
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

## Cheking your input
echo "Check your input:"
echo
echo "Your domain: $nexus_domain
Your email: $email
Mode: $staging"
read -p "Is this correct? (y/N) " correct
  if [ "$correct" != "Y" ] && [ "$correct" != "y" ]; then
    exit
  fi

if [ ! -e "nexus-data/" ]; then
  echo "### Creating directory for nexus data..."
  mkdir nexus-data
  echo
  echo "### Changing ownership (requires sudo) for nexus data..."
  sudo chown -R 200:200 nexus-data 
fi
## Fix permissions anyway
sudo chown -R 200:200 nexus-data

## For guest from future, you may want to check if these links are still working, otherwise feel free to change them
if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
  echo
fi

echo "### Creating dummy certificate for $domains ..."
path="/etc/letsencrypt/live/$domains"
mkdir -p "$data_path/conf/live/$domains"
docker-compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:2048 -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot
echo


echo "### Starting nginx ..."
docker-compose up --force-recreate -d nginx
echo
sleep 5
echo "### Deleting dummy certificate for $domains ..."
docker-compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$domains && \
  rm -Rf /etc/letsencrypt/archive/$domains && \
  rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
echo


echo "### Requesting Let's Encrypt certificate for $domains ..."
#Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal \
    --no-eff-email \
    -v" certbot
echo

echo "### Reloading nginx ..."
docker-compose exec nginx nginx -s reload
docker-compose up -d

until curl -sk -f https://$domains -o /dev/null ; do
    sleep 5
done
adminpass=`docker-compose exec nexus cat /nexus-data/admin.password`
echo '### nexus admin username: admin'
echo '### nexus admin password:' $adminpass
echo '### change your password after login ###'
echo "### You can visit your Nexus OSS Repository here: https://$domains "
