#!/bin/bash

# This script runs every 5 minutes

# Variables
log_dir="/var/log/odoo"
pg_log_dir="/var/lib/pgsql/9.6/data/pg_log"
date_today=$(date -d "$D" '+%Y-%m-%d')
fail_threshold=10
server="yourserver"

# Start
# Odoo user login fails
num_failed_login=$(grep -r ^"${date_today}" "$log_dir" --include=*.log | grep 'Login failed' | wc -l)

# Odoo admin fails
num_admin_fails=$(grep -B6 "AccessDenied:" -r "$log_dir" --include=*.log | grep "${date_today}" | grep "ERROR" | awk '{print $2,$5,$7}' | wc -l)

# Postgres user login fails
num_failed_pg_login=$(grep -r "${date_today}" "$pg_log_dir" --include=*.log | grep 'FATAL' | grep 'password' | awk '{print $2,$3,$6,$8,$10,$13,$14}' | wc -l)

if (( $num_failed_login >= $fail_threshold )) || (( $num_admin_fails >= $fail_threshold )) || (( $num_failed_pg_login  >= $fail_threshold ));then
   # Odoo user login fails
   results="
Odoo user login fails on date $date_today
-----------------------------------------"
   results="${results}"$'\n'"$num_failed_login Odoo user failed logins"$'\n'
   results="${results}"$'\n'$(grep -r ^"${date_today}" "$log_dir" --include=*.log | grep 'Login failed' | awk '{print $2,$7,$8,$9,$10,$11}')
   results="${results}"$'\n'"_________________________________________"$'\n'

   # Odoo admin fails
   results="${results}"$'\n'"
Odoo admin login fails on date $date_today
-----------------------------------------"
   results="${results}"$'\n'"$num_admin_fails Odoo admin failed logins"$'\n'
   results="${results}"$'\n'$(grep -B6 "AccessDenied:" -r "$log_dir" --include=*.log | grep "${date_today}" | grep "ERROR" | awk '{print $2,$5,$7}')
   results="${results}"$'\n'"_________________________________________"$'\n'

   # Postgres user login fails
   results="${results}"$'\n'"
Posgres login fails on date $date_today
-----------------------------------------"
   results="${results}"$'\n'"$num_failed_pg_login Postgres failed logins"$'\n'

   all_login_lines=$(grep -r "${date_today}" "$pg_log_dir" --include=*.log | grep -B1 'FATAL' | grep -B1 'password\|host' | awk '{print $2,$3,$4,$9,$14}' | tr -d '«' | tr -d '»' | sed 's/password/user=/'  | sed 's/^\s*$/+/' | tr -d '\n')
   n=0
   old_IFS=$IFS; IFS=$'+'
   for line in ${all_login_lines};do
      n=$(( n + 1 ))
      results="${results}"$'\n'$(echo "$n $line" | awk '{print $1,$2,$3,$4,$5,$9$10}')
   done
   IFS=$old_IFS

   # Send mail
   echo "${results}" | mail -s "[$server] Login monitoring: Too many login fails" your@mail.com

fi

exit
