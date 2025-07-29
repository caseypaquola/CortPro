#!/bin/bash

# set paths and variables

ANAT_DIR=$1
SUBJECT_ID=$2
OUT_DIR=$3
RATIO_TYPE=$4

micapipe_simg=${SING_DIR}/micapipe-v0.2.3.simg
ls $TOOLBOX_BIN

for m in T1w $RATIO_TYPE ; do

    # Create T1 and T2 average across all available runs
    singularity exec -B $ANAT_DIR:/anat_dir \
                -B $OUT_DIR/$SUBJECT_ID/:/out_dir \
                -B ${TOOLBOX_BIN}/:/toolbox_bin \
                "${micapipe_simg}" \
                /toolbox_bin/anatomical_average.sh "$m"

    # Apply bias correction
    mri_nu_correct.mni --i $OUT_DIR/$SUBJECT_ID/${m}.nii.gz --o $OUT_DIR/$SUBJECT_ID/${m}_BC.nii.gz
done

##------------------------------------------------------------------------------#
# Register T2 directly to T1 with affine
singularity exec -B $OUT_DIR/$SUBJECT_ID/:/run_dir \
            "${micapipe_simg}" \
            antsRegistrationSyN.sh \
            -d 3 \
            -f /run_dir/T1w_BC.nii.gz \
            -m /run_dir/${RATIO_TYPE}_BC.nii.gz \
            -o /run_dir/${RATIO_TYPE}_space-T1 \
            -t a 


##------------------------------------------------------------------------------#
# Compute T1w/T2w image
echo "Computing the ratio image"
singularity exec -B $OUT_DIR/$SUBJECT_ID/:/run_dir \
            "${micapipe_simg}" \
            fslmaths /run_dir/T1w.nii.gz \
            -div /run_dir/${RATIO_TYPE}_space-T1Warped.nii.gz \
            /run_dir/T1wDividedBy${RATIO_TYPE}.nii.gz