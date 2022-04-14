#!/bin/bash -ex
#script d'automatisation du déploiement d instance WP
source /var/www/fonctions.sh

printPoweredBy
check_root


#nom du site = virtualhost et nom du site
echo "Nom du site Wordpress"
read nomSite

echo "Nom de la base MySQL [default prefix wp_]"
read sqlBase

echo "Nom utilisateur MySQL"
read userSQL

echo "Mot de passe utilisateur MySQL"
read passwordUserSQL

echo "Nom d'utilisateur du pannel admin"
read userAdmin

echo "Mot de passe de l'utilisateur"
read passwordAdmin

echo "Email utilisateur"
read email

echo "Nom de domaine affilié"
read nomDomaine

##############################################
#               DL WORDPRESS
##############################################

webDir=/var/www
cd $webDir
mkdir $nomSite -p  && cd $nomSite

wget "https://fr.wordpress.org/latest-fr_FR.tar.gz"

gzip -d latest-fr_FR.tar.gz
tar -xvf latest-fr_FR.tar 2>&1 >/dev/null
rm latest-fr_FR.tar
mv wordpress/* . && rm -r wordpress
mv wp-config-sample.php wp-config.php

sed -i -e "s/votre_nom_de_bdd/$sqlBase/g" $webDir/$nomSite/wp-config.php
sed -i -e "s/votre_utilisateur_de_bdd/$userSQL/g" $webDir/$nomSite/wp-config.php
sed -i -e "s/votre_mdp_de_bdd/$passwordUserSQL/g" $webDir/$nomSite/wp-config.php


##############################################
#               Apache
##############################################

apacheDir=/etc/apache2
cd $apacheDir

cat <<EOF >>$apacheDir/sites-available/$nomSite.conf
<VirtualHost *:80>
        ServerName $nomDomaine

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/$nomSite
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
RewriteEngine on
RewriteCond %{SERVER_NAME} =$nomDomaine
RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
EOF

a2ensite $nomSite.conf
systemctl restart apache2

certbot --apache


##############################################
#               MYSQL
##############################################

mysql -e "DROP DATABASE IF EXISTS $sqlBase;"
mysql -e "DROP USER IF EXISTS $userSQL@localhost;"
mysql -Bse "CREATE DATABASE $sqlBase CHARACTER SET utf8;CREATE USER $userSQL@localhost IDENTIFIED BY '$passwordUserSQL';GRANT ALL ON $sqlBase.* TO $userSQL@localhost;FLUSH PRIVILEGES;"

##############################################
#               NOIP
##############################################

#API NO IP

##############################################
#               cURL
##############################################


curl --data-urlencode "weblog_title=$nomSite" \
     --data-urlencode "user_name=$userAdmin" \
     --data-urlencode "admin_password=$passwordUserAdmin" \
     --data-urlencode "admin_password2=$passwordUserAdmin" \
     --data-urlencode "admin_email=$email" \
     --data-urlencode "Submit=Install+WordPress" \
     https://$nomDomaine/wp-admin/install.php?step=2 /dev/null 2>&1



