# shell_datametrie

Ce script Bash permet de surveiller la performance réseau de plusieurs serveurs en mesurant les temps de réponse via des pings et des requêtes HTTP. Les résultats sont enregistrés dans un fichier CSV pour un suivi et une analyse ultérieurs.

## Fonctionnalités

- **Ping** : Mesure le temps de réponse des serveurs via la commande `ping`.
- **Requêtes HTTP** : Utilise `curl` pour mesurer le temps total de chargement d'une page web.
- **Statistiques** : Calcule les valeurs minimales, maximales et moyennes des temps de réponse.
- **Résultats** : Enregistre les résultats dans un fichier CSV et affiche les résultats en temps réel dans la console.
- **Configuration** : Paramètres configurables via un fichier `config.sh`.

## Prérequis

- Bash
- `ping` command-line tool
- `curl` command-line tool
- `bc` pour les calculs arithmétiques

## Installation

1. Clonez ce dépôt sur votre machine locale.
   ```bash
   git clone <URL_DU_DEPOT>
   cd <NOM_DU_DEPOT>
   ```

2. Assurez-vous que le script est exécutable :
   ```bash
   chmod +x script_datamétrie.sh
   ```

3. Créez un fichier `config.sh` à la racine du projet pour configurer vos paramètres.

## Configuration

Créez un fichier nommé `config.sh` dans le même répertoire que le script. Ce fichier doit contenir les variables suivantes :

```bash
# Liste des serveurs à surveiller
serveurs=("serveur1.com" "serveur2.com")

# Fichier de log pour enregistrer les résultats
log_file="resultats.csv"

# Temps maximum de réponse acceptable (en millisecondes)
max_response_time=1000

# Intervalle entre chaque test (en secondes)
intervalle=60
```

## Utilisation

Exécutez le script avec la commande suivante :

```bash
./script_datamétrie.sh
```

Le script va exécuter en boucle indéfinie, effectuant des tests sur chaque serveur à l'intervalle spécifié et enregistrant les résultats dans le fichier CSV défini.

## Résultats

Les résultats sont enregistrés dans un fichier CSV qui inclut les informations suivantes pour chaque test :

- Date et heure du test
- Nom du serveur testé
- Ping minimum et maximum (en ms)
- Temps minimum et maximum de chargement (en ms)
- Résultat du test (Réussi ou Échec)
- Ping moyen (en ms)
- Temps moyen de chargement (en secondes)
