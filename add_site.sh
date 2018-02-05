#!/bin/bash
# ------------------------------------------------------------------------
# Debian 9
# Installation automatique d'un site sous nginx avec SSL et PHP
#
#
# author : Bernard Pardo
# Created : 02/01/2018
# Contact: bernard.pardo@gmail.com
# Site : https://tech.pardo.mobi
# ------------------------------------------------------------------------


# ================= PARAMETRES ===========================================

# ----- NGINX -----
SITES_AVAILABLE='/etc/nginx/sites-available'
SITES_ENABLED='/etc/nginx/sites-enabled'

GROUP_SERVER='www-data'
NGINX_INIT='/etc/init.d/nginx'

# ----- PHP -----
PHP_POOL_DIR='/etc/php/7.0/fpm/pool.d'
PHP_FPM_INIT='/etc/init.d/php7.0-fpm'

# ----- PORTS -----
HTTP_PORT=80
HTTPS_PORT=443



# ----- PHP -----

# Par défaut le script d'ajout de sites utilise le mode dynamic

# Mode 'static' MAX_CHILDS seront créés au démarrage
# Mode 'dynamic' les processus seront créés à la demande à concurrence de MAX_CHILDS
MAX_CHILDS=40

# Uniquement en mode 'dynamic'
# Nombre de processus crées au démarrage 
START_SERVERS=0


# Uniquement en mode 'dynamic'
# Nombre de processus idle
MIN_SPARE_SERVERS=1


# Uniquement en mode 'dynamic'
# Nombre maximum de processus en idle
MAX_SPARE_SERVERS=4


# ================= NE PAS TOUCHER CI-DESSOUS ============================

SCRIPT_VERSION=1.0

USERNAME=''
DOMAIN=''
USE_PHP=0

PATH_SCRIPT="$( cd "$( dirname "$0" )" && pwd )"
. "$PATH_SCRIPT/include/colors.sh"
. "$PATH_SCRIPT/include/myfuncs.sh"

# ----- BANNER 
echo -e "\n${grisclair}"
echo -e "#######################################"
echo -e "## INSTALLATION D'UN SITE sous NGINX ##"
echo -e "#######################################${neutre}\n"



function check_base_config() {

  # Verification si on est sur une distribution Debian
  #test $(lsb_release --id | awk '{ print " "$3 }') == 'Debian'
  #if [ $? -eq 1 ]; then
  #  Error "Le script ne peut pas être exécuté sur une distribution autre qu'une Debian"
  #  exit 999
  #fi



  Check_Root


  Info2 "Vérification des templates de configuration des domaines"
  list="html.vhost.template ssl.vhost.template ssl.vhost.php.template"
  for Template in $list; do
    if [ ! -f "$PATH_SCRIPT/templates/${Template}" ]; then
      Error "Le template de paramétrage du site : ${vertclair}$PATH_SCRIPT/templates/${Template}${error} est absent"
      exit 999
    fi
  done
  Info "OK"
}


function patch_template() {

    local CONFIG=$1
    local PHP=$2
    local DATE=$(date)


    # Patch d'un template NGINX | PHP
    # en valorisant les @@tokens@@ 



    $SED -i "s/@@SCRIPT_VERSION@@/$SCRIPT_VERSION/g" $CONFIG
    $SED -i "s/@@DATE@@/$(date)/g" $CONFIG


    Info "\nMAPPING VALEURS dans le fichier $vert$CONFIG$info pour $vert$DOMAIN\n"
    Info " @@HTTP_PORT@@ -> $HTTP_PORT"
    $SED -i "s/@@HTTP_PORT@@/$HTTP_PORT/g" $CONFIG

    Info " @@HTTPS_PORT@@ -> $HTTPS_PORT"
    $SED -i "s/@@HTTPS_PORT@@/$HTTPS_PORT/g" $CONFIG

    Info " @@DOMAIN@@ -> $DOMAIN"
    $SED -i "s/@@DOMAIN@@/$DOMAIN/g" $CONFIG

    Info " @@USERNAME@@ -> $USERNAME"
    $SED -i "s/@@USERNAME@@/$USERNAME/g" $CONFIG

    Info " @@HOME_DIR@@ -> $HOME_DIR"
    $SED -i "s/@@HOME_DIR@@/\/home\/$USERNAME\/$DOMAIN/g" $CONFIG

    Info " @@HOME_WWW@@ -> $HOME_WWW"
    $SED -i "s/@@HOME_WWW@@/\/home\/$USERNAME\/$DOMAIN\/www/g" $CONFIG

    Info " @@LOG_DIR@@ -> $HOME_DIR/_logs"
    # $SED -i -e "s/@@LOG_DIRECTORY@@/\/home\/$USERNAME\/$DOMAIN\/_logs/g" $CONFIG
    $SED -i "s/@@LOG_DIR@@/\/home\/$USERNAME\/$DOMAIN\/_logs/g" $CONFIG

    # PHP
    if [ $PHP -eq 1 ]; then
      Info " @@MAX_CHILDS@@ -> $MAX_CHILDS"
      $SED -i "s/@@MAX_CHILDS@@/$MAX_CHILDS/g" $CONFIG
      Info " @@START_SERVERS@@ -> $START_SERVERS"
      $SED -i "s/@@START_SERVERS@@/$START_SERVERS/g" $CONFIG
      Info " @@MIN_SPARE_SERVERS@@ -> $MIN_SPARE_SERVERS"
      $SED -i "s/@@MIN_SPARE_SERVERS@@/$MIN_SPARE_SERVERS/g" $CONFIG
      Info " @@MAX_SPARE_SERVERS@@ -> $MAX_SPARE_SERVERS"
      $SED -i "s/@@MAX_SPARE_SERVERS@@/$MAX_SPARE_SERVERS/g" $CONFIG
    fi

}



