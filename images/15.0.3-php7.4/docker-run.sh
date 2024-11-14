#!/bin/bash
# This script is run when the Docker web container is started.
# It is embedded into the Docker image of dolibarr/dolibarr.
#

# usage: get_env_value VAR [DEFAULT]
#    ie: get_env_value 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
function get_env_value() {
	local varName="${1}"
	local fileVarName="${varName}_FILE"
	local defaultValue="${2:-}"

	if [ "${!varName:-}" ] && [ "${!fileVarName:-}" ]; then
		echo >&2 "error: both ${varName} and ${fileVarName} are set (but are exclusive)"
		exit 1
	fi

	local value="${defaultValue}"
	if [ "${!varName:-}" ]; then
	  value="${!varName}"
	elif [ "${!fileVarName:-}" ]; then
		value="$(< "${!fileVarName}")"
	fi

	echo ${value}
	exit 0
}


# Function to create directories, create conf.php file and set permissions on files
function initDolibarr()
{
  if [[ ! -d /var/www/documents ]]; then
    echo "[INIT] => create volume directory /var/www/documents ..."
    mkdir -p /var/www/documents
  fi

  echo "[INIT] => update PHP Config ..."
  cat > ${PHP_INI_DIR}/conf.d/dolibarr-php.ini << EOF
date.timezone = ${PHP_INI_DATE_TIMEZONE}
sendmail_path = /usr/sbin/sendmail -t -i
memory_limit = ${PHP_INI_MEMORY_LIMIT}
upload_max_filesize = ${PHP_INI_UPLOAD_MAX_FILESIZE}
post_max_size = ${PHP_INI_POST_MAX_SIZE}
allow_url_fopen = ${PHP_INI_ALLOW_URL_FOPEN}
session.use_strict_mode = 1
disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_get_handler,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,pcntl_async_signals,passthru,shell_exec,system,proc_open,popen,dl,apache_note,apache_setenv,show_source,virtual
EOF

if [[ ! -f /var/www/html/conf/conf.php ]]; then
    echo "[INIT] => update Dolibarr Config ..."
    cat > /var/www/html/conf/conf.php << EOF
<?php
\$dolibarr_main_url_root='${DOLI_URL_ROOT}';
\$dolibarr_main_document_root='/var/www/html';
\$dolibarr_main_url_root_alt='/custom';
\$dolibarr_main_document_root_alt='/var/www/html/custom';
\$dolibarr_main_data_root='/var/www/documents';
\$dolibarr_main_db_host='${DOLI_DB_HOST}';
\$dolibarr_main_db_port='${DOLI_DB_HOST_PORT}';
\$dolibarr_main_db_name='${DOLI_DB_NAME}';
\$dolibarr_main_db_prefix='llx_';
\$dolibarr_main_db_user='${DOLI_DB_USER}';
\$dolibarr_main_db_pass='${DOLI_DB_PASSWORD}';
\$dolibarr_main_db_type='${DOLI_DB_TYPE}';
\$dolibarr_main_authentication='${DOLI_AUTH}';
\$dolibarr_main_prod=${DOLI_PROD};
EOF
    if [[ ! -z ${DOLI_INSTANCE_UNIQUE_ID} ]]; then
      echo "[INIT] => update Dolibarr Config with instance unique id ..."
      echo "\$dolibarr_main_instance_unique_id='${DOLI_INSTANCE_UNIQUE_ID}';" >> /var/www/html/conf/conf.php
    else
      # It is better to have a generic value than no value
      echo "[INIT] => update Dolibarr Config with instance unique id ..."
      echo "\$dolibarr_main_instance_unique_id='myinstanceuniquekey';" >> /var/www/html/conf/conf.php
    fi
    if [[ ${DOLI_AUTH} =~ .*ldap.* ]]; then
      echo "[INIT] => update Dolibarr Config with LDAP entries ..."
      cat >> /var/www/html/conf/conf.php << EOF
\$dolibarr_main_auth_ldap_host='${DOLI_LDAP_HOST}';
\$dolibarr_main_auth_ldap_port='${DOLI_LDAP_PORT}';
\$dolibarr_main_auth_ldap_version='${DOLI_LDAP_VERSION}';
\$dolibarr_main_auth_ldap_servertype='${DOLI_LDAP_SERVER_TYPE}';
\$dolibarr_main_auth_ldap_login_attribute='${DOLI_LDAP_LOGIN_ATTRIBUTE}';
\$dolibarr_main_auth_ldap_dn='${DOLI_LDAP_DN}';
\$dolibarr_main_auth_ldap_filter='${DOLI_LDAP_FILTER}';
\$dolibarr_main_auth_ldap_admin_login='${DOLI_LDAP_BIND_DN}';
\$dolibarr_main_auth_ldap_admin_pass='${DOLI_LDAP_BIND_PASS}';
\$dolibarr_main_auth_ldap_debug='${DOLI_LDAP_DEBUG}';
EOF
    fi
    if [[ ${DOLI_DB_TYPE} == "mysqli" ]]; then
    	echo "\$dolibarr_main_db_character_set='utf8mb4';" >> /var/www/html/conf/conf.php
    	echo "\$dolibarr_main_db_collation='utf8mb4_unicode_ci';" >> /var/www/html/conf/conf.php
    fi
  fi

  echo "[INIT] => update ownership for file in Dolibarr Config ..."
  chown www-data:www-data /var/www/html/conf/conf.php
  if [[ ${DOLI_DB_TYPE} == "pgsql" && ! -f /var/www/documents/install.lock ]]; then
    chmod 600 /var/www/html/conf/conf.php
  else
    chmod 400 /var/www/html/conf/conf.php
  fi
}


