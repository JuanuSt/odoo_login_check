# Odoo login bruteforce attack and detection
Odoo has two interfaces with passwords. One is the admin interface, which has no username and is used to manage databases. The other one, once the database has been selected,
is the user interface, which ask for classic user and password combo for this database.

## Bruteforcing with [Hydra](https://github.com/vanhauser-thc/thc-hydra)
Both interfaces have a security policy against Cross-Site Request Forgery, an Anti-CSRF token. So it is necessary to make a request (cURL) before launch Hydra to get this token.
The session_id is also necessary, so in this same request the cookie is saved and parsed to extract it.

The http-forms are differents for each interface. For admin interface Hydra gives as 'failed password' when find the word 'denied' in the response (F=denied). For user interface
Hydra gives as 'success password' when find the words 'window.location' (S=window.location). This last method is less prone to false positives. For both attacks you can use the
SSL versions, just edit the scritps to use them.

Hydra contains a module for Postgres too, and in many cases the sites that run Odoo expose the Postgres port to Internet. So we can attack directly the same database with same
users and passwords that we are using for web interfaces. The script odoo_all.sh gathers the three attacks together.

## Detection
These attacks leave traces in the Odoo and Postgres logs. To check these fails there are two scripts, monitoring and report. The monitoring script is intended to be executed by
a crontab every five minutes and detect attacks in progress. The report script is intended to be run at the end of the day to summarise the logins fail in Odoo and Postgres.
Both can send a email if a treshold is exceeded.

> Note that if this treshold is exceeded by monitoring script it will continue sending a alert email every five minutes. In that case, just increase the threshold until next day.

Check how parsing is made by the scripts before launching them. The format of date or the keywords can be different in your logs.