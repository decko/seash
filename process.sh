#!/bin/sh

# Based from http://oceancolor.gsfc.nasa.gov/forum/oceancolor/topic_show.pl?tid=2046
# first define the region to be extracted from your MODIS L1A files
# NOTE! change these for your own region of interest

SWLON=-77
SWLAT=37
NELON=-74.5
NELAT=39.5

for FILE in *L1A_LAC
do
# The line below assumes an extension, and creates a base name without that extension
BASE=`echo $FILE |awk -F. '{ print $1 }'`
GEOFILE=${BASE}.GEO
L1ASUB=${BASE}_sub.L1A_LAC
GEOSUB=${BASE}_sub.GEO
L1BFILE=${BASE}.L1B
L2FILE=${BASE}.L2

# process the L1A file to GEO
modis_L1A_to_GEO.csh $FILE -o $GEOFILE
if [ $? -ne 0 ]; then
	echo 'Problem creating the GEO file from' $FILE
	exit 1
fi

# extract a subscene from the MODIS file
modis_L1A_extract.csh $FILE $GEOFILE $SWLON $SWLAT $NELON $NELAT $L1ASUB $GEOSUB
if [ $? -ne 0 ]; then
        echo 'Problem extracting a subscene from' $FILE
        exit 1
fi

# process the L1A/GEO subscene files to L1B
modis_L1A_to_L1B.csh $L1ASUB $GEOSUB -o $L1BFILE -delete-hkm -delete-qkm
if [ $? -ne 0 ]; then
        echo 'Problem generating L1B file from' $FILE
        exit 1
fi


# determine ancillary data
ms_met.csh $L1BFILE
ms_ozone.csh $L1BFILE
ms_oisst.csh $L1BFILE
# the three above commands create three files in l2gen's par file format:
#   L1BFILE.met_list, L1BFILE.ozone_list, L1BFILE.sst_list

# process the L1B subscene to L2
echo "Processing $L1BFILE to Level 2.."
# NOTE! customize the l2gen parameters here
l2gen ifile=$L1BFILE geofile=$GEOSUB ofile1=$L2FILE \
l2prod1='chlor_a,K_490,nLw_412,nLw_551,l2_flags' \
par=${L1BFILE}.met_list \
par=${L1BFILE}.ozone_list \
par=${L1BFILE}.sst_list >$BASE.log
done
