#!/bin/bash
set -e

# For debug purposes only
: ${ENV_SECRETS_DEBUG:=1}

################################################################################################################
#
# Convert Docker secrets to env vars so this script works
#
################################################################################################################
: ${ENV_SECRETS_DIR:=/run/secrets}

env_secret_debug()
{
    if [ ! -z "$ENV_SECRETS_DEBUG" ]; then
        echo -e "\033[1m$@\033[0m"
    fi
}

# usage: env_secret_expand SECRET_NAME ENVIRONMENT_VARIABLE
#    ie: env_secret_expand 'DB_USER_PASSWORD' 'MYSQL_USER'

# (will check for "$XYZ_DB_PASSWORD" variable value for a placeholder that defines the
#  name of the docker secret to use instead of the original value. For example:
# XYZ_DB_PASSWORD={{DOCKER-SECRET:my-db.secret}}

env_secret_expand() {
    var="$1"
	env_var="$2"
    eval val=\$$var
    if secret_name=$(expr match "$val" "{{DOCKER-SECRET:\([^}]\+\)}}$"); then
        secret="${ENV_SECRETS_DIR}/${secret_name}"
        env_secret_debug "Secret file for $env_var: $secret"
        if [ -f "$secret" ]; then
            val=$(cat "${secret}")
            export "$env_var"="$val"
            env_secret_debug "Expanded variable: $env_var=$val"
        else
            env_secret_debug "Secret file does not exist! $secret"
        fi
    fi
}

# env_secrets_expand() {
#     for env_var in $(printenv | cut -f1 -d"=")
#     do
#         env_secret_expand $env_var
#     done

#     if [ ! -z "$ENV_SECRETS_DEBUG" ]; then
#         echo -e "\n\033[1mExpanded environment variables\033[0m"
#         printenv
#     fi
# }

#env_secrets_expand
env_secret_expand db_user MYSQL_USER
env_secret_expand db_user_password MYSQL_PASSWORD





################################################################################################################
#
# Execute the shell scripts to create the MYSQL cluster and setup the initial table
#
################################################################################################################
if [ "$1" = 'mysqlsh' ]; then

    if [[ -z $MYSQL_HOST || -z $MYSQL_PORT || -z $MYSQL_USER || -z $MYSQL_PASSWORD ]]; then
	    echo "We require all of"
	    echo "    MYSQL_HOST"
	    echo "    MYSQL_PORT"
	    echo "    MYSQL_USER"
	    echo "    MYSQL_PASSWORD"
	    echo "to be set. Exiting."
	    exit 1
    fi
    max_tries=12
    attempt_num=0
    until (echo > "/dev/tcp/$MYSQL_HOST/$MYSQL_PORT") >/dev/null 2>&1; do
	    echo "Waiting for mysql server $MYSQL_HOST ($attempt_num/$max_tries)"
	    sleep $(( attempt_num++ ))
	    if (( attempt_num == max_tries )); then
		    exit 1
	    fi
    done
    if [ "$MYSQLSH_SCRIPT" ]; then
	mysqlsh "$MYSQL_USER@$MYSQL_HOST:$MYSQL_PORT" --dbpassword="$MYSQL_PASSWORD" -f "$MYSQLSH_SCRIPT" || true
    fi
    if [ "$MYSQL_SCRIPT" ]; then
	mysqlsh "$MYSQL_USER@$MYSQL_HOST:$MYSQL_PORT" --dbpassword="$MYSQL_PASSWORD" --sql -f "$MYSQL_SCRIPT" || true
    fi
    exit 0
fi

exec "$@"