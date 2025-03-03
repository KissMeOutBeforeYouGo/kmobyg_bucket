#!/usr/bin/env bash

####################
# Andrey Fomin <andreyafomin@icloud.com>
####################
# BEFORE PROCEEDING, NOTE:
# 
# This script requires 2 additional environment variables that aren't set by default:
# (1) POSTGRES_PASSWORD - password that will be used by default (it's assumed that you'll change it later manually)
# (2) POSTGRES_DATA_DIR - filesystem path where postgres data will be stored. Since you can't run some commands like pg_ctl as root, 
#   it's assumed that you've set up unprivileged user and it has rw capabilities for this directory.
# 
# This script demonstrates simplest way to bootsrap/run fully functional postgresql instance inside the container.
# Mind that there is still a lot of configuration to do in order to make it production-ready.

set -e

POSTGRES_INIT_DONE_FILE="$POSTGRES_DATA_DIR/postgresql.conf"

run_postgres() {
    postgres -c data_directory=$POSTGRES_DATA_DIR \
    -c hba_file=$POSTGRES_DATA_DIR/pg_hba.conf \
    -c ident_file=$POSTGRES_DATA_DIR/pg_ident.conf \
    -c listen_addresses='*' -D $POSTGRES_DATA_DIR
}

if [ ! -e $POSTGRES_INIT_DONE_FILE ]; then

    echo $POSTGRES_PASSWORD > /home/postgres/passwd
    initdb -D $POSTGRES_DATA_DIR -E UTF8 --pwfile=/home/postgres/passwd
    rm /home/postgres/passwd
    pg_ctl -D $POSTGRES_DATA_DIR start
    psql -c 'create database "CSS_PLANTS"'
    pg_restore -d CSS_PLANTS /home/postgres/css_db.template.${SIV_RELEASE_TAG}
    pg_ctl -D $POSTGRES_DATA_DIR  stop

    printf "local all all trust\n host all all all md5" \
    > $POSTGRES_DATA_DIR/pg_hba.conf
    run_postgres
else
    run_postgres
fi
