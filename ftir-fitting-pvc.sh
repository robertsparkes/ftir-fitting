#!/bin/bash

###################################### Description #################################################
#
# This script analyses FTIR spectra of PVC, by fitting Voigt distributions to nine peaks, 
# as well as correcting for a linear background.
# The input is taken from a series of text files as produced by a Renishaw Raman spectrometer using
# Wire software. Proprietary .wxd files can be converted into two-column space-separated text files 
# (wavenumber intensity) using the "Wire Batch Convert" program. The text files should be contained 
# within one single folder, or grouped into sub-folders.
#
# The script outputs three graphs, containing the raw spectra with linear background identified,
# raw spectra with overalll fit superimposed and a residual shown, and the spectra following the fitting,
# showing the fitted peaks after the background has been removed. The fitting parameters (peak locations,
# amplitudes, widths and areas, as well as characteristic area ratios) are outputted to a summary file 
# for further analysis
#
# The script requires the following software to run:
# - A Unix / Linux environment (tested with Ubuntu)
# - Bash terminal program
# - Dos2unix text file conversion software
# - Gnuplot graphing software. 
#     - Version 4.5 or above is required
# - Ghostscript PostScript and PDF manipulation software
# - The script "prepraman.sh" should be run before the first files in a given folder are analysed.
#   This script creates folders and initiates some datafiles for the subsequent fits
# - Both this fitting script and "prepraman.sh" require permission to execute as programs
#
# The script executes from the command line, in the form
# $ sparkesfitraman.sh [options] [input files]
#
# The options are
# -q Quiet mode - graphs appear on screen but immediately disappear
# -d Delete - removes previous files from "acombinedresults.txt"

#
# Input files can be listed individually, or selected all at once using a wildcard (e.g. *.txt)
# After analysis the results are written to a file entitled "acombinedresults.txt". Any filename
# already in this file will be ignored and not re-fitted, hence the delete option.
#
# Example code to prepare for and then analyse all samples with "taiwan" in the file name:
# $ prepraman.sh 
# $ sparkesfitraman.sh -d -q -t 5 taiwan*.txt
#
#
##################################################################################################


# First the options are collected


quiet=false
persist=-persist
delete=false
delans=n

while getopts 'dq' option
do
case $option in
	d) delete=true;;
	q) quiet=true;;

esac
done
shift $(($OPTIND - 1))

if [ "$delete" = "true" ] ; then
	echo "Really delete all records? (y/n)"
	read delans
	if [ "$delans" = "y" ] ; then
		echo "name pvc_height carbonate_height dotp_height p4008_height pvc_perc carbonate_perc dotp_perc p4008_perc" > acombinedresults.txt

		echo "Records deleted!"
	else
		echo "Records saved!"	
	fi
fi

echo Quiet? $quiet

if [ "$quiet" = "true" ] ; then
persist=""
fi

echo $#
echo $@


########  This is the start of the main function    #################

