#!/bin/bash
# Source env variable
source ../../configs/.env

echo 'Reading db connection details from profile'
export PGHOST=${PGHOST}
export PGPORT=${PGPORT}
export PGDATABASE=${PGDATABASE}
export POSTGRES_USER=${POSTGRES_USER}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

export LOCAL_RAW=${LOCAL_RAW}
export LOCAL_CLEAN=${LOCAL_CLEAN}

echo 'Creating schemas...'
#PGPASSWORD=$POSTGRES_PASSWORD psql -h $PGHOST -U $POSTGRES_USER -d $PGDATABASE -c "CREATE SCHEMA IF NOT EXISTS organizaciones_civiles;"

echo 'Downloading SAT donatarias table'
## 2017
#wget -O "$LOCAL_RAW/sat_donatarias_2017.xls" http://www.sat.gob.mx/terceros_autorizados/donatarias_donaciones/Documents/dir171.xls
## 2015
#wget -O "$LOCAL_RAW/sat_donatarias_2015.xls" http://www.sat.gob.mx/terceros_autorizados/donatarias_donaciones/Documents/ddas15final.xls
## 2014
#wget -O "$LOCAL_RAW/sat_donatarias_2014.xls" http://www.sat.gob.mx/terceros_autorizados/donatarias_donaciones/Documents/das1421515.xls


echo 'to csv'
in2csv --no-inference "$LOCAL_RAW/sat_donatarias_2017.xls" | tail -n +31  > "$LOCAL_RAW/sat_donatarias_2017.csv"
in2csv --no-inference "$LOCAL_RAW/sat_donatarias_2015.xls" | tail -n +31  > "$LOCAL_RAW/sat_donatarias_2015.csv"
in2csv --no-inference "$LOCAL_RAW/sat_donatarias_2014.xls" | tail -n +31  > "$LOCAL_RAW/sat_donatarias_2014.csv"

echo 'clean'
python3 etl/clean_sat_donatarias.py

echo 'Generate create statement'
csvsql -i postgresql --db-schema organizaciones_civiles --table sat_donatarias -d ',' -e 'utf-8' "$LOCAL_CLEAN/sat_donatarias_clean.csv" > "$LOCAL_CLEAN/sat_donatarias.sql"

echo 'Create table'
PGPASSWORD=$POSTGRES_PASSWORD psql -h $PGHOST -U $POSTGRES_USER -d $PGDATABASE < "$LOCAL_CLEAN/sat_donatarias.sql"

echo 'Populate table'
PGPASSWORD=$POSTGRES_PASSWORD psql -h $PGHOST -U $POSTGRES_USER -d $PGDATABASE -c "\COPY organizaciones_civiles.sat_donatarias FROM $LOCAL_CLEAN/sat_donatarias_clean.csv WITH CSV HEADER DELIMITER AS ',';"