# Wait that container database is running
function waitForDataBase()
{
  r=1

  while [[ ${r} -ne 0 ]]; do
    mysql -u ${DOLI_DB_USER} --protocol tcp -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} --connect-timeout=5 -e "status" >> /var/www/documents/initdb.log 2>&1
    r=$?
    if [[ ${r} -ne 0 ]]; then
      echo "Waiting that SQL database is up ..."
      sleep 2
    fi
  done
}


# Lock any new upgrade
function lockInstallation()
{
  touch /var/www/documents/install.lock
  chown www-data:www-data /var/www/documents/install.lock
  chmod 400 /var/www/documents/install.lock
}


# Run SQL files into /scripts directory.
function runScripts()
{
  if [ -d /var/www/scripts/$1 ] ; then
    for file in /var/www/scripts/$1/*; do
      [ ! -f $file ] && continue

      # If extension is not in PHP SQL SH, we loop
      isExec=$(echo "PHP SQL SH" | grep -wio ${file##*.})
      [ -z "$isExec" ] && continue

      echo "Importing custom ${isExec} from `basename ${file}` ..."
      echo "Importing custom ${isExec} from `basename ${file}` ..." >> /var/www/documents/initdb.log
      if [ "$isExec" == "SQL" ] ; then
        sed -i 's/^--.*//g;' ${file}
        sed -i 's/__ENTITY__/1/g;' ${file}
        mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} < ${file} >> /var/www/documents/initdb.log 2>&1
      elif [ "$isExec" == "PHP" ] ; then
        php $file
      elif [ "$isExec" == "SH" ] ; then
        /bin/bash $file
      fi
    done
  fi
}


