# HEIGVD - Sécurité des Réseaux - 2023

# Laboratoire n°5 - VPN

Ce travail est à réaliser en équipes de deux personnes.
Choisissez une personne avec qui vous n'avez pas encore travaillé pour un labo du cours SRX.
C'est le **troisième travail noté** du cours SRX.

Répondez aux questions en modifiant directement votre clone du README.md.

Le rendu consiste simplement à compléter toutes les parties marquées avec la mention "LIVRABLE".
Le rendu doit se faire par un `git commit` sur la branche `main`.

## Table de matières

- [Introduction](#introduction)
  - [Échéance](#échéance)
  - [Évaluation](#évaluation)
  - [Introduction](#introduction)
  - [Configuration](#configuration)
  - [Test](#test)
- [OpenVPN](#openvpn)
  - [Mise en place du CA](#mise-en-place-du-ca)
  - [Réseau à réseau](#réseau-à-réseau)
  - [Remote à réseau](#remote-à-réseau)
  - [Desktop à réseau](#desktop-à-réseau)
- [WireGuard](#wireguard)
  - [Création des clés](#création-des-clés)
  - [Réseau à réseau](#réseau-à-réseau-1)
  - [Remote à réseau](#remote-à-réseau-1)
  - [Bonus - Desktop à réseau](#bonus--desktop-à-réseau)
- [IPSec](#ipsec)
  - [Mise en place du CA](#mise-en-place-du-ca-1)
  - [Réseau à réseau](#réseau-à-réseau-2)
  - [Remote à réseau](#remote-à-réseau-2)
- [Comparaison](#comparaison)
  - [Sécurité](#sécurité)
  - [Facilité d'utilisation](#facilité-dutilisation)
  - [Performances](#performance)
- [Points spécifiques](#points-spécifiques)
  - [OpenVPN](#openvpn-1)
  - [WireGuard](#wireguard-1)
  - [IPSec](#ipsec-1)

# Introduction

## Échéance

Ce travail devra être rendu au plus tard, **le 14 mai 2023 à 23h59.**

## Évaluation

Vous trouverez le nombre de points pour chaque question derrière le numéro de la question:

**Question 1 (2):**

Désigne la 1ère question, qui donne 2 points.
La note finale est calculée linéairement entre 1 et 6 sur le nombre de points totaux.
Les pénalités suivantes sont appliquées:

- 1/2 note pour chaque tranche de 24h de retard

À la fin du document, vous trouverez une liste de points supplémentaires qui se feront sur la base de votre
code rendu.

## Introduction

Ce labo va vous présenter trois types de VPNs: OpenVPN, WireGuard et IPSec.
On va voir au cours une partie de la configuration, pour le reste, vous devez faire
vos propres recherches sur internet.
La quatrième partie vous demande de faire une comparaison des différents VPNs vu dans ce labo.

Les trois VPNs vont être fait avec deux connexions différentes:

- une pour connecter deux réseaux distants
- une pour connecter un ordinateur pour faire partie du réseau `main`
  Pour OpenVPN, vous devez aussi connecter votre ordinateur hôte au réseau docker.

Il y a trois réseaux:

- 10.0.0.0/24 - fait office d'internet - toutes les adresses "publiques" seront dans cette plage.
  L'ordinateur distant a l'adresse publique 10.0.0.4
- 10.0.1.0/24 - le réseau `main` avec le serveur VPN, adresse publique de 10.0.0.2
- 10.0.2.0/24 - le réseau `far` qui sera à connecter au réseau `main`, adresse publique de 10.0.0.3

Pour les deux réseaux, on aura chaque fois trois machines:

- serveur: avec le host-IP = 2 et l'adresse publique correspondante
- client1: avec le host-IP = 10
- client2: avec le host-IP = 11
  Les deux serveurs vont faire un routing des paquets avec un simple NAT.
  Docker ajoute une adresse avec le host-IP de 1 qui est utilisée pour router le trafic vers l'internet.

Une fois la connexion VPN établie, vous devrez vous assurer que:

- toutes les machines connectées peuvent échanger des paquets entre eux
- tous les paquets entre les réseaux et l'ordinateur distant doivent passer par le VPN.
  Vous pouvez utiliser le script décrit dans [Test](#test) pour cela.

## Configuration

Vu que vous devez faire trois configurations qui se basent sur les mêmes images docker,
j'ai ajouté une configuration automatique.
Ceci vous permet de travailler sur les trois configurations, OpenVPN, WireGuard, et IPSec,
et de pouvoir aller de l'une à l'autre.

D'abord il y a le fichier [routing.sh](root/routing.sh) qui fait le routage pour les serveurs
et les clients.
Ce script est copié dans l'image docker et il est exécuté au démarrage.
Ainsi les clients vont envoyer tous leurs paquets vers le serveur et le serveur va faire du
NAT avant d'envoyer les paquets vers l'internet/intranet.
Ceci est nécessaire parce que par défaut docker ajoute une passerelle avec le host-id `1`,
et sans ce changement dans le routage, connecter les serveurs en VPN ne ferait rien pour
les clients.

Après il y a un répertoire pour chaque serveur et pour la machine distante qui se trouve dans les
répertoires suivants.
Chaque répertoire est monté en tant que `/root` dans la machine correspondante.

- [main](root/main) pour le serveur `MainS`
- [far](root/far) pour le serveur `FarS`
- [remote](root/remote) pour l'ordinateur `Remote`
  Le répertoire [host](root/host) sert à ajouter la configuration depuis votre machine hôte pour
  se connecter au VPN.

Ceci vous permet deux choses:

- éditer les fichiers dans ces répertoires directement sur votre machine hôte et les utiliser dans les machines docker
- lancer le `docker-compose` en indiquant quel fichier il faut exécuter après le démarrage:

```
RUN=openvpn.sh docker-compose up
```

Ceci va exécuter le fichier `openvpn.sh` sur les deux serveurs et la machine distante.
Tous les fichiers supplémentaires sont à mettre dans un sous-répertoire.

Ça sera à vous d'ajouter les fichiers nécessaires pour les autres VPNs.
Appelez-les `wireguard.sh` pour le wireguard, et `ipsec.sh` pour l'IPSec.

## Test

Une fois que vous avez terminé avec une implémentation de VPN, vous pouvez la tester avec
la commande suivante:

```
./test/runit.sh openvpn
```

Vous pouvez remplacer `openvpn` avec `wireguard` et `ipsec`.

Chaque fois que vous faites un `git push` sur github, il y a un `git workflow` qui vérifie si
les VPNs se font de façon juste.

# OpenVPN

[OpenVPN](https://openvpn.net/community-resources/how-to) est un VPN basé sur des connexions
SSL/TLS.
Il n'est pas compatible avec les autres VPNs comme WireGuard ou IPSec.
Des implémentations pour Linux, Windows, et Mac existent.
La configuration de base, et celle qu'on retient ici, est basé sur un système de certificats.
Le serveur et les clients se font mutuellement confiance si le certificat de la station distante
est signé par le certificat racine, vérifié avec la clé publique qui est disponible sur chaque machine.

---

**Question 1 (1): route par défaut**

Quelle est l'avantage d'utiliser le routage par défaut pour le OpenVPN?
A quoi est-ce qu'il faut faire attention si on utilise cette méthode sur un client?

---

**Réponse**

---

## Mise en place du CA

---

**Question 2 (2) : Avantages du CA**

Décrivez deux avantages d'un système basé sur les Certificate Authority dans le cadre de
l'authentification des machines.

---

**Réponse**

---

**Question 3 (2) : commandes utilisées**

Quelles commandes avez-vous utilisées pour mettre en place le CA et les clés des clients?
Décrivez les commandes et les arguments et à quoi ils servent.

---

**Réponse**

---

**Question bonus 4 (2) : création de clés sécurisée**

Quel est une erreur courante dans la création de ces clés comme décrite dans le HOWTO d'OpenVPN?
Comment est-ce qu'on peut éviter cette erreur?

---

**Réponse**

---

## Réseau à réseau

Pour commencer, vous allez connecter les réseaux `main` et `far`.
Utilisez seulement le fichier de configuration OpenVPN, sans ajouter des `ip route`
ou des règles `nftable`.
Chaque machine de chaque réseau doit être capable de contacter chaque autre machine de chaque
réseau avec un `ping`.

---

**Question 5 (2) : routage avec OpenVPN**

Décrivez les lignes de votre fichier de configuration qui font fonctionner le routage entre
les deux réseaux.
Pour chaque ligne, expliquez ce que cette ligne fait.

---

**Réponse**

---

## Remote à réseau

Maintenant, vous allez faire une connexion avec la station distante `Remote` et la machine `MainS`.
Vérifiez que la machine `Remote` peut atteindre toutes les machines dans les deux réseaux `main` et `far`.
Comme pour l'exercice précédent, n'utilisez pas des `ip route` supplémentaires ou des commandes `nftable`.

Une fois que tout est bien mise en place, faites de sorte que la configuration est chargée automatiquement
à travers des scripts `openvpn.sh` pour chaque hôte.
À la fin, la commande suivante doit retourner avec succès:

```
./test/runit.sh openvpn
```

## Desktop à réseau

Utiliser l'application [OpenVPN Connect Client](https://openvpn.net/vpn-client/) sur votre hôte pour vous
connecter au réseau docker.
Mettez la configuration nécessaire quelque part dans le répertoire `root/host`.
L'assistant va tester si cette configuration marche, en faisant un `ping` sur toutes les machines du réseau docker.

---

**Question 6 (1) : integration des clés dans le fichier de configuration**

Comment avez-vous fait pour faire un seul fichier de configuration pour OpenVPN?

---

**Réponse**

---

# WireGuard

Pour [WireGuard](https://www.wireguard.com/quickstart/) la partie `Desktop à réseau` est une partie
bonus qu'il ne faut pas faire absolument.
Vous allez configurer WireGuard avec des clés statiques, tout en décrivant comment éviter que les
clés privées se trouvent sur plus d'une seule machine.
Utilisez le port `51820` pour les connexions, car c'est celui qui est aussi ouvert avec le `docker-compose.yaml`.

## Création des clés

D'abord il faut commencer à créer des clés statiques pour les différentes machines.
Utilisez la commande `wg` pour ceci et stockez les clés quelque part dans les répertoires `root`,
pour que vous puissiez les retrouver facilement après.

---

**Question 7 (2) : Sécuriser la création des clés**

A quoi est-ce qu'il faut faire attention pendant la création des clés pour garantir une
sécurité maximale?
Un point est indiqué par la commande `wg` quand vous créez les clés privées.
L'autre point a déjà été discuté plusieurs fois au cours par rapport à la création et
la distribution des clés privées.

---

**Réponse:**

---

## Réseau à réseau

Comme pour l'OpenVPN, commencez par connecter les deux machines `MainS` et `FarS` ensemble.
Il n'est pas nécessaire de changer le script `routing.sh` ou d'ajouter d'autres règles au
pare-feu.
Vous pouvez faire toute la configuration avec les fichiers de configuration pour la commande
`wg-quick`.
Appelez les fichiers de configuration `wg0.conf`.
A la fin, assurez-vous que vous pouvez faire un `ping` entre toutes les machines du réseau `Main` et
le réseau `Far`.

---

**Question 8 (2) : sécurité du fichier `wg0.conf`**

Si vous créez votre fichier `wg0.conf` sur votre système hôte avec les permissions
normales, qu'est-ce qui va s'afficher au lancement de WireGuard?
Pourquoi c'est un problème?
Et avec quelle commande est-ce qu'on peut réparer ceci?

---

**Réponse**

---

## Remote à réseau

Maintenant faites la configuration pour la machine `Remote`.
Il faut qu'elle puisse contacter toutes les autres machines des réseaux `Main` et `Far`.

---

**Question 9 (1): tableau de routage sur `MainS`**

Ajoutez ici une copie du tableau de routage de `MainS` une fois les connexions avec
`FarS` et `Remote` sont établies.

---

**Réponse**

---

**Question 10 (3): passage des paquets**

Décrivez par quelles interfaces un paquet passe quand on fait un `ping 10.0.2.10` sur la machine `Remote`.
Pour chaque passage à une nouvelle interface, indiquez la machine, l'interface, et si le paquet va être
transféré d'une façon chiffrée ou pas.
Décrivez le chemin aller du `echo request` et le chemin retour du `echo reply`.

---

**Réponse**

---

Comme pour OpenVPN, assurez-vous que tout le démarrage de la configuration soit dans les scripts
`wireguard.sh` pour les différentes machines.
Quand tout est fait, la commande suivante doit retourner avec succès:

```
./test/runit.sh wireguard
```

## Bonus: Desktop à réseau

Je n'ai pas réussi à connecter le desktop hôte sur le réseau docker avec WireGuard.
Donc si vous réussissez à vous connecter avec [WireGuard Client](https://www.wireguard.com/install/)
depuis votre machine hôte à vos dockers et faire des pings sur les différents réseaux, c'est un bonus!
Mettez le fichier de configuration quelque part dans le répertoire `root/host`. 

# IPSec

Ici, vous allez utiliser l'implémentation de [StrongSwan](https://docs.strongswan.org/docs/5.9/config/quickstart.html)
pour mettre en place un VPN entre les différentes machines.
Comme OpenVPN, StrongSwan se base sur des certificats pour l'autorisation des connexions.
Par contre, il ne va pas utiliser le TLS pour la connexion, mais d'autres protocols.

Pour lancer StrongSwan, vous devez d'abord lancer le daemon `charon` avec la commande suivante:

```
/usr/lib/ipsec/charon &
```

Contrairement à OpenVPN et WireGuard, il est plus difficile de configurer StrongSwan avec un répertoire différent.
Il faut donc que votre script `ipsec.sh` copie les fichiers depuis le répertoire `/root` dans les endroits
appropriés.
Assurez-vous que seulement les fichiers nécessaires sont copiés!

## Mise en place du CA

Utilisez les commandes décrites dans la documentation de StrongSwan pour mettre en place une CA auto-signé.
Ceci veut dire que vous ne vous reposez pas sur une autorité reconnue mondialement, mais sur une clé
créée par vous-mêmes.
Comme ça vous devriez copier la partie publique de cette clé sur toutes les autres machines, afin que celles-ci
puissent vérifier que les certificats proposés sont valides.

Le certificat inclut aussi une description des machines.
Regardez quels sont les informations correctes à y mettre.
Vous pouvez bien sûr inventer une entreprise et un nom de domaine à votre idée.

Gardez les clés quelque part dans l'arborescence `root` de votre projet.
Assurez-vous que les clés sont seulement disponibles sur les machines qui en ont besoin. 

---

**Question 11 (2): commandes pour création de clés**

- 1 - Quelles sont les commandes que vous avez utilisées pour créer le CA et les clés pour les machines?
- 1 - Si vous avez écrit un script pour créer les clés, copiez-le dans votre répertoire et indiquez le chemin ici.

---

**Réponse**

---

**Question 12 (3) : création de clés hôtes sécurisée**

Dans la documentation de StrongSwan il y a une description pour éviter que la personne qui a créé le
CA de racine voie les clés privées des hôtes.
Supposant qu'il y a deux entités, le `CA holder` et le `host`, décrivez chronologiquement qui crée quelle
clé à quel moment, et quelles sont les fichiers échangés.
Laissez ces fichiers dans les sous-répertoires correspondants, même si vous en avez plus besoin.

---

**Réponse**

---

## Réseau à réseau

Maintenant, vous êtes prêt·e·s pour configurer StrongSwan pour connecter les réseaux `Main` et `Far`.
Faites attention, parce que StrongSwan va seulement créer la connexion une fois un paquet le requiert.
En mettant en place la connexion, `charon` va journaliser ses efforts dans le terminal.
Regardez bien ce journal si quelque chose ne marche pas.

Comme décrit dans l'introduction pour IPSec, il faut stocker les fichiers nécessaires dans le répertoire `root`, puis
les copier dans l'arborescence pour que StrongSwan puisse les trouver.

---

**Question 13 (2) : fichiers et leur utilité**

Pour les hôtes `MainS` et `FarS`, décrivez pour chaque fichier que vous copiez la destination et l'utilité de
ce fichier.

---

**Réponse**

---

## Remote à Réseau

La prochaine étape est de connecter un seul hôte à `MainS`.
Ce hôte doit être capable de contacter autant le réseau `main` que le réseau `far`.
Bien sûr que ça requiert que l'IPSec entre `main` et `far` est actif.
Cherchez dans la documentation StrongSwan à quelle configuration ceci correspond et ajoutez-la à votre
configuration existante.

---

**Question 14 (1) : fichiers et leur utilité**

Comme pour l'exercice _Réseau à réseau_, les fichiers doivent être dans le répertoire `root`, mais
StrongSwan en a besoin dans d'autres répertoires.
Pour l'hôte `Remote`, décrivez pour chaque fichier que vous copiez la destination et l'utilité de
ce fichier.
Indiquez aussi quel(s) fichier(s) vous avez dû ajouter à `MainS`.

---

**Réponse**

---

# Comparaison

Maintenant, vous allez devoir comparer les différents protocols entre eux.
Pour chaque question, assurez-vous de bien donner des explications complètes,
sauf si la question vous demande de donner qu'une courte réponse.

## Sécurité

---

**Question 15 (2) : Sécurité de la communication**

Décrivez la sécurité maximale disponible pour chaque protocol une fois la connexion établie.
Pour chacune de votre configuration retenue dans ce labo, décrivez quels sont les algorithmes
utilisés pour sécuriser la connexion.

---

**Réponse:**

- OpenVPN:
- WireGuard:
- IPSec:

---

**Question 16 (2) : Sécurité de l'authentification**

Décrivez la sécurité de l'authentification que nous avons choisi pour les différents
exercices.
Regardez aussi les certificats et l'algorithme de signature utilisé et commentez si c'est un algorithme
sécure ou pas.

---

**Réponse:**

- OpenVPN:
- WireGuard:
- IPSec:

---

## Facilité d'utilisation

---

**Question 17 (1) : Facilité de la configuration serveur**

Quelle est la complexité de mettre en place un serveur pour les deux cas demandés
dans les exercices?
Trier votre réponse pour que la solution VPN la plus facile soit au début et que la difficulté augmente avec chaque
entrée.

---

**Réponse:**

- OpenVPN:
- WireGuard:
- IPSec:

---

**Question 18 (1) : Facilité de la configuration client desktop**

Quelle est la complexité de mettre en place un client desktop pour les deux cas demandés
dans les exercices?

---

**Réponse:**

- OpenVPN:
- WireGuard:
- IPSec:

---

## Performance

---

**Question 19 (2) : Plus vite au plus lent**

Trie les trois configurations que nous avons vues dans l'ordre décroissant
de leur vitesse mesuré avec `iperf`.
Pour chaque protocol, indique les trois vitesses suivantes:
- entre le `MainS` et le `FarS`
- entre `MainC1` et `FarC1` 
- entre `Remote` et `FarC2`
Si un des protocols est beaucoup plus rapide que les autres, décrivez pourquoi c'est le cas.

---

**Réponse:**

- OpenVPN:
- WireGuard:
- IPSec:

---

# Points spécifiques

Voici quelques points supplémentaires qui seront évalués, avec leurs points:

- 20 (2) - organisation des fichiers dans le répertoire `root`
- 21 (3) - acceptation du labo par le script `test/runit.sh`
- 22 (2) - bonne utilisation des scripts

## OpenVPN

- 23 (2) - est-ce que la configuration dans `root/far/openvpn/client.ovpn` marche pour une connexion depuis l'ordinateur
  hôte et toutes les machines sont atteignables depuis l'hôte

## WireGuard

- 24 (3) bonus - connexion avec la configuration dans `root/far/wireguard/client.conf` depuis l'ordinateur
  hôte et toutes les machines sont atteignables depuis l'hôte

## IPSec

- 25 (1) - pas de clés supplémentaires pour le IPSec dans les autres machines
- 26 (1) - présence des fichiers utilisés pour la mise en place des clés pour IPSec

