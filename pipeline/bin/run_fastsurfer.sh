#!/bin/bash

# set paths and variables

ANAT_DIR=$1
SUBJECT_ID=$2
SUBJECTS_DIR=$3
OUT_DIR=$4

fastsurfer_sif=${singularities}/fastsurfer-gpu.sif
micapipe_simg=${singularities}/micapipe-v0.2.3.simg

# -----------------------------
# Check for singularity
# -----------------------------
if [[ ! -f $fastsurfer_sif ]] ; then
    echo "[ERROR] Can't find singularity of Fastsurfer"
    exit
end

# -----------------------------
# Identify T1s in ANAT_DIR
# -----------------------------
cd $ANAT_DIR
imageList=$(ls -1 *"${m}".nii.gz)
num_scans=$(ls *"${m}".nii.gz | wc -l)

# -----------------------------
# Define T1 for Fastsurfer use 
# -----------------------------
if [ "$num_scans" -lt 2 ] ; then
    cp $imageList $OUT_DIR/$SUBJECT_ID/${m}.nii.gz
else
    if [[ ! -f $OUT_DIR/${m}.nii.gz ]] ; then
        singularity exec -B $ANAT_DIR:/anat_dir \
                -B $OUT_DIR/$SUBJECT_ID/:/out_dir \
                -B ${TOOLBOX_BIN}/:/bin \
                "${micapipe_simg}" \
                bin/anatomical_average.sh T1w
    fi
fi

# -----------------------------
# Run Fastsurfer
# -----------------------------
singularity exec --nv \
                 --no-home \
                 -B "${OUT_DIR}"/$SUBJECT_ID/:/output \
                 -B "${SUBJECTS_DIR}"/:/subjects_dir \
                 -B ${FREESURFER_HOME}/:/freesurfer \
                 "${fastsurfer_sif}" \
                 /fastsurfer/run_fastsurfer.sh \
                 --t1 /output/T1w.nii.gz \
                 --sid $SUBJECT_ID \
                 --sd /subjects_dir/ \
                 --fs_license /freesurfer/license.txt \
                 --parallel --3T