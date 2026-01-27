#!/bin/bash

# set paths and variables

T1_FILE=$1
T2_FILE=$2
SUBJECT_ID=$3
OUT_DIR=$4
SKIP_BC=$5

micapipe_simg=${SING_DIR}/micapipe-v0.2.3.simg


if [[ "$SKIP_BC" -eq 0 ]]; then
    echo "Apply bias correction"
    mri_nu_correct.mni --i $T1_FILE --o $OUT_DIR/$SUBJECT_ID/T1w_BC.nii.gz
    mri_nu_correct.mni --i $T2_FILE --o $OUT_DIR/$SUBJECT_ID/T2w_BC.nii.gz

    echo "Register T2 directly to T1 with affine"
    singularity exec -B $OUT_DIR/$SUBJECT_ID/:/run_dir \
            "${micapipe_simg}" \
            antsRegistrationSyN.sh \
            -d 3 \
            -f /run_dir/T1w_BC.nii.gz \
            -m /run_dir/T2w_BC.nii.gz \
            -o /run_dir/T2w_space-T1 \
            -t a 
else

    echo "Register T2 directly to T1 with affine"
    cp $T1_FILE $OUT_DIR/$SUBJECT_ID/T1w.nii.gz
    cp $T2_FILE $OUT_DIR/$SUBJECT_ID/T2w.nii.gz
    singularity exec -B $OUT_DIR/$SUBJECT_ID/:/run_dir \
            "${micapipe_simg}" \
            antsRegistrationSyN.sh \
            -d 3 \
            -f /run_dir/T1w.nii.gz \
            -m /run_dir/T2w.nii.gz \
            -o /run_dir/T2w_space-T1 \
            -t a 
fi


##------------------------------------------------------------------------------#
# Compute T1w/T2w image
echo "Computing the ratio image"
singularity exec -B $OUT_DIR/$SUBJECT_ID/:/run_dir \
            "${micapipe_simg}" \
            fslmaths /run_dir/T1w.nii.gz \
            -div /run_dir/T2w_space-T1Warped.nii.gz \
            /run_dir/T1wDividedByT2w.nii.gz
