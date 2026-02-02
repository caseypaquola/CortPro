#!/bin/bash

SUBJECT_ID=$1

FSLDIR=/opt/fsl-6.0.2/
T1_in_fs=/subjects_dir/${SUBJECT_ID}/mri/rawavg.mgz
MICRO_TEMPLATE=/out_dir/$SUBJECT_ID/"$SUBJECT_ID"_space-native_desc-template.nii.gz
MICRO_IMAGE=/out_dir/$SUBJECT_ID/"$SUBJECT_ID"_space-native_desc-micro.nii.gz
MICRO_WARPED="/out_dir/${SUBJECT_ID}/${SUBJECT_ID}_space-fsnative_desc-micro.nii.gz"

synthseg_native() {
  mri_img=$1
  mri_str=$2
  mri_synth="/out_dir/${mri_str}_synthsegGM.nii.gz"
  mri_synthseg --i "${mri_img}" --o "/tmp/${mri_str}_synthseg.nii.gz" --robust --cpu
  $FSLDIR/bin/fslmaths "/tmp/${mri_str}_synthseg.nii.gz" -uthr 42 -thr 42 -bin -mul -39 -add "/tmp/${mri_str}_synthseg.nii.gz" "${mri_synth}"
}

synthseg_native "${T1_in_fs}" "T1w"
synthseg_native "${MICRO_TEMPLATE}" "micro"
img_fixed="/out_dir/T1w_synthsegGM.nii.gz"
img_moving="/out_dir/micro_synthsegGM.nii.gz"
str_micro2fs_xfm="/out_dir/${SUBJECT_ID}/${SUBJECT_ID}_from-micro_to-fsnative_"
mat_micro2fs_xfm="${str_micro2fs_xfm}0GenericAffine.mat"

# Registrations from T1-fsnative to micro-native space
antsRegistrationSyN.sh -d 3 -f "$img_fixed" -m "$img_moving" -o "$str_micro2fs_xfm" -t a -p d -i ["${img_fixed}","${img_moving}",0]

# Check if transformations file exist
if [ ! -f "${mat_micro2fs_xfm}" ]; then 
  echo "[ERROR] Registration between micro and T1fsnative failed"
  exit
fi

# Apply transformations: from micro to T1-fsnative
antsApplyTransforms -d 3 -i "$MICRO_IMAGE" -r "$T1_in_fs" -t ${mat_micro2fs_xfm} -o "$MICRO_WARPED" -v -u int
