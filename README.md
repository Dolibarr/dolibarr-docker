# Dolibarr on Docker

Docker image for Dolibarr ERP & CRM Open source web suite.

Dolibarr is a modern software package to manage your organization's activity (contacts, quotes, invoices, orders, stocks, agenda, hr, expense reports, accountancy, ecm, manufacturing, ...).

> [More information](https://github.com/dolibarr/dolibarr)


## Available versions/tags on Docker

See https://hub.docker.com/r/dolibarr/dolibarr/tags

*Very old Dolibarr versions may not be updated on docker hub, but you can always get them as standard zip package from Dolibarr official web site*


## Supported architectures

Linux x86-64 (`amd64`), ARMv7 32-bit (`arm32v7` :warning: MariaDB/Mysql docker images don't support it) and ARMv8 64-bit (`arm64v8`)


## How to run this image ?

This image is based on the [official PHP repository](https://hub.docker.com/_/php/) and the [official Dolibarr repository](https://github.com/Dolibarr/dolibarr). It is build
using the tools saved in the [Dolibarr docker build repository](https://github.com/Dolibarr/dolibarr-docker). 

This image does not contains database, so you need to link it with a database container. Let's use [Docker Compose](https://docs.docker.com/compose/) to integrate it with [MariaDB](https://hub.docker.com/_/mariadb/) (you can also use [MySQL](https://hub.docker.com/_/mysql/) if you prefer):

If you want to have a persistent database and dolibarr data files after reboot or upgrade, you must first
create a directory `/home/dolibarr_mariadb`, `/home/dolibarr_documents` and `/home/dolibarr_custom` on your host to store persistent files, respectively, of the database, of the Dolibarr document files and of the installed external Dolibarr modules.

`mkdir /home/dolibarr_mariadb /home/dolibarr_documents /home/dolibarr_custom;`

Then, create a `docker-compose.yml` file as following:

```yaml
# Edit this file then run 
# docker-compose up -d
# docker-compose logs

services:
    mariadb:
        image: mariadb:latest
        environment:
            MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-root}
            MYSQL_DATABASE: ${MYSQL_DATABASE:-dolidb}
            MYSQL_USER: ${MYSQL_USER:-dolidbuser}
            MYSQL_PASSWORD: ${MYSQL_PASSWORD:-dolidbpass}

        volumes:
            - /home/dolibarr_mariadb:/var/lib/mysql

    web:
    	# Choose the version of image to install
    	# dolibarr/dolibarr:latest (the latest stable version)
    	# dolibarr/dolibarr:develop
    	# dolibarr/dolibarr:x.y.z
        image: dolibarr/dolibarr:latest
        environment:
            WWW_USER_ID: ${WWW_USER_ID:-1000}
            WWW_GROUP_ID: ${WWW_GROUP_ID:-1000}
            DOLI_DB_HOST: ${DOLI_DB_HOST:-mariadb}
            DOLI_DB_NAME: ${DOLI_DB_NAME:-dolidb}
            DOLI_DB_USER: ${DOLI_DB_USER:-dolidbuser}
            DOLI_DB_PASSWORD: ${DOLI_DB_PASSWORD:-dolidbpass}
            DOLI_URL_ROOT: "${DOLI_URL_ROOT:-http://0.0.0.0}"
            DOLI_ADMIN_LOGIN: "${DOLI_ADMIN_LOGIN:-admin}"
            DOLI_ADMIN_PASSWORD: "${DOLI_ADMIN_PASSWORD:-admin}"
            DOLI_CRON: ${DOLI_CRON:-0}
            DOLI_INIT_DEMO: ${DOLI_INIT_DEMO:-0}
            DOLI_COMPANY_NAME: ${DOLI_COMPANY_NAME:-MyBigCompany}

        ports:
            - "80:80"
        links:
            - mariadb
        volumes:
            - /home/dolibarr_documents:/var/www/documents
            - /home/dolibarr_custom:/var/www/html/custom
```

Then build and run all services (-d is to run in background).

`sudo docker-compose up -d`

If the "docker-compose" command is not available, you can replace it with the command "docker compose".

You can check the web and the mariadb containers are up and see logs with

`sudo docker-compose ps`

`sudo docker-compose logs`

Once the log shows that the start is complete (you should see a message "You can connect to your Dolibarr web application..."), go to http://0.0.0.0 to access to the new Dolibarr installation, first admin login is admin/admin (if you did not change default value previously in the docker-compose.yml file). 

Note: If the host port 80 is already used, you can replace "80:80" with "xx:80" where xx a free port on the host. You will be
able to access the Dolibarr using the URL http://0.0.0.0:xx


Other examples:

You can find several examples in the `examples` directory, such as:
 - [Running Dolibarr with a letsencrypt certificate](./examples/with-certbot/dolibarr-with-certbot.md)
 - [Running Dolibarr with a mysql server](./examples/with-mysql/dolibarr-with-mysql.md)
 - [Running Dolibarr with a Traefik reverse proxy](./examples/with-rp-traefik/dolibarr-with-traefik.md)
 - [Running Dolibarr with secrets](./examples/with-secrets/dolibarr-with-secrets.md)


## Upgrading Dolibarr version and migrating DB

Warning: Only data stored into the persistent directories (see the section "volumes" of your docker-compose.yml) will not be lost after an upgrade of containers.

Remove the `install.lock` file located inside the container volume `/var/www/documents` using one of this method:

`sudo docker exec nameofwebcontainer bash -c "rm -f /var/www/documents/install.lock"`

or

`sudo docker exec -it nameofwebcontainer bash`

`rm -f /var/www/documents/install.lock; exit`

or if the document directory has been set as a persistent directory, you can do it from the host:

`rm -f /home/dolibarr_documents/install.lock`


Then download the updated version of containers and restart them.

`sudo docker-compose pull`

`sudo docker-compose up -d`

`sudo docker-compose logs`

Ensure that env `DOLI_INSTALL_AUTO` in your docker-compose.yml is set to `1` so it will migrate the Database to the new version, or
you can prefer to use the standard way to upgrade Dolibarr through the web interface by calling the /install page.


## Environment variables summary

You can use the following variables for a better customization of your docker-compose file.

| Variable                        | Default value                  | Description |
| ------------------------------- | ------------------------------ | ----------- |
| **WWW_USER_ID**                 |                                | ID of user www-data. ID will not changed if leave empty. During a development, it is very practical to put the same ID as the host user.
| **WWW_GROUP_ID**                |                                | ID of group www-data. ID will not changed if leave empty.
| **PHP_INI_DATE_TIMEZONE**       | *UTC*                          | Default timezone on PHP
| **PHP_INI_MEMORY_LIMIT**        | *256M*                         | PHP Memory limit
| **PHP_INI_UPLOAD_MAX_FILESIZE** | *2M*                           | PHP Maximum allowed size for uploaded files
| **PHP_INI_POST_MAX_SIZE**       | *8M*                           | PHP Maximum size of POST data that PHP will accept.
| **PHP_INI_ALLOW_URL_FOPEN**     | *0*                            | Allow URL-aware fopen wrappers
| **DOLI_INSTALL_AUTO**           | *1*                            | 1: The installation will be done during docker first boot
| **DOLI_INIT_DEMO**              | *0*                            | 1: The installation will also load demo data during docker first boot
| **DOLI_PROD**                   | *1*                            | 1: Dolibarr will be run in production mode
| **DOLI_DB_TYPE**                | *mysqli*                       | Type of the DB server (**mysqli**, pgsql)
| **DOLI_DB_HOST**                | *mariadb*                      | Host name of the MariaDB/MySQL server
| **DOLI_DB_HOST_PORT**           | *3306*                         | Host port of the MariaDB/MySQL server
| **DOLI_DB_NAME**                | *dolidb*                       | Database name
| **DOLI_DB_USER**                | *dolidbuser*                   | Database user
| **DOLI_DB_PASSWORD**            | *dolidbpass*                   | Database user's password
| **DOLI_URL_ROOT**               | *http://localhost*             | Url root of the Dolibarr installation
| **DOLI_ADMIN_LOGIN**            | *admin*                        | Admin's login created on the first boot
| **DOLI_ADMIN_PASSWORD**         | *admin*                        | Admin's initial password created on the first boot
| **DOLI_ENABLE_MODULES**         |                                | Comma-separated list of modules to be activated at install. modUser will always be activated. (Ex: `Societe,Facture,Stock`)
| **DOLI_COMPANY_NAME**           |                                | Set the company name of Dolibarr at container init
| **DOLI_COMPANY_COUNTRYCODE**    |                                | Set the company and Dolibarr country at container init. Need 2-letter codes like "FR", "GB", "US",...
| **DOLI_AUTH**                   | *dolibarr*                     | Which method is used to connect users, change to `ldap` or `ldap, dolibarr` to use LDAP
| **DOLI_LDAP_HOST**              | *127.0.0.1*                    | The host of the LDAP server
| **DOLI_LDAP_PORT**              | *389*                          | The port of the LDAP server
| **DOLI_LDAP_VERSION**           | *3*                            | The version of LDAP to use
| **DOLI_LDAP_SERVER_TYPE**       | *openldap*                     | The type of LDAP server (openLDAP, Active Directory, eGroupWare)
| **DOLI_LDAP_LOGIN_ATTRIBUTE**   | *uid*                          | The attribute used to bind users
| **DOLI_LDAP_DN**                | *ou=users,dc=my-domain,dc=com* | The base where to look for users
| **DOLI_LDAP_FILTER**            |                                | The filter to authorise users to connect
| **DOLI_LDAP_BIND_DN**           |                                | The complete DN of the user with read access on users
| **DOLI_LDAP_BIND_PASS**         |                                | The password of the bind user
| **DOLI_LDAP_DEBUG**             | *false*                        | Activate debug mode
| **DOLI_CRON**                   | *0*                            | 1: Enable cron service
| **DOLI_CRON_KEY**               |                                | Security key launch cron jobs
| **DOLI_CRON_USER**              |                                | Dolibarr user used for cron jobs
| **DOLI_INSTANCE_UNIQUE_ID**     |                                | Secret ID used as a salt / key for some encryption. By default, it is set randomly when the docker container is created.

Some environment variables are compatible with docker secrets behaviour, just add the `_FILE` suffix to var name and point the value file to read.
Environment variables that are compatible with docker secrets:

* `DOLI_DB_USER` => `DOLI_DB_USER_FILE`
* `DOLI_DB_PASSWORD` => `DOLI_DB_PASSWORD_FILE`
* `DOLI_ADMIN_LOGIN` => `DOLI_ADMIN_LOGIN_FILE`
* `DOLI_ADMIN_PASSWORD` => `DOLI_ADMIN_PASSWORD_FILE`
* `DOLI_CRON_KEY` => `DOLI_CRON_KEY_FILE`
* `DOLI_CRON_USER` => `DOLI_CRON_USER_FILE`
* `DOLI_INSTANCE_UNIQUE_ID` => `DOLI_INSTANCE_UNIQUE_ID_FILE`



## Advanced setup

### Add post-deployment and before starting scripts

It is possible to execute `*.sh`, `*.sql` and/or `*.php` custom files at the end of a deployment or before starting Apache by mounting volumes.
For scripts to execute during deployment, mount volume in `/var/www/scripts/docker-init.d`.
For scripts to execute before Apache start, mount volume in `/var/www/scripts/before-starting.d`.
```
\docker-init.d
|- custom_script.sql
|- custom_script.php
|- custom_script.sh
```

Mount the volumes with compose file : 

```yaml
services:
    mariadb:
        image: mariadb:latest
        environment:
            MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-root}
            MYSQL_DATABASE: ${MYSQL_DATABASE:-dolidb}
            MYSQL_USER: ${MYSQL_USER:-dolidbuser}
            MYSQL_PASSWORD: ${MYSQL_PASSWORD:-dolidbpass}

    web:
    	# Choose the version of image to install
    	# dolibarr/dolibarr:latest (the latest stable version)
    	# dolibarr/dolibarr:develop
    	# dolibarr/dolibarr:x.y.z
        image: dolibarr/dolibarr
        environment:
            DOLI_DB_HOST: ${DOLI_DB_HOST:-mariadb}
            DOLI_DB_NAME: ${DOLI_DB_NAME:-dolidb}
            DOLI_DB_USER: ${DOLI_DB_USER:-dolidbuser}
            DOLI_DB_PASSWORD: ${DOLI_DB_PASSWORD:-dolidbpass}
            DOLI_URL_ROOT: "${DOLI_URL_ROOT:-http://0.0.0.0}"
            DOLI_ADMIN_LOGIN: "${DOLI_ADMIN_LOGIN:-admin}"
            DOLI_ADMIN_PASSWORD: "${DOLI_ADMIN_PASSWORD:-admin}"
            DOLI_INIT_DEMO: ${DOLI_INIT_DEMO:-0}
            WWW_USER_ID: ${WWW_USER_ID:-1000}
            WWW_GROUP_ID: ${WWW_GROUP_ID:-1000}
        volumes :
          - volume-scripts:/var/www/scripts/docker-init.d
          - before-starting-scripts:/var/www/scripts/before-starting.d
        ports:
            - "80:80"
        links:
            - mariadb
```


### Tuning the apache configuration to suit you

#### ServerName

If you run apache2ctl configtest inside the container you'll probably get a message like this:
> AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using x.y.z.w Set the 'ServerName' directive globally to suppress this message

Easy fix, create a single text file

Contents: "ServerName dolibarr.example.com"

Mountpoint: "/etc/apache2/conf-enabled/servername.conf"

read-only: Yes, mount it read only with :ro 

#### Running your dolibarr behind a proxy?

If you want Dolibarr or the logs from the dolibarr container to reveal the original IP address and not just the proxy's IP address you should create 2 text files:

*remoteip.load*
This file will load the apache module remoteip https://httpd.apache.org/docs/current/mod/mod_remoteip.html

Contents: "LoadModule remoteip_module /usr/lib/apache2/modules/mod_remoteip.so"

Mountpoint: "/etc/apache2/mods-enabled/remoteip.load"

read-only: Yes, mount it read only with :ro 

*remoteip.conf*
This file will contain the configuration for remoteip and should also be bind mounted read-only inside the container. Content will depend on your proxy and which kind of header it uses. You may perhaps also enable the proxy protocol, read more at https://httpd.apache.org/docs/current/mod/mod_remoteip.html

Example content: "RemoteIPHeader X-Forwarded-For"

Mountpoint: "/etc/apache2/mods-enabled/remoteip.conf"


### Support for PostgreSQL

Setting `DOLI_DB_TYPE` to `pgsql` enable Dolibarr to run with a PostgreSQL database.
When set to use `pgsql`, Dolibarr must be installed manually on it's first execution:
 - Browse to `http://0.0.0.0/install`;
 - Follow the installation setup;
 - Add `install.lock` inside the container volume `/var/www/html/documents` (ex `docker-compose exec services-data_dolibarr_1 /bin/bash -c "touch /var/www/html/documents/install.lock"`).

When setup this way, to upgrade version the use of the web interface is mandatory:
 - Remove the `install.lock` file (ex `docker-compose exec services-data_dolibarr_1 /bin/bash -c "rm -f /var/www/html/documents/install.lock"`).
 - Browse to `http://0.0.0.0/install`;
 - Upgrade DB;
 - Add `install.lock` inside the container volume `/var/www/html/documents` (ex `docker-compose exec services-data_dolibarr_1 /bin/bash -c "touch /var/www/html/documents/install.lock"`).

 
## Trouble shooting

If you get error "urllib3.exceptions.URLSchemeUnknown: Not supported URL scheme http+docker" during docker-compose, try to upgrade or downgrade the pip package:
pip install requests==2.31.0
