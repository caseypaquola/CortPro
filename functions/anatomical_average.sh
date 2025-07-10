#!/bin/bash

m=$1

echo "Defining FSLDIR"
FSLDIR=/opt/fsl-6.0.2/
cd /anat_dir

# Extra parameters
StandardImage="$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz"
StandardMask="$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz"

# Image List
imageList=$(ls -1 *"${m}"*.nii.gz)
num_scans=$(ls *"${m}"*.nii.gz | wc -l)
echo "[INFO] found $num_scans of modality ${m}: $imageList"

# Quit if there's only one run
if [ "$num_scans" -lt 2 ] ; then
    cp $imageList /out_dir/${m}.nii.gz
    exit 0
fi

# For each image reorient and register to std space
echo "Reorienting images"
for i in `seq 1 1 "$num_scans"` ; do
    im1=`echo "$imageList" | head -n ${i} | tail -n 1`;
    if [ ! -f /tmp/${m}_run-${i}_roi_to_std.mat ] ; then
        $FSLDIR/bin/fslreorient2std /anat_dir/$im1 /tmp/${m}_run-${i}_reorient
        $FSLDIR/bin/robustfov -i /tmp/${m}_run-${i}_reorient -r /tmp/${m}_run-${i}_roi -m /tmp/${m}_run-${i}_roi2orig.mat
        $FSLDIR/bin/convert_xfm -omat /tmp/${m}_run-${i}_TOroi.mat -inverse /tmp/${m}_run-${i}_roi2orig.mat
        $FSLDIR/bin/flirt -in /tmp/${m}_run-${i}_roi -ref "$StandardImage" -omat /tmp/${m}_run-${i}_roi_to_std.mat -out /tmp/${m}_run-${i}_roi_to_std -dof 12 -searchrx -30 30 -searchry -30 30 -searchrz -30 30
        $FSLDIR/bin/convert_xfm -omat /tmp/${m}_run-${i}_std2roi.mat -inverse /tmp/${m}_run-${i}_roi_to_std.mat
    fi
done

# register images together, using standard space brain masks
echo "Identifying the first image"
cp $FSLDIR/etc/flirtsch/ident.mat /tmp/${m}_run-1_to_im1_linmask.mat
translist=/tmp/${m}_run-1_to_im1_linmask.mat

echo "transform std space brain mask"
$FSLDIR/bin/flirt -init /tmp/${m}_run-1_std2roi.mat -in "$StandardMask" -ref /tmp/${m}_run-1_roi -out /tmp/${m}_run-1_roi_linmask -applyxfm

echo "Registering other images to the first"
for i in `seq 2 1 "$num_scans"` ; do
    im2=`echo "$imageList" | head -n ${i} | tail -n 1`;
    if [ ! -f /tmp/${m}_run-${i}_to_im1_linmask.mat ] ; then
        echo "Register version of two images (whole heads still)"
        $FSLDIR/bin/flirt -in /tmp/${m}_run-${i}_roi -ref /tmp/${m}_run-1_roi -omat /tmp/${m}_run-${i}_to_im1.mat -out /tmp/${m}_run-${i}_to_im1 -dof 6 -searchrx -30 30 -searchry -30 30 -searchrz -30 30 
            
        echo "re-register using the brain mask as a weighting image"
        $FSLDIR/bin/flirt -in /tmp/${m}_run-${i}_roi -init /tmp/${m}_run-${i}_to_im1.mat -omat /tmp/${m}_run-${i}_to_im1_linmask.mat -out /tmp/${m}_run-${i}_to_im1_linmask -ref /tmp/${m}_run-1_roi -refweight /tmp/${m}_run-1_roi_linmask -nosearch
    fi
    translist="$translist /tmp/${m}_run-${i}_to_im1_linmask.mat"
done

echo "get the halfway space transforms (midtrans output is the *template* to halfway transform)"
echo "$translist"
$FSLDIR/bin/midtrans --separate=/tmp/ToHalfTrans --template=/tmp/${m}_run-1_roi $translist

echo "interpolate"
for i in `seq 1 1 "$num_scans"` ; do
    im1=`echo "$imageList" | head -n ${i} | tail -n 1`;
    num=`$FSLDIR/bin/zeropad $i 4`;
    $FSLDIR/bin/convert_xfm -omat /tmp/ToHalfTrans${num}.mat -concat /tmp/ToHalfTrans${num}.mat /tmp/${m}_run-${i}_TOroi.mat
    $FSLDIR/bin/convert_xfm -omat /tmp/ToHalfTrans${num}.mat -concat /tmp/${m}_run-1_roi2orig.mat /tmp/ToHalfTrans${num}.mat
    $FSLDIR/bin/applywarp --rel -i /tmp/${m}_run-${i}_reorient --premat=/tmp/ToHalfTrans${num}.mat -r /tmp/${m}_run-1_reorient -o /tmp/ImToHalf${num} --interp=spline  
done

echo "average outputs"
comm=`echo /tmp/ImToHalf* | sed "s@ /tmp/ImToHalf@ -add /tmp/ImToHalf@g"`;
tot=`echo /tmp/ImToHalf* | wc -w`;
$FSLDIR/bin/fslmaths ${comm} -div $tot /out_dir/${m}.nii.gz