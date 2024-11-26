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
    # Prepare HTML content for the email
    {
        echo "To: $EMAIL_TO"
        echo "From: votre_adresse@gmail.com" # Replace with your Gmail address
        echo "Subject: Log de performance $(date +'%Y-%m-%d %H:%M:%S')"
        echo "Content-Type: text/html; charset=UTF-8"
        echo "MIME-Version: 1.0"
        echo ""
        echo "<html>"
        echo "<body>"
        echo "<h2>Rapport de Performance</h2>"
        echo "<table style='width: 100%; border-collapse: collapse;'>"
        echo "<tr><th style='border: 1px solid #ddd; padding: 8px; background-color: #f2f2f2;'>Date</th><th style='border: 1px solid #ddd; padding: 8px; background-color: #f2f2f2;'>Serveur</th><th style='border: 1px solid #ddd; padding: 8px; background-color: #f2f2f2;'>Min Ping (ms)</th><th style='border: 1px solid #ddd; padding: 8px; background-color: #f2f2f2;'>Max Ping (ms)</th><th style='border: 1px solid #ddd; padding: 8px; background-color: #f2f2f2;'>Min Temps (ms)</th><th style='border: 1px solid #ddd; padding: 8px; background-color: #f2f2f2;'>Max Temps (ms)</th><th style='border: 1px solid #ddd; padding: 8px; background-color: #f2f2f2;'>Résultat</th><th style='border: 1px solid #ddd; padding: 8px; background-color: #f2f2f2;'>Ping Moyen (ms)</th><th style='border: 1px solid #ddd; padding: 8px; background-color: #f2f2f2;'>Temps Moyen (s)</th></tr>"
        
        while IFS=',' read -r date serveur min_ping max_ping min_time max_time resultat avg_ping avg_time; do
            echo "<tr><td style='border: 1px solid #ddd; padding: 8px;'>${date}</td><td style='border: 1px solid #ddd; padding: 8px;'>${serveur}</td><td style='border: 1px solid #ddd; padding: 8px;'>${min_ping}</td><td style='border: 1px solid #ddd; padding: 8px;'>${max_ping}</td><td style='border: 1px solid #ddd; padding: 8px;'>${min_time}</td><td style='border: 1px solid #ddd; padding: 8px;'>${max_time}</td><td style='border: 1px solid #ddd; padding: 8px;'>${resultat}</td><td style='border: 1px solid #ddd; padding: 8px;'>${avg_ping}</td><td style='border: 1px solid #ddd; padding: 8px;'>${avg_time}</td></tr>"
        done < "$log_file"

        echo "</table>"
        echo "</body>"
        echo "</html>"
    } | /usr/bin/mail -s "Log de performance $(date +'%Y-%m-%d %H:%M:%S')" -a "Content-Type:text/html" "$EMAIL_TO"
}

ping_counter=0   # Initialize a counter for pings

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
    
    ping_counter=$((ping_counter + 1))   # Increment the ping counter
    
    if (( ping_counter >= 10 )) ; then   # Check if we've done enough pings for an email
        send_email                     # Send the email with results
        ping_counter=0                 # Reset the counter after sending email
    fi
    
    sleep 30   # Wait for next ping cycle
    
    # Reset statistics after each complete cycle for all servers.
    min_ping=9999; max_ping=0; min_time=9999; max_time=0; total_ping=0; total_time=0; test_count=0;
done
