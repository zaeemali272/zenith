#!/usr/bin/env bash

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting Automated LAMP + phpMyAdmin Setup for Arch Linux...${NC}"

# 1. Install Core Packages
echo -e "${GREEN}Step 1: Installing Apache, PHP, MariaDB, and phpMyAdmin...${NC}"
sudo pacman -Syu --needed apache mariadb php php-apache phpmyadmin

# 2. Configure Apache (httpd.conf)
echo -e "${GREEN}Step 2: Configuring Apache for PHP...${NC}"
CONF="/etc/httpd/conf/httpd.conf"
sudo cp $CONF "$CONF.bak"

# Swap MPM Event for Prefork (Required for PHP module)
sudo sed -i 's/^LoadModule mpm_event_module/#LoadModule mpm_event_module/' $CONF
sudo sed -i 's/^#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/' $CONF

# Inject PHP Module and Handler
if ! grep -q "php_module" "$CONF"; then
    echo -e "\nLoadModule php_module modules/libphp.so\nAddHandler php-script .php\nInclude conf/extra/php_module.conf" | sudo tee -a $CONF
fi

# Ensure DirectoryIndex includes index.php
sudo sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' $CONF

# 3. Configure PHP Extensions for phpMyAdmin
echo -e "${GREEN}Step 3: Enabling PHP extensions in php.ini...${NC}"
PHPINI="/etc/php/php.ini"
sudo sed -i 's/^;extension=bz2/extension=bz2/' $PHPINI
sudo sed -i 's/^;extension=iconv/extension=iconv/' $PHPINI
sudo sed -i 's/^;extension=mysqli/extension=mysqli/' $PHPINI
sudo sed -i 's/^;extension=pdo_mysql/extension=pdo_mysql/' $PHPINI

# 4. Configure phpMyAdmin Apache Alias
echo -e "${GREEN}Step 4: Creating Apache configuration for phpMyAdmin...${NC}"
PMACONF="/etc/httpd/conf/extra/phpmyadmin.conf"
sudo bash -c "cat > $PMACONF" <<EOF
Alias /phpmyadmin "/usr/share/webapps/phpMyAdmin"
<Directory "/usr/share/webapps/phpMyAdmin">
    DirectoryIndex index.php
    AllowOverride All
    Options FollowSymlinks
    Require all granted
</Directory>
EOF

# Include phpmyadmin config in main httpd.conf if not already there
if ! grep -q "phpmyadmin.conf" "$CONF"; then
    echo "Include conf/extra/phpmyadmin.conf" | sudo tee -a $CONF
fi

# Create phpMyAdmin temp directory for PHP 8.x
sudo mkdir -p /usr/share/webapps/phpMyAdmin/tmp
sudo chown http:http /usr/share/webapps/phpMyAdmin/tmp

# 5. Setup Project Directory
echo -e "${GREEN}Step 5: Setting up /srv/http/web-test...${NC}"
sudo mkdir -p /srv/http/web-test
sudo chown -R $USER:http /srv/http/web-test
sudo chmod -R 775 /srv/http/web-test
echo "<h1>Success!</h1><?php phpinfo(); ?>" > /srv/http/web-test/index.php

# 6. Initialize MariaDB
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo -e "${GREEN}Step 6: Initializing MariaDB...${NC}"
    sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi

# 7. Start Services
echo -e "${GREEN}Step 7: Starting Services...${NC}"
sudo systemctl enable --now httpd
sudo systemctl enable --now mariadb

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "Web Project: http://localhost/web-test/"
echo -e "Database Manager: http://localhost/phpmyadmin/"
echo -e "${BLUE}=======================================${NC}"
