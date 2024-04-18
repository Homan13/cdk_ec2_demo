#!/bin/bash
#
## Configure a Wordpress based LAMP stack running on a Linux instance (Amazon Linux 2, Amazon Linux 2023, RHEL 9 and Ubuntu (22.04))
## This is an Apache based installation
## Inspired by https://www.how2shout.com/linux/script-to-install-lamp-wordpress-on-ubuntu-20-04-lts-server-quickly-with-one-command/
#
## Variables
#
platform=$(cat /etc/*release | grep -w ^NAME | sed 's/NAME=//')
version=$(cat /etc/*release | grep -w ^VERSION | sed 's/VERSION=//')
#
## Update instance and install Apache, MariaDB, PHP and other utilities
#
if [[ $platform == '"Amazon Linux"' ]] && [[ $version == '"2"' ]]; then
   echo "Updating and installing packages on Amazon Linux 2"
   yum update -y
   yum install lynx -y
   amazon-linux-extras enable php8.2 && yum clean metadata
   curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
   bash mariadb_repo_setup --os-type=rhel  --os-version=7 --mariadb-server-version=10.11
   rm -rf /var/cache/yum
   yum makecache
   amazon-linux-extras install epel -y
   yum install httpd -y
   yum install MariaDB-server MariaDB-client jemalloc -y
   amazon-linux-extras install php8.2 -y
   yum install php-bz2 php-mysqli php-curl php-gd php-intl php-common php-mbstring php-xml -y

   setenforce 0
  
   sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/httpd/conf/httpd.conf
   systemctl enable httpd
   systemctl start httpd

   systemctl enable mariadb
   systemctl start mariadb

elif [[ $platform == '"Amazon Linux"' ]] && [[ $version == '"2023"' ]]; then
   echo "Updating and installing packages on Amazon Linux 2023"
   dnf update -y
   dnf install lynx -y
   dnf install httpd -y
   dnf install mariadb105 mariadb105-server -y
   dnf install php -y
   dnf install php-bz2 php-mysqli php-curl php-gd php-intl php-common php-mbstring php-xml -y

   sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/httpd/conf/httpd.conf
   systemctl enable httpd
   systemctl start httpd

   systemctl enable mariadb
   systemctl start mariadb

elif [[ $platform == '"Red Hat Enterprise Linux"' ]]; then
   echo "Updating and installing packages on Red Hat Enterprise Linux"
   dnf update -y
   dnf install lynx wget -y
   dnf install httpd -y
   dnf install mariadb mariadb-server -y
   dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
   dnf install http://rpms.remirepo.net/enterprise/remi-release-9.rpm -y
   dnf module reset php -y
   dnf module install php:remi-8.2 -y
   dnf install php -y
   dnf install php-bz2 php-mysqli php-curl php-gd php-intl php-common php-mbstring php-xml -y

   sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/httpd/conf/httpd.conf
   systemctl enable httpd
   systemctl start httpd

   systemctl enable mariadb
   systemctl start mariadb

elif [[ $platform == '"Ubuntu"' ]]; then
   echo "Updating and installing packages on Ubuntu"
   apt update -y && apt upgrade -y
   apt install lynx dirmngr ca-certificates software-properties-common apt-transport-https curl -y
   apt install apache2 -y
   rm -rf /var/www/html/index.html
   curl -fsSL http://mirror.mariadb.org/PublicKey_v2 | sudo gpg --dearmor | sudo tee /usr/share/keyrings/mariadb.gpg > /dev/null
   echo "deb [arch=amd64,arm64,ppc64el signed-by=/usr/share/keyrings/mariadb.gpg] http://mirror.mariadb.org/repo/10.11/ubuntu/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mariadb.list
   apt update
   apt install mariadb-server mariadb-client -y
   add-apt-repository ppa:ondrej/php -y
   apt update
   apt install php8.2 -y
   apt install php8.2-bz2 php8.2-mysql php8.2-curl php8.2-gd php8.2-intl php8.2-common php8.2-mbstring php8.2-xml -y

   sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/apache2/apache2.conf
   systemctl enable apache2
   systemctl start apache2

   systemctl enable mariadb
   systemctl start mariadb
   
else
   echo "Unsupported version of Linux"

fi
#
## MySQL secure installation
#
mysql -sfu root <<EOS
-- set root password
ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password;
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('Password12345');
-- delete anonymous users
DELETE FROM mysql.user WHERE User='';
-- delete remote root capabilities
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- drop database 'test'
DROP DATABASE IF EXISTS test;
-- also make sure there are lingering permissions to it
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- make changes immediately
FLUSH PRIVILEGES;
EOS
touch /root/.my.cnf
chmod 640 /root/.my.cnf
echo "[client]">>/root/.my.cnf
echo "user=root">>/root/.my.cnf
echo "password=Password12345">>/root/.my.cnf
#
## Download, extract and configure WordPress
#
if test -f /tmp/latest.tar.gz; then
   echo "WordPress has already been downloaded"
else
   echo "Downloading WordPress installation package"
   cd /tmp/ && wget "http://wordpress.org/latest.tar.gz";
   tar -C /var/www/html -zxf /tmp/latest.tar.gz --strip-components=1
   if [[ $platform == '"Amazon Linux"' ]] || [[ $platform == '"Red Hat Enterprise Linux"' ]]; then
      chown apache: /var/www/html -R
   else [[ $platform == '"Ubuntu"' ]]
      chown www-data: /var/www/html -R
      systemctl restart apache2
   fi
fi
#
## Create wp-config and configure DB
#
mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s/database_name_here/wordpress/g" /var/www/html/wp-config.php
sed -i "s/username_here/wpuser/g" /var/www/html/wp-config.php
sed -i "s/password_here/Password12345/g" /var/www/html/wp-config.php
cat << EOF >> /var/www/html/wp-config.php
define('FS_METHOD', 'direct');
EOF
cat << EOF >> /var/www/html/.htaccess
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF
#
## Set WordPress salts
#
grep -A50 'table_prefix' /var/www/html/wp-config.php > /tmp/wp-tmp-config
sed -i '/**#@/,/$p/d' /var/www/html/wp-config.php
lynx --dump -width 200 https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/html/wp-config.php
cat /tmp/wp-tmp-config >> /var/www/html/wp-config.php && rm /tmp/wp-tmp-config -f
mysql -u root -e "CREATE DATABASE wordpress;"
mysql -u root -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'Password12345';"
mysql -u root -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
#
## System Cleanup
#
rm -rf ~/wordpress.sh
rm -rf /tmp/latest.tar.gz