function create_user_and_directories() {
    adduser $USERNAME
    HOME_DIR="/home/$USERNAME/$DOMAIN"
    HOME_WWW="$HOME_DIR/www"
    # /home/$USERNAME/$DOMAIN/www
    Info "### Creation de l'environnement du site : ${vertfonce}${DOMAIN}${info} dans le répertoire : ${vertfonce}$HOME_DIR${info}"

    # ==================== CREATION DES REPERTOIRES ET ATTRIBUTION DES DROITS ====================
    sudo mkdir -p $HOME_WWW
    sudo chmod 750 $HOME_WWW -R

    # --- index.html / index.php
    if [ $USE_PHP -eq 1 ]; then 
      sudo cp $PATH_SCRIPT/templates/index.php $HOME_WWW/index.php
      sudo $SED -i "s/@@DOMAIN@@/$DOMAIN/g" $HOME_WWW/index.php

      # On rajoute aussi l'index HTML qui  est nécessaire pour tester sie le site 
      # est accessible avant de demander le certificat
      # ensuite il sera suppprimé apres l'installation du php
      sudo cp $PATH_SCRIPT/templates/index.html $HOME_WWW/index.html
      sudo $SED -i "s/@@DOMAIN@@/$DOMAIN/g" $HOME_WWW/index.html
    else
      sudo cp $PATH_SCRIPT/templates/index.html $HOME_WWW/index.html
      $SED -i "s/@@DOMAIN@@/$DOMAIN/g" $HOME_WWW/index.html
    fi

    Info "  # Création du répertoire des logs :$HOME_DIR/_logs"
    sudo mkdir -p $HOME_DIR/_logs
    sudo chmod 770 $HOME_DIR/_logs

    Info "  # Création du répertoire des sessions :$HOME_DIR/_sessions"
    sudo mkdir -p $HOME_DIR/_sessions
    sudo chmod 700 $HOME_DIR/_sessions

    Info "  # Création du répertoire secure :$HOME_DIR/_secure"
    sudo mkdir -p $HOME_DIR/_secure
    sudo chmod 700 $HOME_DIR/_secure

    Info "  # Création du répertoire backups :$HOME_DIR/_backups"
    sudo mkdir -p $HOME_DIR/_backups
    sudo chmod 700 $HOME_DIR/_backups

    Info "  # Affectation des droits user:group $USERNAME:$USERNAME au répertoire /home/$USERNAME"
    sudo chown $USERNAME:$USERNAME /home/$USERNAME/ -R

    Info " ### Création des répertoires de base terminé OK"
}


# ======================== STARTING SCRIPT =======================================================

check_base_config

SED=`which sed`

DOMAIN=''
while [ -z $DOMAIN ]; do
  Question "Veuillez saisir un nom de domaine (en minuscule) (${vertfonce}ou CTRL+C pour arrêter${question}) ?"
  read DOMAIN
done

Info2 "Vérification de la validité du nom de domaine"

PATTERN="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$";
if [[ "$DOMAIN" =~ $PATTERN ]]; then
    DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
    Info "OK"
    Info "Création de l'hébergement pour le domaine : ${DOMAIN}"
else
    Error "Le nom de domaine ${DOMAIN} est invalide."
    exit 999
fi

USERNAME=''
# Selection d'un nouvel utilisateur pour le domaine
while [ -z $USERNAME ]; do
    Question "Spécifiez un nom d'utilisateur (en minuscule) pour l'administration du site ? :"
    read USERNAME
