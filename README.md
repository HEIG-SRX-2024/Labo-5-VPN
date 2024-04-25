# HEIGVD - Sécurité des Réseaux - 2024

# Laboratoire n°5 - VPN

Ce travail est à réaliser en équipes de deux personnes.
Choisissez une personne avec qui vous n'avez pas encore travaillé pour un labo du cours SRX.
C'est le **troisième travail noté** du cours SRX.

Répondez aux questions en modifiant directement votre clone du README.md.

Le rendu consiste simplement à compléter toutes les parties marquées avec la mention "LIVRABLE".
Le rendu doit se faire par un `git commit` sur la branche `main`.

## Table de matières

- [HEIGVD - Sécurité des Réseaux - 2024](#heigvd---sécurité-des-réseaux---2024)
- [Laboratoire n°5 - VPN](#laboratoire-n5---vpn)
  - [Table de matières](#table-de-matières)
- [Introduction](#introduction)
  - [Échéance](#échéance)
  - [Évaluation](#évaluation)
  - [Introduction](#introduction-1)
  - [Configuration](#configuration)
  - [Test](#test)
- [OpenVPN](#openvpn)
  - [Mise en place du CA](#mise-en-place-du-ca)
  - [Réseau à réseau](#réseau-à-réseau)
  - [Remote à réseau](#remote-à-réseau)
  - [Tests](#tests)
  - [Desktop à réseau](#desktop-à-réseau)
- [WireGuard](#wireguard)
  - [Création des clés](#création-des-clés)
  - [Réseau à réseau](#réseau-à-réseau-1)
  - [Remote à réseau](#remote-à-réseau-1)
  - [Test](#test-1)
  - [Bonus: Desktop à réseau](#bonus-desktop-à-réseau)
- [IPSec](#ipsec)
  - [Mise en place du CA](#mise-en-place-du-ca-1)
  - [Réseau à réseau](#réseau-à-réseau-2)
  - [Remote à Réseau](#remote-à-réseau-2)
  - [Test](#test-2)
- [Comparaison](#comparaison)
  - [Sécurité](#sécurité)
  - [Facilité d'utilisation](#facilité-dutilisation)
  - [Performance](#performance)
- [Points spécifiques](#points-spécifiques)
  - [OpenVPN](#openvpn-1)
  - [WireGuard](#wireguard-1)
  - [IPSec](#ipsec-1)

# Introduction

## Échéance

Ce travail devra être rendu au plus tard, **le 29 mai 2024 à 23h59.**

## Évaluation

Vous trouverez le nombre de points pour chaque question derrière le numéro de la question:

**Question 1 (2):**

Désigne la 1ère question, qui donne 2 points.
La note finale est calculée linéairement entre 1 et 6 sur le nombre de points totaux.
Les pénalités suivantes sont appliquées:

- 1/2 note pour chaque tranche de 24h de retard

À la fin du document, vous trouverez **une liste de points supplémentaires qui seront évalués** sur la base de votre
code rendu.

## Introduction

Ce labo va vous présenter trois types de VPNs: OpenVPN, WireGuard et IPSec.
On va voir au cours une partie de la configuration, pour le reste, vous devez faire
vos propres recherches sur internet.
La quatrième partie vous demande de faire une comparaison des différents VPNs vu dans ce labo.

Les trois VPNs vont être fait avec deux connexions différentes:

- une pour connecter deux réseaux distants, `main` et `far`
- une pour connecter un ordinateur `remote` pour faire partie du réseau `main`

Pour OpenVPN, vous devez aussi connecter votre ordinateur hôte au réseau docker.

Il y a trois réseaux:

- 10.0.0.0/24 - fait office d'internet - toutes les adresses "publiques" des passerelles de
  `main` et `far`, ainsi que le `remote` seront dans cette plage.
  L'ordinateur distant a l'adresse publique 10.0.0.4
- 10.0.1.0/24 - le réseau `main` avec le serveur VPN, adresse publique de 10.0.0.2
- 10.0.2.0/24 - le réseau `far` qui sera à connecter au réseau `main`, adresse publique de 10.0.0.3

Pour les deux réseaux, on aura chaque fois trois machines:

- serveur: avec le host-IP = 2 et une adresse publique correspondante
- client1: avec le host-IP = 10
- client2: avec le host-IP = 11

![Network Diagram](network.svg)

Les deux serveurs vont faire un routing des paquets avec un simple NAT.
Docker ajoute une adresse avec le host-IP de 1 qui est utilisée pour router le trafic vers l'internet.

Une fois la connexion VPN établie, vous devrez vous assurer que:

- toutes les machines connectées peuvent échanger des paquets entre eux
- tous les paquets entre les réseaux et l'ordinateur distant passent par le VPN.

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

Après vous devez ajouter les fichiers nécessaires pour les autres VPNs.
Appelez-les `wireguard.sh` pour le wireguard, et `ipsec.sh` pour l'IPSec.
L'arborescence finale devrait se présenter comme ça:

```
+root+
     + main + openvpn.sh
     I      + openvpn + fichier 1
     I      I         + fichier 2
     I      + wireguard.sh
     I      + wireguard + fichier 1
     I      I           + fichier 2
     I      + ipsec.sh
     I      + ipsec + fichier 1
     I              + fichier 2
     + far + openvpn.sh
     I     + openvpn + fichier 1
     I     I         + fichier 2
     I     + wireguard.sh
     I     + wireguard + fichier 1
     I     I           + fichier 2
     I     + ipsec.sh
     I     + ipsec + fichier 1
     I             + fichier 2
     + wireguard + openvpn.sh
                 + openvpn + fichier 1
                 I         + fichier 2
                 + wireguard.sh
                 + wireguard + fichier 1
                 I           + fichier 2
                 + ipsec.sh
                 + ipsec + fichier 1
                         + fichier 2
```

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

**Question 1.1 (3): route par défaut**

a) Pourquoi veut on faire un routage par défaut qui passe à travers le VPN?

b) Cherchez sur internet une faille souvent rencontrée quand un fait un routage par défault à travers le VPN?

c) Donnez un cas où le routage par défaut à travers le VPN n'est pas indiqué: host-host, remote-access, site-site? Et pourquoi?

---

**Réponse**

---

## Mise en place du CA

Comme décrit dans le cours, on va commencer par installer une CA sur le serveur `MainS`
et puis copier les certificats sur `FarS` et `Remote`.
Vous pouvez choisir comment vous faites, mais décrivez les avantages / désavantages de
ce que vous avez fait dans les questions 3 et 4.

1. Créer toutes les clés sur le serveur `MainS`
2. Créer une PKI sur chaque serveur et le `Remote`, puis de copier seulement les
   requests.

Le paquet `easy-rsa` est déjà installé sur le système.
Vous pouvez trouver les fichiers avec `dpkg -L easy-rsa`, ce qui vous montrera où est
la commande nécessaire pour créer le PKI.
Prenez la description pour la version 3 de `easy-rsa` dans le 
[Quickstart README](https://github.com/OpenVPN/easy-rsa/blob/master/README.quickstart.md).

---

**Question 1.2 (2) : Avantages du CA**

Décrivez deux avantages d'un système basé sur les Certificate Authority dans le cadre de
l'authentification des machines.
Réfléchissez par rapport à l'ajout des nouvelles machines.

---

**Réponse**

---

**Question 1.3 (2) : commandes utilisées**

Quelles commandes avez-vous utilisées pour mettre en place le CA et les clés des clients?
Donnez les commandes et décrivez à quoi servent les arguments.

---

**Réponse**

---

**Question bonus 1.4 (2) : création de clés sécurisées**

Quel est une erreur courante lors de la création de ces clés, comme décrite dans le HOWTO d'OpenVPN?
Comment est-ce qu'on peut éviter cette erreur?
Réfléchissez par rapport à la sécurité: qui pourrait abuser des clés et dans quel but?

---

**Réponse**

---

## Réseau à réseau

Pour commencer, vous allez connecter les réseaux `main` et `far`.
Utilisez seulement le fichier de configuration OpenVPN, sans ajouter des `ip route`
ou des règles `nftable`.
Chaque machine de chaque réseau doit être capable de contacter chaque autre machine de chaque
réseau avec un `ping`.
Tout le traffic entre les passerelles de `main` et `far` doit passer par le VPN.

Vous trouvez des exemples de configuration sur 
[OpenVPN example files](https://openvpn.net/community-resources/how-to/#examples).

---

**Question 1.5 (2) : routage avec OpenVPN**

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
Vous trouvez une description de la configuration à faire ici:
[Including Multiple Machines](https://openvpn.net/community-resources/how-to/#including-multiple-machines-on-the-server-side-when-using-a-routed-vpn-dev-tun).


---

**Question 1.6 (2) : configuration remote**

Décrivez les lignes de votre fichier sur le container `remote` qui font fonctionner le routage entre
remote et les deux réseaux.
Pour chaque ligne, expliquez ce que cette ligne fait.

---

**Réponse**

---

## Tests

Une fois que tout est bien mise en place, faites de sorte que la configuration est chargée automatiquement
à travers des scripts `openvpn.sh` pour chaque hôte.
À la fin, la commande suivante doit retourner avec succès:

```
./test/runit.sh openvpn
```

Faites un commit, puis un `git push`, et vérifiez si les tests pour openvpn passent sur
github.

## Desktop à réseau

Utiliser l'application [OpenVPN Connect Client](https://openvpn.net/vpn-client/) sur votre hôte pour vous
connecter au réseau docker.
Mettez la configuration nécessaire quelque part dans le répertoire `root/host`.
L'assistant va tester si cette configuration marche, en faisant un `ping` sur toutes les machines du réseau docker.

---

**Question 1.7 (1) : integration des clés dans le fichier de configuration**

Comment avez-vous fait pour faire un seul fichier de configuration pour OpenVPN?

---

**Réponse**

---

**Question bonus 1.8 (1) : manque de fichiers de configuration example openvpn**

Cette question est uniquement pour les férus de systèmes Debian / Ubuntu.
J'ai cherché moi-même un bon moment sans rien trouver.
Même ChatGPT / Gemini / Claude ne pouvaient pas m'aider.
Donc 1 point bonus pour celui / celle qui peut m'expliquer pourquoi
`dpkg -L openvpn` montre qu'il y a des paquets de configuration exemple,
mais qu'on ne les trouve pas sur le système sous `/usr/share/doc/openvpn`.
En téléchargeant le paquet deb on retrouve les fichiers dans le `data.tar.zst`,
mais pour une raison qui m'échappe, ces fichiers ne sont pas installé, ou ils
sont effacées.

---

**Réponse**

---

# WireGuard

Pour WireGuard la partie `Desktop à réseau` est optionnelle.
Vous allez configurer WireGuard avec des clés statiques, tout en décrivant comment éviter que les
clés privées se trouvent sur plus d'une seule machine.
Utilisez le port `51820` pour les connexions, car c'est celui qui est aussi ouvert avec le `docker-compose.yaml`.
Vous trouverez des détails sur l'installation de WireGuard ici: 
[WireGuard QuickStart](https://www.wireguard.com/quickstart/)

## Création des clés

D'abord il faut commencer par créer des clés statiques pour les différentes machines.
Utilisez la commande `wg` pour ceci et stockez les clés quelque part dans les répertoires `root`,
pour que vous puissiez les retrouver facilement par la suite.

---

**Question 2.1 (2) : Sécuriser la création des clés**

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
Vérifiez aussi à l'aide de `tcpdump` que les paquets entre `MainS` et `FarS` sont seulement
des paquets WireGuard.

---

**Question 2.2 (2) : sécurité du fichier `wg0.conf`**

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

**Question 2.3 (1): tableau de routage sur `MainS`**

Ajoutez ici une copie du tableau de routage de `MainS` une fois les connexions avec
`FarS` et `Remote` établies.
Utilisez la commande `ip route` pour l'afficher.

---

**Réponse**

---

**Question 2.4 (3): passage des paquets**

Décrivez par quelles interfaces un paquet passe quand on fait un `ping 10.0.2.10` sur la machine `Remote`.
Pour chaque passage à une nouvelle interface, indiquez la machine, l'interface, et si le paquet va être
transféré d'une façon chiffrée ou pas.
Décrivez le chemin aller du `echo request` et le chemin retour du `echo reply`.

---

**Réponse**
+-----------+-------------+--------------+------------+
I Source    I Destination I Interfaces   I Chiffré    I
+-----------+-------------+--------------+------------+
I FarC1     I FarS        I eth0 -> eth1 I non        I
+-----------+-------------+--------------+------------+

---

## Test

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

Ici, vous allez utiliser l'implémentation de StrongSwan
pour mettre en place un VPN entre les différentes machines.
Comme OpenVPN, StrongSwan se base sur des certificats pour l'autorisation des connexions.
Par contre, il ne va pas utiliser le TLS pour la connexion, mais d'autres protocoles.

Vous trouvez des informations pour l'installation sur le 
[StrongSwan QuickStart](https://docs.strongswan.org/docs/5.9/config/quickstart.html)

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
Regardez quelles sont les informations correctes à y mettre.
Vous pouvez bien sûr inventer une entreprise et un nom de domaine à votre idée.

Gardez les clés quelque part dans l'arborescence `root` de votre projet.
Assurez-vous que les clés sont seulement disponibles sur les machines qui en ont besoin. 

Suivant les instructions dans
[PKI Quickstart](https://docs.strongswan.org/docs/5.9/pki/pkiQuickstart.html),
n'oubliez pas d'ajouter l'adresse IP avec un `--san`.
Donc votre commande doit commencer par

```
pki --san main --san 10.0.0.2 ...
```

---

**Question 3.1 (2): commandes pour création de clés**

- 1 - Quelles sont les commandes que vous avez utilisées pour créer le CA et les clés pour les machines?
- 1 - Si vous avez écrit un script pour créer les clés, copiez-le dans votre répertoire et indiquez le chemin ici.

---

**Réponse**

---

**Question 3.2 (3) : création de clés hôtes sécurisées**

Dans la documentation de StrongSwan il y a une description pour éviter que la personne qui a créé le
CA de racine voie les clés privées des hôtes.
Supposant qu'il y a deux entités, le `CA holder` et le `host`, décrivez chronologiquement qui crée quelle
clé à quel moment, et quels sont les fichiers échangés.

---

**Réponse**

---

## Réseau à réseau

Maintenant, vous êtes prêt·e·s pour configurer StrongSwan pour connecter les réseaux `Main` et `Far`.
Faites attention, parce que StrongSwan va seulement créer la connexion une fois qu'un paquet le requiert.
En mettant en place la connexion, `charon` va journaliser ses efforts dans le terminal.
Regardez bien ce journal si quelque chose ne marche pas.

Comme décrit dans l'introduction pour IPSec, il faut stocker les fichiers nécessaires dans le répertoire `root`, puis
les copier dans l'arborescence pour que StrongSwan puisse les trouver.

Un bon vieux `tcpdump -i any -n` va vous aider si vous ne trouvez plus par où passent les paquets.

---

**Question 3.3 (2) : fichiers et leur utilité**

Pour les hôtes `MainS` et `FarS`, décrivez pour chaque fichier que vous copiez la destination et l'utilité de
ce fichier.

---

**Réponse**

---

## Remote à Réseau

La prochaine étape est de connecter un seul hôte à `MainS`.
Cet hôte doit être capable de contacter autant le réseau `main` que le réseau `far`.
Bien sûr, cela requiert que l'IPSec entre `main` et `far` est actif.
Ceci correspond à la configuration `Roadwarrior` du document de OpenSwan.

---

**Question 3.4 (1) : fichiers et leur utilité**

Comme pour l'exercice _Réseau à réseau_, les fichiers doivent être dans le répertoire `root`, mais
StrongSwan en a besoin dans d'autres répertoires.
Pour l'hôte `Remote`, décrivez pour chaque fichier que vous copiez la destination et l'utilité de
ce fichier.
Indiquez aussi quel(s) fichier(s) vous avez dû ajouter à `MainS`.

---

**Réponse**

---

## Test

Comme pour l'OpenVPN et le Wireguard, assurez-vous que les tests passent en lançant:

```bash
./test/runit.sh ipsec
```

Faites un commit et un push, et vérifiez que github vous donne le feu vert.

# Comparaison

Maintenant, vous allez devoir comparer les différents protocoles entre eux.
Pour chaque question, assurez-vous de bien donner des explications complètes,
sauf si la question vous demande de donner qu'une courte réponse.

## Sécurité

---

**Question 4.1 (2) : Sécurité de la communication**

Décrivez la sécurité maximale disponible pour chaque protocole une fois la connexion établie.
Pour chacune de vos configurations retenues dans ce labo, décrivez quels sont les algorithmes utilisés pour sécuriser la connexion.

---

**Réponse:**

- OpenVPN:
- WireGuard:
- IPSec:

---

**Question 4.22 (2) : Sécurité de l'authentification**

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

**Question 4.3 (1) : Facilité de la configuration serveur**

Quelle est la complexité de mettre en place un serveur pour les deux cas demandés
dans les exercices?
Triez votre réponse par ordre croissant de complexité.

---

**Réponse:**

- OpenVPN:
- WireGuard:
- IPSec:

---

## Performance

---

**Question 4.4 (2) : Plus rapide au plus lent**

Triez les trois configurations que nous avons vues dans l'ordre décroissant
de leur vitesse mesuré avec `iperf`.
Pour chaque protocole, indiquez les trois vitesses suivantes:
- entre le `MainS` et le `FarS`
- entre `MainC1` et `FarC1` 
- entre `Remote` et `FarC2`

Si un des protocoles est beaucoup plus rapide que les autres, décrivez pourquoi c'est le cas.

---

**Réponse:**

- OpenVPN:
- WireGuard:
- IPSec:

---

# Points spécifiques

Voici quelques points supplémentaires qui seront évalués, avec leurs points:

- 5.1 (2) - organisation des fichiers dans le répertoire `root`
- 5.2 (3) - acceptation du labo par le script `test/runit.sh`
- 5.3 (2) - bonne utilisation des scripts

## OpenVPN

- 5.4 (2) - est-ce que la configuration dans `root/far/openvpn/client.ovpn` marche pour une connexion depuis l'ordinateur
  hôte et toutes les machines sont atteignables depuis l'hôte

## WireGuard

- 5.5 (3) bonus - connexion avec la configuration dans `root/far/wireguard/client.conf` depuis l'ordinateur
  hôte et toutes les machines sont atteignables depuis l'hôte

## IPSec

- 5.6 (1) - pas de clés supplémentaires pour le IPSec dans les autres machines
- 5.7 (1) - présence des fichiers utilisés pour la mise en place des clés pour IPSec
