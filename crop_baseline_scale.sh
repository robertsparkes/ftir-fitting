mkdir crop_scaled
mkdir full_sized
xmin=555.5
xmax=1800

echo $# files to adjust

while :
do

if [[ "$#" > "0" ]]
then 
#ymin=`awk 'BEGIN { min = 1000000 } (($1 > ('$xmin') && ($1 < '$xmax'))) { if ( min > $2 ) min = $2 } END { print min }' $1`
#echo Minimum = $ymin
#`awk 'BEGIN { min = '$ymin' }  ( $1 > 100 ) && ( $1 < 1800 ) { print $1, ($2 - min) } ' $1 > baseline/${1}`


ymin=`awk 'BEGIN { min = 1000000 } (($1 > ('$xmin') && ($1 < '$xmax'))) { if ( min > $2 ) min = $2 } END { print min }' $1`
echo Minimum = ${ymin}
`awk 'BEGIN { min = '$ymin'}  ( $1 > '$xmin' ) && ( $1 < '$xmax' ) { print $1, ($2 - min) } ' $1 > zero_${1}`

ymax=`awk 'BEGIN { max = -1000000 } (($1 > ('$xmin') && ($1 < '$xmax'))) { if ( max < $2 ) max = $2 } END { print max }' zero_$1`
echo Maximum = ${ymax}
`awk 'BEGIN { max = '$ymax'}  ( $1 > '$xmin' ) && ( $1 < '$xmax' ) { print $1, ($2 * 100 / max) } ' zero_$1 > crop_scaled/${1}`

mv ${1} full_sized

shift


else
rm zero_*.txt
echo finish
exit
fi
done
