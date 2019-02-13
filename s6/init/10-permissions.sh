  #!/usr/bin/with-contenv bash

chmod -R 755 /var/www/app/storage
chown -R www-data:www-data /var/www/app/storage /var/www/app/bootstrap /var/www/app/public/logo /var/www/app/.env