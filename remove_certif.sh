#!/bin/bash

# SUPPRESSION des certificats Let's Encrypt pour le domaine passé en paramètre
# ./remove_certif.sh sousdomaine.domaine.xxx


PATH_SCRIPT="$( cd "$( dirname "$0" )" && pwd )"
. "$PATH_SCRIPT/include/colors.sh"
. "$PATH_SCRIPT/include/myfuncs.sh"


Info "\n********************************************************"
Info "SUPPRESSION DES CERTIFICATS LETS ENCRYPT POUR UN DOMAINE"
Info "********************************************************\n"

Check_Root

#if [ -z ${1} ]; then
#  echo -e "\n< ERREUR > Aucun domaine n'a été transmis que la ligne de commande."
#  echo -e "\n ./remove_certif.sh sousdomaine.domaine.xxx"
#  exit 1
#fi


DOMAIN=$1
while [ -z $DOMAIN ]; do
  Question "Veuillez saisir le nom de domaine (en minuscule)${vertfonce}ou CTRL+C pour arrêter${question}) ?"
  read DOMAIN
done


echo -e "\nSuppression du certificat pour le domaine $DOMAIN, Tappez ENTREE pour continuer sinon CTRL+C pour abandonner"
read valeur

if [ -z "$DOMAIN" ]; then
  echo -e "\n< ERREUR > DOMAINE Vide arrêt du script."
  exit 999
fi

REP_CERTIF='live renewal archive'
for REP in $REP_CERTIF; do
  # Répertoire à supprimer
  SUP="/etc/letsencrypt/${REP}/${DOMAIN}/"
  exec_command "sudo rm -rf ${SUP}" "Suppression ${SUP}"
  if [ $? -ne 0 ]; then
    Erreur "Impossible de supprimer le répertoire ${SUP}"
  fi
done

Info "\n*** Fin de script***"
exit 0


