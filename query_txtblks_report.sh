#!/usr/bin/env bash

# Queries text blocks and outputs them to html in shared google drive folder
# Gets input from multiple csv files in folder, passing report_id to the plpgsql

FILES=./data/lv1_data_cik_el/*
OLDIFS=$IFS
IFS=,
for f in ./data/lv1_data_cik_el/lv1_cik_el_V_report.csv # ./data/lv1_data_cik_el/lv1_cik_el_G_report.csv# $FILES
do
    echo "*** Processing $f ***"
    [ ! -f $f ] && { echo "$f file not found"; exit 99; }
    while read cik elname report
    do
        output=./data/level_1_html_2017/$cik-$elname.html
        echo "...querying report - $cik for $elname..."
    #    echo $output
    #    touch $output
        /Library/PostgreSQL/9.6/bin/psql -h rltest.markv.com -p8084 -d debug3_db -U postgres -q -c 'COPY (SELECT * FROM get_txtblks_report ('$report', '\'$elname\'') AS t(value text)) TO STDOUT;' > /tmp/unpro.html
        # delete the file if size is zero, otherwise process
        if [ ! -s /tmp/unpro.html ] ; then
            rm /tmp/unpro.html
        else
            sed -e 's/\\t//g' -e 's/\\n//g' -e 's/\\r//g' /tmp/unpro.html > $output
        fi
    done < $f
done
echo '** DONE **'
# ls -1 ./data/level_1_html_2017 | wc -l
# find ./data/level_1_html_2017 -size 0 -delete
# ls -1 ./data/level_1_html_2017 | wc -l
IFS=$OLDIFS

# complete: A, B, C, D, E, F, G, I, L, M, N, O, P, Q, R, S, T, U, V