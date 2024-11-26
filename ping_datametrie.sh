#!/bin/bash

# Charger les paramètres de configuration
source config.sh

# Initialisation des variables statistiques
min_ping=9999
max_ping=0
min_time=9999
max_time=0
total_ping=0
total_time=0
test_count=0

# Vérifier si le fichier de log existe déjà
if [ ! -f "$log_file" ]; then
    # Créer le fichier de log et ajouter les en-têtes
    echo "Date,Serveur,Min Ping (ms),Max Ping (ms),Min Temps (ms),Max Temps (ms),Résultat,Ping Moyen (ms),Temps Moyen (s)" > "$log_file"
fi

while true; do
    for serveur in "${serveurs[@]}"; do
        # Ping du serveur
        ping_result=$(ping -c 1 $serveur | grep 'time=' | awk -F '=' '{print $4}' | awk '{print $1}')
        
        # Requête HTTP avec curl et mesure du temps de chargement
        temps_chargement=$(curl -s -o /dev/null -w "%{time_total}" "https://$serveur")
        
        # Conversion du temps de chargement en millisecondes pour la comparaison
        temps_chargement_ms=$(echo "$temps_chargement * 1000" | bc)

        # Mise à jour des statistiques
        total_ping=$(echo "$total_ping + $ping_result" | bc)
        total_time=$(echo "$total_time + $temps_chargement_ms" | bc)
        test_count=$((test_count + 1))

        # Déterminer le résultat du test et mettre à jour les statistiques
        if (( $(echo "$temps_chargement_ms < $max_response_time" | bc -l) )); then
            resultat="Réussi"
        else
            resultat="Échec"
        fi

        # Mise à jour des valeurs min/max pour le ping et le temps de chargement
        if (( $(echo "$ping_result < $min_ping" | bc -l) )); then
            min_ping=$ping_result
        fi

        if (( $(echo "$ping_result > $max_ping" | bc -l) )); then
            max_ping=$ping_result
        fi

        if (( $(echo "$temps_chargement_ms < $min_time" | bc -l) )); then
            min_time=$temps_chargement_ms
        fi

        if (( $(echo "$temps_chargement_ms > $max_time" | bc -l) )); then
            max_time=$temps_chargement_ms
        fi

        # Calcul des moyennes après chaque test
        avg_ping=$(echo "scale=2; $total_ping / $test_count" | bc)
        avg_time=$(echo "scale=2; $total_time / $test_count / 1000" | bc) # Convertir en secondes

        # Enregistrement des résultats dans le fichier CSV après chaque test pour chaque serveur, incluant le résultat du test avant les compteurs.
        echo "$(date),$serveur,$min_ping,$max_ping,$min_time,$max_time,$resultat,$avg_ping,$avg_time" >> "$log_file"

        # Affichage des résultats dans la console pour suivi en temps réel, incluant le résultat du test.
        echo "$(date): Serveur: ${serveur}, Ping: ${ping_result}ms, Temps de chargement: ${temps_chargement}s, Résultat: ${resultat}"
    done
    
    # Attente de l'intervalle spécifié avant le prochain test global pour tous les serveurs.
    sleep $intervalle
    
    # Réinitialiser les statistiques après chaque cycle complet sur tous les serveurs.
    min_ping=9999; max_ping=0; min_time=9999; max_time=0; successful_tests=0; failed_tests=0; total_ping=0; total_time=0; test_count=0;
done
