#!/bin/bash
# Recipient email address



recipient="lololo@gmail.com"



# Email subject



subject="Automated Email Notification"



# Email message body



message="Hello,
This is an automated notification sent via shell script.
Regards,
Your Name"

# Send email using the 'mail' command



echo "$message" | mail -s "$subject" $recipient
