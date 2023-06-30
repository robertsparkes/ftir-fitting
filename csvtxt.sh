#!/bin/bash

echo $# files

while :
do
if [[ "$#" > "0" ]]
then 
filename=$1
#nicename=${1}b
nicename=${filename%\.*}
awk ' BEGIN {FS = ","; OFS = " "} { print $1 * 1, $2 * 1 } ' $filename > ${nicename}.txt
#awk ' BEGIN {FS = ","; OFS = " "} { print $1 +0, $2 +0 } ' $filename > $nicename

shift

else 
#rm *.txt
#mmv '*.txtb' '#1.txt'
mkdir CSV
mv *.CSV CSV
mv *.csv CSV
echo "Done"

exit
fi
done


