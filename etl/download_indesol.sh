#!/bin/bash
# Source env variable
source ../../configs/.env

echo 'Reading db connection details from profile'

export PGHOST=${PGHOST}
export PGPORT=${PGPORT}
export PGDATABASE=${PGDATABASE}
export POSTGRES_USER=${POSTGRES_USER}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

export LOCAL_DIR=${LOCAL_DIR}

echo 'Creating schemas...'
PGPASSWORD=$POSTGRES_PASSWORD psql -h $PGHOST -U $POSTGRES_USER -d $PGDATABASE -c "CREATE SCHEMA IF NOT EXISTS organizaciones_civiles;"  

echo 'Downloading Indesol table'
wget -O "$LOCAL_DIR/indesol.csv" http://166.78.45.36/portal/organizaciones/excel/?cluni=&nombre=&acronimo=&rfc=&status_osc=&status_sancion=&figura_juridica=&estado=&municipio=&asentamiento=&cp=&rep_nombre=&rep_apaterno=&rep_amaterno=&num_notaria=&objeto_social=&red=&advanced=

echo 'Clean'
csvclean -d ',' -e  "$LOCAL_DIR/indesol.csv" 
sed  "s/,,/,NA,/g; s/^,/NA,/g; s/,$/,NA/g; s/^N\/A,,/NA,/g; s/,N\/A,/,NA,/g; s/,N\/A$/,NA/g;" $LOCAL_DIR/indesol_out.csv > $LOCAL_DIR/indesol_out_clean.csv

echo 'Generate create statement'
csvsql -i postgresql --db-schema organizaciones_civiles --table indesol -d ',' -e 'utf-8' "$LOCAL_DIR/indesol_out_clean.csv" > "$LOCAL_DIR/indesol.sql"

echo 'Create table'
#PGPASSWORD=$POSTGRES_PASSWORD psql -h $PGHOST -U $POSTGRES_USER -d $PGDATABASE < "$LOCAL_DIR/indesol.sql"

echo 'Populate table'
#PGPASSWORD=$POSTGRES_PASSWORD psql -h $PGHOST -U $POSTGRES_USER -d $PGDATABASE -c "\COPY organizaciones_civiles.indesol FROM $LOCAL_DIR/indesol_out_clean.csv WITH CSV HEADER DELIMITER AS ',' NULL 'NA';"

