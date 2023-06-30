# ftir-fitting-pvc

A script for automatically analysing FTIR spectra of PVC to determine 
the contribution of four raw materials to the overall formulation

The main script, **ftir-fitting-pvc.sh** analyses FTIR spectra of a PVC mixture fitting the sample data against
defined spectra of four standards, plus a linear background. Other scripts in this repository are 
for pre-processing the data and generating required files in the working directory.

## Requirements

The script requires the following software to run:
- A Unix / Linux environment (tested with Ubuntu 22.04)
- Packages "dos2unix", "bc", "awk", "ghostscript"
- Gnuplot graphing software (package "gnuplot") 
    - v4.5 or above is required, v5.4.2 is included with Ubuntu 22.04

- All scripts require permission to execute as programs

The input is taken from a series of two-column space-separated text files. The text files should be contained 
within one single folder, or grouped into sub-folders which will each need to be prepared and analysed separately.
Column 1 is the wavenumber, column 2 is the intensity.

## Basic Operation

### Preparing the data files

#### Converting comma separated to space separated files

If data is presented in comma separated files, the script "**csvtxt.sh**" can be used to convert them into space-separated text files. 
Original .csv and .CSV files are moved into a new folder called "CSV".

> $ csvtxt.sh mydata.csv

#### Cropping and scaling input data

The data file must have the same wavenumber values as the defiend standard spectra. The default standards in this repository
range from 555 to 1800 cm-1.
If necessary, edit the script "**crop_baseline_scale.sh**" to give the correct maximum and minimum wavenumbers from the standard spectra. 

The script "**crop_baseline_scale.sh**" requires inputs of one or more data files (two column, space sparated). "*" can be used as a wildcard. Example:

> $ crop_baseline_scale.sh mydata.txt 

The script does the following operations:
- Datafile is cropped to only include x-values in the range defined at the start of the script
- Data is adjusted so that the smallest intensity value is corrected to "0", by subtracting the minimum intensity of the entire dataset from each data point.
- Data is scaled to be within the range 0 to 100

Processed data is moved to the folder "crop_scaled". Original data is preserved in the folder "full_sized"

### Preparing the working directory

Ensure that the datafile containing the FTIR spectra of the standards is present in the "crop_scaled" folder 
and is named "**FTIR_standards_scaled.txt**"

The script "**prepftir.sh**" should be run before the first files in a given folder are analysed.
This script creates folders and initiates some datafiles for the subsequent analyses.
Execute the script within the "crop_scaled" folder

> $ prepftir.sh

### Script Execution

The script executes from the command line, in the form
> $ ftir-fitting-pvc.sh [options] [input files]

The options are
-q Quiet mode - graphs appear on screen but immediately disappear
-d Delete - removes previous results from "acombinedresults.txt"

Input files can be listed individually, or selected all at once using a wildcard (e.g. *.txt)
After analysis the results are written to a file entitled "acombinedresults.txt". Any filename
already in this file will be ignored and not re-fitted. The "-d" option removes all results 
from "acombinedresults.txt" and allows previously fitted files to be analysed.

Example code to prepare for and then analyse all samples with "specimen" at the start of the file name:
> $ prepftir.sh
> 
> $ ftir-fitting-pvc.sh -d -q specimen*.txt

### Outputs

The script outputs two graphs, containing the raw spectra with linear background identified,
raw spectra with overall fit superimposed and a residual shown, and the spectra following the fitting,
showing the fitted peaks after the background has been removed. 

The fitting parameters are written to a summary file (acombinedresults.txt) for further analysis
