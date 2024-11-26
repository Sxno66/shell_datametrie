#!/bin/bash

# Load configuration parameters
source config.sh

# Remove the log file if it already exists
if [ -f "$log_file" ]; then
    rm "$log_file"
fi

# Initialize statistical variables
min_ping=9999
max_ping=0
min_time=9999
max_time=0
total_ping=0
total_time=0
test_count=0

# Create the log file and add headers
echo "Date,Serveur,Min Ping (ms),Max Ping (ms),Min Temps (ms),Max Temps (ms),Résultat,Ping Moyen (ms),Temps Moyen (s)" > "$log_file"

send_email() {
    # Send the CSV file via email using mail
    {
        echo "To: $EMAIL_TO"
        echo "From: votre_adresse@email.com" # Replace with your email configured in mail
        echo "Subject: Log de performance $(date +'%Y-%m-%d %H:%M:%S')"
        echo "Content-Type: text/plain; charset=UTF-8"
        echo "MIME-Version: 1.0"
        echo ""
        cat "$log_file"
    } | /usr/bin/mail -s "Log de performance $(date +'%Y-%m-%d %H:%M:%S')" "$EMAIL_TO" < "$log_file"
}

while true; do
    for serveur in "${serveurs[@]}"; do
        ping_result=$(ping -c 1 $serveur | grep 'time=' | awk -F '=' '{print $4}' | awk '{print $1}')
        temps_chargement=$(curl -s -o /dev/null -w "%{time_total}" "https://$serveur")
        temps_chargement_ms=$(echo "$temps_chargement * 1000" | bc)

        total_ping=$(echo "$total_ping + $ping_result" | bc)
        total_time=$(echo "$total_time + $temps_chargement_ms" | bc)
        test_count=$((test_count + 1))

        if (( $(echo "$temps_chargement_ms < $max_response_time" | bc -l) )); then
            resultat="Réussi"
        else
            resultat="Échec"
        fi

        if (( $(echo "$ping_result < $min_ping" | bc -l) )); then min_ping=$ping_result; fi
        if (( $(echo "$ping_result > $max_ping" | bc -l) )); then max_ping=$ping_result; fi

        if (( $(echo "$temps_chargement_ms < $min_time" | bc -l) )); then min_time=$temps_chargement_ms; fi
        if (( $(echo "$temps_chargement_ms > $max_time" | bc -l) )); then max_time=$temps_chargement_ms; fi

        avg_ping=$(echo "scale=2; $total_ping / $test_count" | bc)
        avg_time=$(echo "scale=2; $total_time / $test_count / 1000" | bc)

        echo "$(date),$serveur,$min_ping,$max_ping,$min_time,$max_time,$resultat,$avg_ping,$avg_time" >> "$log_file"

        echo "$(date): Serveur: ${serveur}, Ping: ${ping_result}ms, Temps de chargement: ${temps_chargement}s, Résultat: ${resultat}"
    done
    
    send_email
    
    sleep 300
    
    # Reset statistics after each complete cycle for all servers.
    min_ping=9999; max_ping=0; min_time=9999; max_time=0; total_ping=0; total_time=0; test_count=0;
done
