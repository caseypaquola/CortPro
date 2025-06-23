#!/bin/bash

SUBJECT_ID=$1

FSLDIR=/opt/fsl-6.0.2/
mkdir /run_dir
T1_in_fs=/subjects_dir/${SUBJECT_ID}/mri/rawavg.mgz
MICRO_IMAGE=/outdir/$SUBJECT_ID/"$SUBJECT_ID"_space-nativepro_desc-micro.nii.gz


synthseg_native() {
  mri_img=$1
  mri_str=$2
  mri_synth=/run_dir/${mri_str}_synthsegGM.nii.gz"
  mri_synthseg --i "${mri_img}" --o /run_dir/${mri_str}_synthseg.nii.gz" --robust --cpu
  fslmaths /run_dir/${mri_str}_synthseg.nii.gz" -uthr 42 -thr 42 -bin -mul -39 -add /run_dir/${mri_str}_synthseg.nii.gz" "${mri_synth}"
}

synthseg_native "${T1_in_fs}" "T1w"
synthseg_native "${MICRO_IMAGE}" "micro"
img_fixed=/run_dir/T1w_synthsegGM.nii.gz"
img_moving=/run_dir/micro_synthsegGM.nii.gz"
str_micro2fs_xfm=/out_dir/${SUBJECT_ID}/${SUBJECT_ID}_from-micro_to-fsnative_"
mat_micro2fs_xfm="${str_micro2fs_xfm}0GenericAffine.mat"
micro_warped=/out_dir/${SUBJECT_ID}_space-fsnative_desc-micro.nii.gz"

# Registrations from t1-fsnative to qMRI
antsRegistrationSyN.sh -d 3 -f "$img_fixed" -m "$img_moving" -o "$str_qMRI2fs_xfm" -t a -p d -i ["${img_fixed}","${img_moving}",0]

# Check if transformations file exist
if [ ! -f "${mat_qMRI2fs_xfm}" ]; then 
  echo "[ERROR] Registration between micro and T1nativepro failed"
  exit
fi

# Apply transformations: from micro to T1-fsnative
antsApplyTransforms -d 3 -i "$microImage" -r "$T1_in_fs" -t ${mat_qMRI2fs_xfm} -o "$micro_warped" -v -u int