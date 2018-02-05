#!/bin/bash
# ------------------------------------------------------------------------
# Suppression automatique d'un site nginx avec PHP
#
# author : Bernard Pardo
# Created : 02/01/2018
# Contact: bernard.pardo@gmail.com
# Site : https://tech.pardo.mobi
# ------------------------------------------------------------------------

###### PARAMETRES

NGINX_CONFIG='/etc/nginx/sites-available'
NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
NGINX_INIT='/etc/init.d/nginx'

PHP_POOL_DIRECTORY='/etc/php/7.0/fpm/pool.d'


#PHP_FPM_INIT='/etc/init.d/php5-fpm'


####################### NE PAS MODIFIER CI-DESSOUS #######################

PATH_SCRIPT="$( cd "$( dirname "$0" )" && pwd )"
. "$PATH_SCRIPT/include/colors.sh"
. "$PATH_SCRIPT/include/myfuncs.sh"


# ----- BANNER
echo -e "\n${grisclair}"
echo -e "#######################################"
echo -e "##    SUPPRESSION D'UN SITE WEB      ##"
echo -e "#######################################${neutre}\n"

if [ -z ${1} ]; then
    Error "Aucun domaine n'a été transmis que la ligne de commande"
    exit 1
fi

if [ -z ${2} ]; then
    Error "Aucun Nom d'utilisateur pour le domaine n'a été transmis à la ligne de commande"
    exit 1
fi

DOMAIN=$1
USERNAME=$2

Info "Desinstallation du domaine : $vert${DOMAIN}$info pour l'utilisateur $vert${USERNAME}$neutre"

echo "Vérification de la validité du domaine"
# check the domain is valid!
PATTERN="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$";
if [[ "$DOMAIN" =~ $PATTERN ]]; then
    DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
else
    Error "invalid domain name"
    exit 1
fi


# Suppression de la description du pool PHP

POOL_PHP="/etc/php/7.0/fpm/pool.d/$USERNAME.conf"

Info "Vérification si un POOL PHP existe ( $POOL_PHP )..."
if [ -f $POOL_PHP ]; then
  Info "  > Suppression du POOL PHP existant : $POOL_PHP"
  sudo rm -f $POOL_PHP
else
  echo -e  "${blue} > Le domaine $DOMAIN ne possede aucun POOL PHP à supprimer${neutre}" 
fi


Info "Suppression de la configuration du site $vert$DOMAIN"
sudo rm -f "$NGINX_SITES_ENABLED/$DOMAIN.conf"
sudo rm -f "$NGINX_CONFIG/$DOMAIN.conf"

sudo userdel -rf "$USERNAME"
sudo delgroup "$USERNAME"

# Delete the virtual host config
Info "Suppression du domaine..."
sudo rm -f "$NGINX_SITES_ENABLED/$DOMAIN.conf"
sudo rm -f "$NGINX_CONFIG/$DOMAIN.conf"

sudo $NGINX_INIT restart

Info "le VHOST pour le domaine ${vert}$DOMAIN${info} a été SUPPRIME."
Info "Fin de script"
exit 0
