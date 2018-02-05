### Commandes pour la création d'un site 
**Création d'un site avec PHP et TLS **
```
sudo bash add_site.sh
```

### Commande pour la suppression d'un site précédement crée par les scripts de création de site
Note : **Attention le repertoire home de utilisateur associé au site sera supprimé**, il contient entre autre le site, les logs, **Pensez à faire des sauvegardes avant.**
```
sudo bash remove_site.sh sousdomaine.domaine.xxx user
```

**Suppression du certificat d'un site**

Note : Le script de suppression de site *remove_site.sh* ne supprime pas les certificats TLS créé pour le domaine (au cas où l'on souhaiterais réinstaller ultérieurement le domaine). 
```
sudo bash remove_certif.sh sousdomaine.domaine.xxx
```
