#!/bin/bash
#script d'automatisation du déploiement d instance WP
source /var/www/fonctions.sh

printPoweredBy
check_root

#nom du site = virtualhost et nom du site

while true
do
	echo "Nom du site Wordpress"
	read nomSite
	if [[ $nomSite =~ [a-zA-Z0-9] ]]; then 
	    echo "nom site regex ok"
	    break 
	else 
	    echo "wrong regex character" 
	fi
done


while true
do
	echo "Nom de la base MySQL [default prefix wp_]"
	read sqlBase 
	if [[ $sqlBase =~ [a-zA-Z0-9] ]]; then 
	    echo "SQL regex ok"
	    break 
	else 
	    echo "wrong character" 
	fi
done


while true
do
	echo "Nom utilisateur MySQL"
	read userSQL
	if [[ $userSQL =~ [a-zA-Z0-9] ]]; then 
	    echo "SQL user ok"
	    break 
	else 
	    echo "wrong character" 
	fi
done


while true
do
	echo "Mot de passe utilisateur MySQL (min 8 carac, 1 maj 1 chiffre)"
	read passwordUserSQL
	if [[ ${#passwordUserSQL} -ge 8 && "$passwordUserSQL" == *[A-Z]* && "$passwordUserSQL" == *[a-z]* && "$passwordUserSQL" == *[0-9]* ]]; then 
	    echo "SQL user password regex ok" 
	    break
	else 
	    echo "regex not satisfied" 
	fi
done

while true
do
	echo "Nom d'utilisateur du pannel admin"
	read userAdmin
	if [[ $userAdmin =~ [a-zA-Z0-9] ]]; then 
	    echo "WP admin regex ok"
	    break 
	else 
	    echo "wrong regex" 
	fi
done


while true
do
	echo "Mot de passe de l'utilisateur"
	read passwordAdmin
	if [[ ${#passwordAdmin} -ge 8 && "$passwordAdmin" == *[A-Z]* && "$passwordAdmin" == *[a-z]* && "$passwordAdmin" == *[0-9]* ]]; then 
	    echo "SQL user password regex ok" 
	    break
	else 
	    echo "regex not satisfied" 
	fi
done



while true
do
	echo "Email utilisateur"
	read email
	if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]; then 
	    echo "email regex ok" 
	    break
	else 
	    echo "wrong email regex" 
	fi
done




while true
do
	echo "Nom de domaine"
	read nomDomaine
	if [[ $nomDomaine =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$ ]]; then 
	    echo "nom de domaine ok" 
	    break
	else 
	    echo "wrong domain name regex" 
	fi
done

exit


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

mysql -Bse "CREATE DATABASE IF EXISTS $sqlBase CHARACTER SET utf8;CREATE USER IF EXISTS $userSQL@localhost IDENTIFIED BY '$passwordUserSQL';GRANT ALL ON $sqlBase.* TO $userSQL@localhost;FLUSH PRIVILEGES;"

##############################################
#               NOIP
##############################################

#API NO IP

##############################################
#               cURL
##############################################

#curl POST pour l'install 
curl --data-urlencode "weblog_title=$nomSite" \
     --data-urlencode "user_name=$userAdmin" \
     --data-urlencode "admin_password=$passwordUserAdmin" \
     --data-urlencode "admin_password2=$passwordUserAdmin" \
     --data-urlencode "admin_email=$email" \
     --data-urlencode "Submit=Install+WordPress" \
     https://$nomDomaine/wp-admin/install.php?step=2 /dev/null 2>&1