# Function called to initialize the database (creation of database tables and init data)
function initializeDatabase()
{
  for fileSQL in /var/www/html/install/mysql/tables/*.sql; do
    if [[ ${fileSQL} != *.key.sql ]]; then
      echo "Importing table from `basename ${fileSQL}` ..."
      echo "Importing table from `basename ${fileSQL}` ..." >> /var/www/documents/initdb.log
      sed -i 's/--.*//g;' ${fileSQL} 	# remove all comment because comments into create sql crash the load
      mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} < ${fileSQL} >> /var/www/documents/initdb.log 2>&1
    fi
  done

  for fileSQL in /var/www/html/install/mysql/tables/*.key.sql; do
    echo "Importing table key from `basename ${fileSQL}` ..."
    echo "Importing table key from `basename ${fileSQL}` ..." >> /var/www/documents/initdb.log
    sed -i 's/^--.*//g;' ${fileSQL}
    mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} < ${fileSQL} >> /var/www/documents/initdb.log 2>&1
  done

  for fileSQL in /var/www/html/install/mysql/functions/*.sql; do
    echo "Importing `basename ${fileSQL}` ..."
    echo "Importing `basename ${fileSQL}` ..." >> /var/www/documents/initdb.log
    sed -i 's/^--.*//g;' ${fileSQL}
    mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} < ${fileSQL} >> /var/www/documents/initdb.log 2>&1
  done

  for fileSQL in /var/www/html/install/mysql/data/*.sql; do
    if [[ $fileSQL =~ llx_accounting_account_ ]]; then
    	echo "Do not import data from `basename ${fileSQL}` ..."
        continue
    fi
    echo "Importing data from `basename ${fileSQL}` ..."
    echo "Importing data from `basename ${fileSQL}` ..." >> /var/www/documents/initdb.log
    sed -i 's/^--.*//g;' ${fileSQL}
    sed -i 's/__ENTITY__/1/g;' ${fileSQL}
    mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} < ${fileSQL} >> /var/www/documents/initdb.log 2>&1
  done

  echo "Set some default const ..."
  echo "Set some default const ..." >> /var/www/documents/initdb.log
  mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "DELETE FROM llx_const WHERE name='MAIN_VERSION_LAST_INSTALL';" >> /var/www/documents/initdb.log 2>&1
  mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "DELETE FROM llx_const WHERE name='MAIN_NOT_INSTALLED';" >> /var/www/documents/initdb.log 2>&1
  mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "DELETE FROM llx_const WHERE name='MAIN_LANG_DEFAULT';" >> /var/www/documents/initdb.log 2>&1
  mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "INSERT INTO llx_const(name,value,type,visible,note,entity) VALUES ('MAIN_VERSION_LAST_INSTALL', '${DOLI_VERSION}', 'chaine', 0, 'Dolibarr version when install', 0);" >> /var/www/documents/initdb.log 2>&1
  mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "INSERT INTO llx_const(name,value,type,visible,note,entity) VALUES ('MAIN_LANG_DEFAULT', 'auto', 'chaine', 0, 'Default language', 1);" >> /var/www/documents/initdb.log 2>&1
  mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "INSERT INTO llx_const(name,value,type,visible,note,entity) VALUES ('SYSTEMTOOLS_MYSQLDUMP', '/usr/bin/mysqldump', 'chaine', 0, '', 0);" >> /var/www/documents/initdb.log 2>&1

  if [[ ${DOLI_INIT_DEMO} -eq 1 ]]; then
    mkdir -p /var/www/dev/initdemo/

	echo "DOLI_VERSION=$DOLI_VERSION"     

	# Set DOLI_TAG to a number "x.y", even if value is "develop"
	DOLI_TAG=${DOLI_VERSION}
    if [ ${DOLI_TAG} == "develop" ]; then
    	echo "DOLI_TAG is develop that does not exists, so we will use the github demo file for version ${DOLI_VERSION_FOR_INIT_DEMO}"
	    DOLI_TAG="${DOLI_VERSION_FOR_INIT_DEMO}"
	fi 

    # Convert version x.y.z into x.y.0
    versiondemo=`echo "${DOLI_TAG}" | sed "s/^\([0-9]*\.[0-9]*\).*/\1.0/"`		# Convert vesion x.y.z into x.y.0 

    echo "Get demo data with: curl -fLSs -o /var/www/dev/initdemo/initdemo.sql https://raw.githubusercontent.com/Dolibarr/dolibarr/${DOLI_TAG}/dev/initdemo/mysqldump_dolibarr_$versiondemo.sql"
    curl -fLSs -o /var/www/dev/initdemo/initdemo.sql https://raw.githubusercontent.com/Dolibarr/dolibarr/${DOLI_TAG}/dev/initdemo/mysqldump_dolibarr_$versiondemo.sql
    if [ $? -ne 0 ]; then
		echo "ERROR: failed to get the online init demo file. No demo init will be done."
	else   
	    for fileSQL in /var/www/dev/initdemo/*.sql; do
	    	echo "Found demo data file, so we first drop tables llx_accounting_xxx ..."
	    	echo "mysql -u ${DOLI_DB_USER} -pxxxxxxx -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e \"DROP TABLE llx_accounting_account\" >> /var/www/documents/initdb.log 2>&1"
	    	mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "DROP TABLE llx_accounting_account" >> /var/www/documents/initdb.log 2>&1
	    	echo "mysql -u ${DOLI_DB_USER} -pxxxxxxx -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e \"DROP TABLE llx_accounting_system\" >> /var/www/documents/initdb.log 2>&1"
	    	mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "DROP TABLE llx_accounting_system" >> /var/www/documents/initdb.log 2>&1
	  		
	  		echo "Then we load demo data ${fileSQL} ..."
	  		echo "Then we load demo data ${fileSQL} ..." >> /var/www/documents/initdb.log
	        sed -i 's/\/\*!999999\\- enable the sandbox mode \*\///g;' ${fileSQL}
	        echo "mysql -u ${DOLI_DB_USER} -pxxxxxxx -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} < ${fileSQL} >> /var/www/documents/initdb.log 2>&1"
	        echo "mysql -u ${DOLI_DB_USER} -pxxxxxxx -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} < ${fileSQL} >> /var/www/documents/initdb.log 2>&1" >> /var/www/documents/initdb.log
	    	mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} < ${fileSQL} >> /var/www/documents/initdb.log 2>&1
	    done
	fi
  else
    echo "DOLI_INIT_DEMO is off. No demo data load to do."
    echo "DOLI_INIT_DEMO is off. No demo data load to do." >> /var/www/documents/initdb.log
  fi

  echo "Create SuperAdmin account ..."
  echo "Create SuperAdmin account ..." >> /var/www/documents/initdb.log
  pass_crypted=`echo -n ${DOLI_ADMIN_PASSWORD} | md5sum | awk '{print $1}'`
  #pass_crypted2=`php -r "echo password_hash(${DOLI_ADMIN_PASSWORD}, PASSWORD_BCRYPT);"`
  
  # Insert may fails if record already exists
  mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "INSERT INTO llx_user (entity, login, pass_crypted, lastname, admin, statut) VALUES (0, '${DOLI_ADMIN_LOGIN}', '${pass_crypted}', 'SuperAdmin', 1, 1);" >> /var/www/documents/initdb.log 2>&1
  # Insert may fails if record already exists
  mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "UPDATE llx_user SET pass_crypted = '${pass_crypted}' WHERE login = '${DOLI_ADMIN_LOGIN}';" >> /var/www/documents/initdb.log 2>&1

  echo "Enable user module ..."
  echo "Enable user module ..." >> /var/www/documents/initdb.log
  php /var/www/scripts/docker-init.php

  # Run init scripts
  echo "Run scripts into docker-init.d if there is ..."
  echo "Run scripts into docker-init.d if there is ..." >> /var/www/documents/initdb.log
  runScripts "docker-init.d"

  # Update ownership after initialisation of modules
  chown -R www-data:www-data /var/www/documents
}


# Migrate database to the new version
function migrateDatabase()
{
  TARGET_VERSION="$(echo ${DOLI_VERSION} | cut -d. -f1).$(echo ${DOLI_VERSION} | cut -d. -f2).0"
  echo "Dumping Database into /var/www/documents/backup-before-upgrade.sql ..."

  mysqldump -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} > /var/www/documents/backup-before-upgrade.sql
  r=${?}
  if [[ ${r} -ne 0 ]]; then
    echo "Dump failed ... Aborting migration ..."
    return ${r}
  fi
  echo "Dump done ... Starting Migration ..."

  echo "Create unlock file with: touch /var/www/documents/upgrade.unlock"
  touch /var/www/documents/upgrade.unlock
   
  > /var/www/documents/migration_error.html
  pushd /var/www/htdocs/install > /dev/null
  php upgrade.php ${INSTALLED_VERSION} ${TARGET_VERSION} >> /var/www/documents/migration_error.html 2>&1 && \
  php upgrade2.php ${INSTALLED_VERSION} ${TARGET_VERSION} >> /var/www/documents/migration_error.html 2>&1 && \
  php step5.php ${INSTALLED_VERSION} ${TARGET_VERSION} >> /var/www/documents/migration_error.html 2>&1
  r=$?
  popd > /dev/null

  echo "Remove unlock file with: rm -f /var/www/documents/upgrade.unlock"
  rm -f /var/www/documents/upgrade.unlock

  if [[ ${r} -ne 0 ]]; then
    echo "Migration failed ... Restoring DB ... check file /var/www/documents/migration_error.html for more info on error ..."
    mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} < /var/www/documents/backup-before-upgrade.sql
    echo "DB Restored ..."
    return ${r}
  else
    echo "Migration successful ... Enjoy !"
  fi

  return 0
}


function run()
{
  > /var/www/documents/initdb.log 2>&1
 
  initDolibarr
  echo "Current Version is : ${DOLI_VERSION}"

  # If install of mysql database (and not install of cron) is requested
  if [[ ${DOLI_INSTALL_AUTO} -eq 1 && ${DOLI_CRON} -ne 1 && ${DOLI_DB_TYPE} != "pgsql" ]]; then
    echo "DOLI_INSTALL_AUTO is on, so we check to initialize or upgrade mariadb database"

    waitForDataBase

	# Check if DB exists (even if empty)
	DB_EXISTS=0
	echo "mysql -u ${DOLI_DB_USER} -pxxxxxx -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} -e \"SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = '${DOLI_DB_NAME}';\" > /tmp/docker-run-checkdb.result 2>&1" >> /var/www/documents/initdb.log 2>&1
	mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} -e "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = '${DOLI_DB_NAME}';" > /tmp/docker-run-checkdb.result 2>&1
    r=$?
    if [[ ${r} -eq 0 ]]; then
		DB_EXISTS=`grep ${DOLI_DB_NAME} /tmp/docker-run-checkdb.result`
	fi
	echo "DB Exists is : ${DB_EXISTS}" >> /var/www/documents/initdb.log 2>&1 
    echo "DB Exists is : ${DB_EXISTS}"

	if [[ ! -f /var/www/documents/install.lock ]]; then
		echo "Install.lock Exists is : no" >> /var/www/documents/initdb.log 2>&1 
    	echo "Install.lock Exists is : no"
	else
		echo "Install.lock Exists is : yes" >> /var/www/documents/initdb.log 2>&1 
    	echo "Install.lock Exists is : yes"
	fi

    # If install.lock does not exists, or if db does not exists, we launch the initializeDatabase, then upgrade if required.
    if [[ ! -f /var/www/documents/install.lock || "${DB_EXISTS}" = "" ]]; then
		echo "mysql -u ${DOLI_DB_USER} -pxxxxxx -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e \"SELECT Q.LAST_INSTALLED_VERSION FROM (SELECT INET_ATON(CONCAT(value, REPEAT('.0', 3 - CHAR_LENGTH(value) + CHAR_LENGTH(REPLACE(value, '.', ''))))) as VERSION_ATON, value as LAST_INSTALLED_VERSION FROM llx_const WHERE name IN ('MAIN_VERSION_LAST_INSTALL', 'MAIN_VERSION_LAST_UPGRADE') and entity=0) Q ORDER BY VERSION_ATON DESC LIMIT 1\" > /tmp/docker-run-lastinstall.result 2>&1" >> /var/www/documents/initdb.log 2>&1
		mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "SELECT Q.LAST_INSTALLED_VERSION FROM (SELECT INET_ATON(CONCAT(value, REPEAT('.0', 3 - CHAR_LENGTH(value) + CHAR_LENGTH(REPLACE(value, '.', ''))))) as VERSION_ATON, value as LAST_INSTALLED_VERSION FROM llx_const WHERE name IN ('MAIN_VERSION_LAST_INSTALL', 'MAIN_VERSION_LAST_UPGRADE') and entity=0) Q ORDER BY VERSION_ATON DESC LIMIT 1" > /tmp/docker-run-lastinstall.result 2>&1
		r=$?
		if [[ ${r} -ne 0 ]]; then
			# If test fails, it means tables does not exists, so we create them
			echo "No table found, we launch initializeDatabase" >> /var/www/documents/initdb.log 2>&1 
    		echo "No table found, we launch initializeDatabase"

			initializeDatabase

			# Regenerate the /tmp/docker-run-lastinstall.result 
			echo "mysql -u ${DOLI_DB_USER} -pxxxxxx -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e \"SELECT Q.LAST_INSTALLED_VERSION FROM (SELECT INET_ATON(CONCAT(value, REPEAT('.0', 3 - CHAR_LENGTH(value) + CHAR_LENGTH(REPLACE(value, '.', ''))))) as VERSION_ATON, value as LAST_INSTALLED_VERSION FROM llx_const WHERE name IN ('MAIN_VERSION_LAST_INSTALL', 'MAIN_VERSION_LAST_UPGRADE') and entity=0) Q ORDER BY VERSION_ATON DESC LIMIT 1\" > /tmp/docker-run-lastinstall.result 2>&1" >> /var/www/documents/initdb.log 2>&1
			mysql -u ${DOLI_DB_USER} -p${DOLI_DB_PASSWORD} -h ${DOLI_DB_HOST} -P ${DOLI_DB_HOST_PORT} ${DOLI_DB_NAME} -e "SELECT Q.LAST_INSTALLED_VERSION FROM (SELECT INET_ATON(CONCAT(value, REPEAT('.0', 3 - CHAR_LENGTH(value) + CHAR_LENGTH(REPLACE(value, '.', ''))))) as VERSION_ATON, value as LAST_INSTALLED_VERSION FROM llx_const WHERE name IN ('MAIN_VERSION_LAST_INSTALL', 'MAIN_VERSION_LAST_UPGRADE') and entity=0) Q ORDER BY VERSION_ATON DESC LIMIT 1" > /tmp/docker-run-lastinstall.result 2>&1
	  	fi

	  	# Now database exists. Do we have to upgrade it ?
	  	if [ -f /tmp/docker-run-lastinstall.result ]; then
			INSTALLED_VERSION=`grep -v LAST_INSTALLED_VERSION /tmp/docker-run-lastinstall.result`
			echo "Database Version is : ${INSTALLED_VERSION}"
			echo "Files Version are   : ${DOLI_VERSION}"

			if [[ ${DOLI_VERSION} != "develop" ]]; then
				# Test if x in INSTALLED_VERSION is lower than X of DOLI_VERSION (in x.y.z)
				if [[ "$(echo ${INSTALLED_VERSION} | cut -d. -f1)" -lt "$(echo ${DOLI_VERSION} | cut -d. -f1)" ]]; then
					echo "Database version is a major lower version, so we must run the upgrade process"
			   		migrateDatabase
			  	else
					# Test if y in INSTALLED_VERSION is lower than Y of DOLI_VERSION (in x.y.z)
					if [[ "$(echo ${INSTALLED_VERSION} | cut -d. -f1)" -eq "$(echo ${DOLI_VERSION} | cut -d. -f1)" && "$(echo ${INSTALLED_VERSION} | cut -d. -f2)" -lt "$(echo ${DOLI_VERSION} | cut -d. -f2)" ]]; then
						echo "Database version is a middle lower version, so we must run the upgrade process"
						migrateDatabase
					else
						# Test if z in INSTALLED_VERSION is lower than Z of DOLI_VERSION (in x.y.z)
						if [[ "$(echo ${INSTALLED_VERSION} | cut -d. -f1)" -eq "$(echo ${DOLI_VERSION} | cut -d. -f1)" && "$(echo ${INSTALLED_VERSION} | cut -d. -f2)" -eq "$(echo ${DOLI_VERSION} | cut -d. -f2)" && "$(echo ${INSTALLED_VERSION} | cut -d. -f3)" -lt "$(echo ${DOLI_VERSION} | cut -d. -f3)" ]]; then
						   	echo "Database version is a minor lower version, so we must run the upgrade process"
							migrateDatabase
						else
							echo "Schema update is not required ... Enjoy !"
						fi
					fi
				fi

	        	lockInstallation
	        else
	        	# Create the upgrade.unlock file to allow upgrade for develop
	        	echo "Create the file to allow upgrade with: touch /var/www/documents/upgrade.unlock"  
	        	touch /var/www/documents/upgrade.unlock
			fi
		fi
    else
		echo "File /var/www/documents/install.lock exists and database exists so we cancel database init"
    fi
  fi

  # Run scripts before starting
  runScripts "before-starting.d"

  local CURRENT_UID=$(id -u www-data)
  local CURRENT_GID=$(id -g www-data)
  usermod -u ${WWW_USER_ID} www-data
  groupmod -g ${WWW_GROUP_ID} www-data

  if [[ ${CURRENT_UID} -ne ${WWW_USER_ID} || ${CURRENT_GID} -ne ${WWW_GROUP_ID} ]]; then
    # Refresh file ownership cause it has changed
    echo "[INIT] => As UID / GID have changed from default, update ownership for files in /var/ww ..."
    chown -R www-data:www-data /var/www
  else
    # Reducing load on init : change ownership only for volumes declared in docker
    echo "[INIT] => update ownership for files in /var/www/documents ..."
    chown -R www-data:www-data /var/www/documents
  fi

  echo "*** You can connect to the docker Mariadb with:"
  echo "sudo docker exec -it nameofmariadbcontainer bash"
  echo "mysql -uroot -p'MYSQL_ROOT_PASSWORD' -h localhost"
  echo "ls /var/lib/mysql"
  echo
  echo "*** You can connect to the docker Dolibarr with:"
  echo "sudo docker exec -it nameofwebcontainer bash"
  echo "ls /var/www/documents"
  echo "ls /var/www/html"
  echo
  echo "*** You can access persistent directory from the host with:"
  echo "ls /home/dolibarr_mariadb_latest"
  echo "ls /home/dolibarr_documents_latest"
  echo "ls /home/dolibarr_custom_latest"
  echo
  echo "*** You can connect to your Dolibarr web application with:"
  echo "http://127.0.0.1:port"
}



# main script 

echo "docker-run.sh started"

DOLI_DB_USER=$(get_env_value 'DOLI_DB_USER' 'dolidbuser')
DOLI_DB_PASSWORD=$(get_env_value 'DOLI_DB_PASSWORD' 'dolidbpass')
DOLI_ADMIN_LOGIN=$(get_env_value 'DOLI_ADMIN_LOGIN' 'admin')
DOLI_ADMIN_PASSWORD=$(get_env_value 'DOLI_ADMIN_PASSWORD' 'admin')
DOLI_CRON_KEY=$(get_env_value 'DOLI_CRON_KEY' '')
DOLI_CRON_USER=$(get_env_value 'DOLI_CRON_USER' '')
DOLI_INSTANCE_UNIQUE_ID=$(get_env_value 'DOLI_INSTANCE_UNIQUE_ID' '')

# Launch the run function
run

set -e

if [[ ${DOLI_CRON} -eq 1 ]]; then
    echo "PATH=\$PATH:/usr/local/bin" > /etc/cron.d/dolibarr
    echo "*/5 * * * * root /bin/su www-data -s /bin/sh -c '/var/www/scripts/cron/cron_run_jobs.php ${DOLI_CRON_KEY} ${DOLI_CRON_USER}' > /proc/1/fd/1 2> /proc/1/fd/2" >> /etc/cron.d/dolibarr
    cron -f
    exit 0
fi

if [ "${1#-}" != "$1" ]; then
  set -- apache2-foreground "$@"
fi

exec "$@"

echo "docker-run.sh stopped."