done


valid_input "Souhaitez-vous installer PHP pour ce site? " "o/n"
if [ "$Return_Val" = "o" ];
then
  USE_PHP=1
else
  USE_PHP=0
fi



Info "========================================"
Info "RECAPITULATIF"
Info "Site : $DOMAIN"
Info "User : $USERNAME"
Info "PHP : $USE_PHP"
Info "========================================"

valid_input "Souhaitez-vous continuer avec ces paramètres ? " "o/n"
if [ "$Return_Val" = "n" ];
then
  exit 1
fi

create_user_and_directories

# On recopie le template -> /etc/nginx/sites-available ($SITES_AVAILABLES) -> /etc/nginx/sites-enables ($SITES_ENABLED)
# /etc/nginx/sites-available/site_url.conf

CONFIG_SITE=$SITES_AVAILABLE/$DOMAIN.conf
sudo cp $PATH_SCRIPT/templates/html.vhost.template $CONFIG_SITE

patch_template $CONFIG_SITE 0

# ----- Username dans le groupe www-data
sudo usermod -aG $USERNAME $GROUP_SERVER
sudo chmod g+rx $HOME_WWW
sudo chmod 600 $CONFIG_SITE

# ----- Création du lien symbolique dans /etc/nginx/sites-enabled ($SITES_ENABLED)
sudo ln -s $CONFIG_SITE $SITES_ENABLED/$DOMAIN.conf

Info "\nVérification du paramétrage du serveur nginx"
sudo $NGINX_INIT configtest
if [ "$?" -ne 0 ]; then
  Error "La configuration des hôtes nginx n'est pas correcte."
  exit 999
fi

Info "\nRédémarrage de nginx avec le nouveau paramétrage du site ${DOMAIN}\n"
sudo $NGINX_INIT reload

Info "\n*** Le site pour le domaine ${vertfonce}${DOMAIN}${info} a bien été crée ***\n"
Info "\nVous pouvez le tester à cette adresse http://${DOMAIN}"
#Info "\nTappez ENTREE pour générer le certificat SSL du domaine ${DOMAIN} sinon (CTRL+C)"
#read wait

Info "*** GENERATION DU CERTIFICAT SSL POUR LE SITE ${vertfonce}$DOMAIN${info} *** \n"

sudo /opt/letsencrypt/letsencrypt-auto certonly --rsa-key-size 4096 --webroot --webroot-path $HOME_WWW -d $DOMAIN

##### ICI LE CERTIFICAT POUR LE DOMAINE EST INSTALLE

CONFIG_SITE=$SITES_AVAILABLE/$DOMAIN.conf


if [ $USE_PHP -eq 0 ]; then
  # Configuration SANS PHP
  Info "Copie du template $PATH_SCRIPT/templates/ssl.vhost.template -> $CONFIG_SITE"
  sudo cp $PATH_SCRIPT/templates/ssl.vhost.template $CONFIG_SITE
else
  # Configuration AVEC PHP
  Info "Copie du template : $PATH_SCRIPT/templates/ssl.vhost.php.template -> $CONFIG_SITE"
  sudo cp $PATH_SCRIPT/templates/ssl.vhost.php.template $CONFIG_SITE

  # On n'a plus besoin de index.html on peut le supprimer 
  sudo rm -f $HOME_WWW/index.html
fi

patch_template $CONFIG_SITE 0

##### PARAMETRAGE DU POOL PHP
if [ $USE_PHP -eq 1 ]; then 
  CONFIG_POOL_PHP=$PHP_POOL_DIR/$USERNAME.conf
  Info "Configuration du POOL PHP ( $CONFIG_POOL_PHP )"
  Info "Copy du template : $PATH_SCRIPT/templates/pool.conf.template -> $CONFIG_POOL_PHP"
  sudo cp $PATH_SCRIPT/templates/pool.conf.template $CONFIG_POOL_PHP
  patch_template $CONFIG_POOL_PHP 1
fi


exec_command "sudo $PHP_FPM_INIT restart" "Redémarrage des POOLS PHP"

Info "\nVérification du paramétrage du serveur nginx pour le site SSL"

$NGINX_INIT configtest
if [ "$?" -ne 0 ]; then
  Error "Le paramétrage des VHOSTS nginx est incorrect, merci de vérifier le dernier crée : /etc/nginx/sites-available/$DOMAIN.conf"
  exit 999
fi

exec_command "sudo $NGINX_INIT reload" "Redémarrage de nginx"

Info "*** FIN DE CREATION DU DOMAINE $DOMAIN ***"
