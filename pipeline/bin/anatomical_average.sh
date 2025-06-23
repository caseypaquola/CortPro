#!/bin/bash

m=$1

echo "Defining FSLDIR"
FSLDIR=/opt/fsl-6.0.2/
mkdir /run_dir
cd /anat_dir

# Extra parameters
StandardImage="$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz"
StandardMask="$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz"

# Image List
imageList=$(ls -1 *"${m}".nii.gz)
im1=`echo "$imageList" | head -n 1`;
if [ "$m" = "T1w" ] ; then
    prefix=`echo "$im1" | sed 's/T1w.nii.gz//'`
elif [ "$m" = "T2w" ] ; then
    prefix=`echo "$im1" | sed 's/T2w.nii.gz//'`
fi
imageList=$(ls -1 "${prefix}"*"${m}".nii.gz)
num_scans=$(ls "${prefix}"*"${m}".nii.gz | wc -l)
echo "[INFO] found $num_scans of ${m}: $imageList"

# Quit if there's only one run
if [ "$num_scans" -lt 2 ] ; then
    cp $imageList /out_dir/${m}.nii.gz
    exit 0
fi

# For each image reorient and register to std space
echo "Reorienting images"
for f in *${m}.nii.gz; do
    fn=`$FSLDIR/bin/remove_ext $f`;
    fn=`basename $fn`;
    if [ ! -f ${fn}roi_to_std.mat ] ; then
        $FSLDIR/bin/fslreorient2std ${fn}.nii.gz ${fn}_reorient
        $FSLDIR/bin/robustfov -i "${fn}"_reorient -r "${fn}"_roi -m "${fn}"_roi2orig.mat
        $FSLDIR/bin/convert_xfm -omat ${fn}TOroi.mat -inverse ${fn}_roi2orig.mat
        $FSLDIR/bin/flirt -in ${fn}_roi -ref "$StandardImage" -omat ${fn}roi_to_std.mat -out ${fn}roi_to_std -dof 12 -searchrx -30 30 -searchry -30 30 -searchrz -30 30
        $FSLDIR/bin/convert_xfm -omat ${fn}_std2roi.mat -inverse ${fn}roi_to_std.mat
    fi
done

# register images together, using standard space brain masks
echo "Identifying the first image and defining the prefix"
im1=`echo "$imageList" | head -n 1`;
if [ "$m" = "T1w" ] ; then
    prefix=`echo "$im1" | sed 's/_run-01_T1w.nii.gz//'`
elif [ "$m" = "T2w" ] ; then
    prefix=`echo "$im1" | sed 's/_run-01_T2w.nii.gz//'`
fi
im1=${prefix}_run-01_${m}
cp $FSLDIR/etc/flirtsch/ident.mat ${im1}_to_im1_linmask.mat
translist=${im1}_to_im1_linmask.mat
echo "Registering other images to the first"
for i in `seq 2 1 "$num_scans"` ; do
    im2=${prefix}_run-0${i}_${m}
    if [ ! -f ${im2}_to_im1_linmask.mat ] ; then
        echo "Register version of two images (whole heads still)"
        $FSLDIR/bin/flirt -in ${im2}_roi -ref ${im1}_roi -omat ${im2}_to_im1.mat -out ${im2}_to_im1 -dof 6 -searchrx -30 30 -searchry -30 30 -searchrz -30 30 
            
        echo "transform std space brain mask"
        $FSLDIR/bin/flirt -init ${im1}_std2roi.mat -in "$StandardMask" -ref ${im1}_roi -out ${im1}_roi_linmask -applyxfm
            
        echo "re-register using the brain mask as a weighting image"
        #TSC: "-nosearch" only sets angle to 0, still optimizes translation
        $FSLDIR/bin/flirt -in ${im2}_roi -init ${im2}_to_im1.mat -omat ${im2}_to_im1_linmask.mat -out ${im2}_to_im1_linmask -ref ${im1}_roi -refweight ${im1}_roi_linmask -nosearch
    fi
    translist="$translist ${im2}_to_im1_linmask.mat"
done

echo "get the halfway space transforms (midtrans output is the *template* to halfway transform)"
#TSC: "halfway" seems to be a misnomer, transforms seem to be from each image all the way to the average template-registered position
echo "$translist"
$FSLDIR/bin/midtrans --separate=/run_dir/ToHalfTrans --template=${im1}_roi $translist

echo "interpolate"
n=1;
for i in `seq 1 1 "$num_scans"` ; do
    fn=${prefix}_run-0${i}_${m}
    num=`$FSLDIR/bin/zeropad $n 4`;
    n=`echo $n + 1 | bc`;
    $FSLDIR/bin/convert_xfm -omat /run_dir/ToHalfTrans${num}.mat -concat /run_dir/ToHalfTrans${num}.mat ${fn}TOroi.mat
    $FSLDIR/bin/convert_xfm -omat /run_dir/ToHalfTrans${num}.mat -concat ${im1}_roi2orig.mat /run_dir/ToHalfTrans${num}.mat
    $FSLDIR/bin/applywarp --rel -i ${fn}_reorient --premat=/run_dir/ToHalfTrans${num}.mat -r ${im1}_reorient -o /run_dir/ImToHalf${num} --interp=spline  
done

echo "average outputs"
comm=`echo /run_dir/ImToHalf* | sed "s@ /run_dir/ImToHalf@ -add /run_dir/ImToHalf@g"`;
tot=`echo /run_dir/ImToHalf* | wc -w`;
$FSLDIR/bin/fslmaths ${comm} -div $tot /out_dir/${m}.nii.gz