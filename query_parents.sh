#!/usr/bin/env bash

# queries income statement element names and parent relationships and writes to file

INPUT="$1"
OLDIFS=$IFS
IFS=,
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
while read report tcode
do
    output=./data/lv1_relations/lv1_relations_$tcode.csv
    echo "...querying $report for $tcode..."
    /Library/PostgreSQL/9.6/bin/psql -h rltest.markv.com -p8084 -d debug3_db -U postgres -q -c \
    'COPY (SELECT * FROM get_parents_is_cf_ci ('$report', '\'$tcode\'') AS
    t(table_code character varying, company_name text, cik character varying(30), url_hyperlink text, sic integer,
    name character varying(1024), line_item_description text, source text,
    amount text, period_end date, period_start date,
    parent_name character varying(1024), parent_line_item_description text)) TO STDOUT WITH CSV;' >> $output
done < $INPUT
echo "** DONE **"
IFS=$OLDIFS