function processsample {
#Prepare input file
filename=$1
dos2unix $filename
nicename=${filename%\.*}
echo $nicename

paste $filename FTIR_standards_scaled.txt > ${nicename}_std.txt

testname=${nicename}_std.txt


###### Test whether the sample has been processed before    ###############
outputresult=`awk 'match($1, '/$nicename/')' acombinedresults.txt`
if [ "$outputresult" = "" ]; 
then 

rm fit.log

############################ GNUPlot Curve Fitting  ###########################################

carbonate_loc=1414
carbonate_height=`awk 'BEGIN { max = -1000000000 } (($1 > ('$carbonate_loc' - 5) && ($1 < '$carbonate_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $testname`

pvc_loc=1257
pvc_height=`awk 'BEGIN { max = -1000000000 } (($1 > ('$pvc_loc' - 5) && ($1 < '$pvc_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $testname`

dotp_loc=1269
dotp_height=`awk 'BEGIN { max = -1000000000 } (($1 > ('$dotp_loc' - 5) && ($1 < '$dotp_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $testname`

p4008_loc=1540
p4008_height=`awk 'BEGIN { max = -1000000000 } (($1 > ('$p4008_loc' - 5) && ($1 < '$p4008_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $testname`


###### Report parameters to command line ##################
echo carbonate_loc = $carbonate_loc
echo carbonate_height = $carbonate_height

echo pvc_loc = $pvc_loc
echo pvc_height = $pvc_height

echo dotp_loc = $dotp_loc
echo dotp_height = $dotp_height

echo p4008_loc = $p4008_loc
echo p4008_height = $p4008_height


########### Enter parameters into fitting dataset #####################

########### Uncomment to use a floating background ###################
#echo grad = $grad > param.txt
#echo int = $yinit >> param.txt

#### Uncomment to use a flat, non moving background  ################
#echo bg = 0.01 > param.txt

#####################################################################

echo carbonate_height = $carbonate_height > param.txt
echo pvc_height = $pvc_height >> param.txt
echo dotp_height = $dotp_height >> param.txt
echo p4008_height = $p4008_height >> param.txt

#echo carbonate_height = 2 > param.txt
#echo pvc_height = 2 >> param.txt
#echo dotp_height = 3 >> param.txt
#echo p4008_height = 4 >> param.txt

gnuplot $persist<<EOF

load "param.txt"

carb(x) = sqrt(carbonate_height**2)*x
pvc(x) = sqrt(pvc_height**2)*x
dotp(x) = sqrt(dotp_height**2)*x
p4008(x) = sqrt(p4008_height**2)*x

set dummy a, b, c, d

f(a,b,c,d) = pvc(a)+carb(b)+dotp(c)+p4008(d)

# Perform the fit
FIT_LIMIT = 1e-12
FIT_MAXITER = 1000
fit f(a,b,c,d) '$testname' using 4:5:6:7:2 via 'param.txt'

save fit 'param_after.txt'

sum(a,b,c,d) = a+b+c+d
prop(a,b,c,d) = 100*a/(a+b+c+d)


############ Output data to text files



set table "data.xy"
plot [x=500:1850] '$testname' using 1:2

set table "residual.xy"
plot [x=500:1850] '$testname' using 1:(\$2-((carb(\$5))+(pvc(\$4))+(dotp(\$6))+(p4008(\$7))))

set table "carbonate_peaks.xy"
plot [x=500:1850] '$testname' using 1:(carb(\$5))

set table "pvc_peaks.xy"
plot [x=500:1850] '$testname' using 1:(pvc(\$4))

set table "dotp_peaks.xy"
plot [x=500:1850] '$testname' using 1:(dotp(\$6))

set table "p4008_peaks.xy"
plot [x=500:1850] '$testname' using 1:(p4008(\$7))

set table "fit.xy"
plot [x=500:1850] '$testname' using 1:((carb(\$5))+(pvc(\$4))+(dotp(\$6))+(p4008(\$7)))

unset table

plot [x=500:1850] 'fit.xy' with lines, 'data.xy' with dots, 'carbonate_peaks.xy' with lines, 'pvc_peaks.xy' with lines, 'dotp_peaks.xy' with lines, 'p4008_peaks.xy' with lines

set terminal pngcairo size 1600,1200
set output "peaks.png"
replot

set output "residual.png"
plot [x=500:1850] 'data.xy', 'residual.xy' with lines


set term post landscape color solid 8
set output 'combined.ps'

# Uncomment the following to line up the axes
# set lmargin 6

#set size ratio 1.5 1.5,1
set origin 0,0

set multiplot title '$charttitle'

set title "'$nicename' FTIR fitting with four ingredients"

set size 1,0.5
set origin 0,0.5
plot \
	[x=500:1850] 'fit.xy' title "Sum" with lines, \
	'data.xy' title "Data" with dots, \
	'carbonate_peaks.xy' title "Carbonate" with lines, \
	'pvc_peaks.xy' title "PVC" with lines, \
	'dotp_peaks.xy' title "DOTP" with lines, \
	'p4008_peaks.xy' with lines \
	title sprintf("\n\n\n\nP4008\nPVC = %.1f %%\nCarbonate = %.1f %%\nDOTP = %.1f %%\nP4008 = %.1f %%", \
	prop(pvc_height,carbonate_height,dotp_height,p4008_height),\
	prop(carbonate_height,pvc_height,dotp_height,p4008_height),\
	prop(dotp_height,pvc_height,carbonate_height,p4008_height),\
	prop(p4008_height,pvc_height,carbonate_height,dotp_height))

set title "Residual after subtraction of ingredients"

set size 1,0.5
set origin 0,0
plot [x=500:1850] 'data.xy' title "Data" with dots, 'residual.xy' title "Data - Fit" with lines

unset multiplot
reset

set print "percentages.txt"
print prop(pvc_height,carbonate_height,dotp_height,p4008_height),\
	prop(carbonate_height,pvc_height,dotp_height,p4008_height),\
	prop(dotp_height,pvc_height,carbonate_height,p4008_height),\
	prop(p4008_height,pvc_height,carbonate_height,dotp_height)

EOF

##### Extract heights 

pvc_height=`awk ' $1 ~ /pvc_height/ { print $3 } ' param_after.txt `
carbonate_height=`awk ' $1 ~ /carbonate_height/ { print $3 } ' param_after.txt `
dotp_height=`awk ' $1 ~ /dotp_height/ { print $3 } ' param_after.txt `
p4008_height=`awk ' $1 ~ /p4008_height/ { print $3 } ' param_after.txt `

pvc_perc=`awk ' { print $1 } ' percentages.txt `
carbonate_perc=`awk ' { print $2 } ' percentages.txt `
dotp_perc=`awk ' { print $3 } ' percentages.txt `
p4008_perc=`awk ' { print $4 } ' percentages.txt `


##### Remove scientific notation
#sed 's/e-/\*10\^-/' param_after.txt > ${1}_param_after.txt

##### Find final parameters ######
#pvc_1_loc=`awk ' $1 ~ /pvc_1_loc/ { print sqrt( $2 ^ 2 ) } ' param3.txt `
#pvc_1_height=`awk ' $1 ~ /pvc_1_height/ { print $2 } ' param3.txt `
#pvc_1_width=`awk ' $1 ~ /pvc_1_width/ { print $2 } ' param3.txt `
#pvc_1_area=`awk ' ( NR > 4) $1 ~ /pvc_1_area/ { print $2 } ' param3.txt `


ps2pdf combined.ps ${nicename}combined.pdf
rm combined.ps

mv peaks.png ${nicename}peaks_xy.png
mv bgremoved.png ${nicename}bgremoved_xy.png
mv residual.png ${nicename}residual_xy.png
mv param_after.txt ${nicename}_ftir_param.txt

mv data.xy ${nicename}data.xy
mv fit.xy  ${nicename}fit.xy

####### Send heights to summary file
echo $nicename $pvc_height $carbonate_height $dotp_height $p4008_height $pvc_perc $carbonate_perc $dotp_perc $p4008_perc
echo $nicename $pvc_height $carbonate_height $dotp_height $p4008_height $pvc_perc $carbonate_perc $dotp_perc $p4008_perc >> acombinedresults.txt


	echo Congratulations, new sample analysed 
	echo
return

else
	echo $outputresult
	echo Sample already processed
	echo
fi
}


function tidy {

echo Tidy up

mv *.png jpg
mv *combined.pdf pdf
mv *.xy xy_chart_files
rm *param*
rm fit.log
rm *.xy
rm *.plt
rm *_std.txt
rm percentages.txt

####### Make combined output
gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=allanalysedftir.pdf pdf/*combined.pdf
}



while :
do
echo $# to go
if [[ "$#" > "0" ]]
then 

echo $# files left to process
processsample $1
shift

else 

tidy

exit
fi
done
