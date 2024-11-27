#!/bin/bash

# Load configuration parameters
source config.sh

# Function to create GPG keys if they don't exist
create_gpg_keys() {
    if ! gpg --list-secret-keys | grep -q "$EMAIL_FROM"; then
        echo "Création d'une nouvelle paire de clés GPG..."
        gpg --batch --gen-key <<EOF
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 2048
Name-Real: Automated Script
Name-Email: $EMAIL_FROM
Expire-Date: 0
%no-protection
%commit
%echo done
EOF
        if [ $? -ne 0 ]; then
            echo "Erreur lors de la création des clés GPG."
            exit 1
        fi
        echo "Clés GPG créées avec succès."
    else
        echo "Les clés GPG existent déjà."
    fi
}

# Function to export and save GPG keys
export_gpg_keys() {
    local public_key_file="public_key.asc"
    local private_key_file="private_key.asc"

    gpg --armor --export "$EMAIL_FROM" > "$public_key_file"
    gpg --armor --export-secret-key "$EMAIL_FROM" > "$private_key_file"

    echo "Clés GPG exportées et sauvegardées dans $public_key_file et $private_key_file"
}

# Create and export GPG keys
create_gpg_keys
export_gpg_keys

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
    # Sign the CSV file
    gpg --detach-sign --armor "$log_file"
    
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la signature du fichier CSV."
        return 1
    fi

    # Prepare the email content and attach both the CSV log file and its signature
    {
        echo "To: $EMAIL_TO"
        echo "From: $EMAIL_FROM"
        echo "Subject: Log de performance $(date +'%Y-%m-%d %H:%M:%S')"
        echo "Content-Type: text/html; charset=UTF-8"
        echo "MIME-Version: 1.0"
        echo ""
        echo "<html>"
        echo "<body>"
        echo "<h2>Rapport de Performance</h2>"
        echo "<p>Veuillez trouver ci-joint le rapport de performance au format CSV et sa signature GPG.</p>"
        echo "</body>"
        echo "</html>"
    } | /usr/sbin/ssmtp -a "$log_file" -a "${log_file}.asc" "$EMAIL_TO"

    # Clean up the signature file
    rm "${log_file}.asc"
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
#!/bin/bash

# Load configuration parameters
source config.sh

# Function to create GPG keys if they don't exist
create_gpg_keys() {
    if ! gpg --list-secret-keys | grep -q "$EMAIL_FROM"; then
        echo "Création d'une nouvelle paire de clés GPG..."
        gpg --batch --gen-key <<EOF
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 2048
Name-Real: Automated Script
Name-Email: $EMAIL_FROM
Expire-Date: 0
%no-protection
%commit
%echo done
EOF
        if [ $? -ne 0 ]; then
            echo "Erreur lors de la création des clés GPG."
            exit 1
        fi
        echo "Clés GPG créées avec succès."
    else
        echo "Les clés GPG existent déjà."
    fi
}

# Function to export and save GPG keys
export_gpg_keys() {
    local public_key_file="public_key.asc"
    local private_key_file="private_key.asc"

    gpg --armor --export "$EMAIL_FROM" > "$public_key_file"
    gpg --armor --export-secret-key "$EMAIL_FROM" > "$private_key_file"

    echo "Clés GPG exportées et sauvegardées dans $public_key_file et $private_key_file"
}

# Create and export GPG keys
create_gpg_keys
export_gpg_keys

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
    # Sign the CSV file
    gpg --detach-sign --armor "$log_file"
    
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la signature du fichier CSV."
        return 1
    fi

    # Prepare the email content and attach both the CSV log file and its signature
    {
        echo "To: $EMAIL_TO"
        echo "From: $EMAIL_FROM"
        echo "Subject: Log de performance $(date +'%Y-%m-%d %H:%M:%S')"
        echo "Content-Type: text/html; charset=UTF-8"
        echo "MIME-Version: 1.0"
        echo ""
        echo "<html>"
        echo "<body>"
        echo "<h2>Rapport de Performance</h2>"
        echo "<p>Veuillez trouver ci-joint le rapport de performance au format CSV et sa signature GPG.</p>"
        echo "</body>"
        echo "</html>"
    } | /usr/sbin/ssmtp -a "$log_file" -a "${log_file}.asc" "$EMAIL_TO"

    # Clean up the signature file
    rm "${log_file}.asc"
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
