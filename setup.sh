#!/usr/bin/env bash

echo -e "\n\e[32m*******************************"
echo -e "* setup.sh - setup for edu-m2 *"
echo -e "*******************************\e[0m"

php_version=php7.0
site_domain='edu-m2.classaxe.com'

shopt -s expand_aliases
source /etc/profile.d/02-php-aliases.sh

echo -en "  Checking php version    \e[33;1m${php_version}\e[0m                "

if $(type -t ${php_version} 2) > /dev/null; then
    echo -e "\e[32m[OK]\e[0m";
else
    echo -e "\e[31;1m[ERROR]\n\e[0m\nSorry: ${php_version} must be available to proceed.\e[0m\n";
    exit 2
fi

echo -n "  Getting target folder ready:                  "
rm -rf /srv/www/edu-m2/magento
mkdir -p /srv/www/edu-m2/magento
echo -e "\e[32m[OK]\e[0m"

# Create local database schemas and users for all local sites and vhosts for them:
sites=(
#   "client  db_host     db_name   db_user   db_pass       php   web_host           web_aliases (space delimited)"
    "edu-m2  localhost   edu_m2    edu_m2    Password123   7.0   ${site_domain}     www.${site_domain}"
)

for i in "${sites[@]}"; do
    arr=(${i// / })
    client=${arr[0]}
    db_host=${arr[1]}
    db_name=${arr[2]}
    db_user=${arr[3]}
    db_pass=${arr[4]}
    php=${arr[5]}
    web_host=${arr[6]}
    web_aliases=""
    if [ -d /srv/www/${client}/magento ]; then
        home_dir="/srv/www/${client}/magento"
    else
        home_dir="/srv/www/${client}"
    fi
    for j in "${arr[@]:7}"; do
        web_aliases="${web_aliases} -a ${j}"
    done;

#    echo -en "  Creating mysql database \e[33;1m${db_name}\e[0m                "
#    echo "drop schema if exists ${db_name};" | MYSQL_PWD=root mysql -uroot
#    echo "create schema ${db_name};" | MYSQL_PWD=root mysql -uroot
#    echo -e "\e[32m[OK]\e[0m"
#    echo -en "  Creating mysql user     \e[33;1m${db_user}@${db_host}\e[0m      "
#    echo "grant all privileges on ${db_name}.* to '${db_user}'@'${db_host}' identified by '${db_pass}';" | MYSQL_PWD=root mysql -uroot
#    echo -e "\e[32m[OK]\e[0m"

#    echo -en "  Setting up apache vhost \e[33;1m${web_host}\e[0m   "
#    sudo vhost add -d ${home_dir} -n ${web_host} ${web_aliases} -p ${php} -f > /dev/null 2>&1
#    echo -e "\e[32m[OK]\e[0m"
#    echo -n "  Restarting apache                             "
#    sudo service apache2 restart > /dev/null 2>&1
#    echo -e "\e[32m[OK]\e[0m"
done

php_7=$(ls -1 /opt/phpfarm/inst | grep php-7.0 | tail -n1 | cut -d'-' -f2)"    "
echo -n "  Setting default PHP to ${php_7:0:8}               "
sudo /opt/phpfarm/inst/bin/switch-phpfarm ${php_7} > /dev/null 2>&1;
echo -e "\e[32m[OK]\e[0m"

echo "  Beginning Composer Installation:"
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /srv/www/edu-m2/magento

echo -n "  Begining Magento 2 Setup:                    "
cd /srv/www/edu-m2/magento

bin/magento sampledata:deploy

bin/magento setup:install \
--backend-frontname=admin \
--key=db23ad69b9028bc105e3ec8ac1cf62a8 \
--db-host=${db_host} \
--db-name=${db_name} \
--db-user=${db_user} \
--db-password=${db_pass} \
--db-init-statements='SET NAMES utf8;' \
--db-engine=mysql \
--admin-firstname="Admin" \
--admin-lastname="User" \
--admin-email="admin@example.com" \
--admin-user="admin" \
--admin-password="Password123" \
--base-url="https://${site_domain}/" \
--base-url-secure="https://${site_domain}/" \
--use-rewrites=1 \
--use-secure=1 \
--use-secure-admin=1 \
--currency=CAD \
--timezone=America/Toronto \
--session-save=db;


echo -e "\e[32m[OK]\e[0m"

external_ip=$(cat /vagrant/config.yml | grep vagrant_ip | cut -d' ' -f2 | xargs)
echo "  Add the following line to your host file:"
echo -e "    \e[33;1m${external_ip}      ${site_domain}\e[0m\n"
echo -e "  Access the site at:\n    \e[32;1mhttps://${site_domain}\e[0m\n"
echo -e "  Admin site details:\n    URL:    https://${site_domain}/admin\n    User:   admin\n    Pass:   Password123\n"

