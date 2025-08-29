#!/bin/bash

# set paths and variables

ANAT_DIR=$1
SUBJECT_ID=$2
SUBJECTS_DIR=$3
OUTPUT_DIR=$4

fastsurfer_sif=${SING_DIR}/fastsurfer-gpu.sif
micapipe_simg=${SING_DIR}/micapipe-v0.2.3.simg

# -----------------------------
# Check for singularity
# -----------------------------
if [[ ! -f $fastsurfer_sif ]] ; then
    echo "[ERROR] Can't find singularity of Fastsurfer"
    exit
fi


# -----------------------------
# Grab or create T1w if not already in output directory
# -----------------------------
if [[ ! -f "${OUTPUT_DIR}"/$SUBJECT_ID/T1w.nii.gz ]] ; then

    # -----------------------------
    # Identify T1s in ANAT_DIR
    # -----------------------------
    m=T1w
    cd $ANAT_DIR
    imageList=$(ls -1 *"${m}"*.nii.gz)
    num_scans=$(ls *"${m}"*.nii.gz | wc -l)

    # -----------------------------
    # Define T1 for Fastsurfer use 
    # -----------------------------
    if [ "$num_scans" -lt 2 ] ; then
        cp $imageList $OUTPUT_DIR/$SUBJECT_ID/${m}.nii.gz
    else
        if [[ ! -f $OUTPUT_DIR/${m}.nii.gz ]] ; then
            singularity exec -B $ANAT_DIR:/anat_dir \
                    -B $OUTPUT_DIR/$SUBJECT_ID/:/OUTPUT_DIR \
                    -B ${TOOLBOX_BIN}/:/bin \
                    "${micapipe_simg}" \
                    bin/anatomical_average.sh T1w
        fi
    fi

fi

# -----------------------------
# Create Fastsurfer directory if needed
# -----------------------------
mkdir -p "$SUBJECTS_DIR"/"$SUBJECT_ID" || {
    echo "[ERROR] Failed to create output directory: "$SUBJECTS_DIR"/"$SUBJECT_ID""
    exit 1
}

# -----------------------------
# Run Fastsurfer
# -----------------------------
singularity exec --nv \
                 --no-home \
                 -B "${OUTPUT_DIR}"/$SUBJECT_ID/:/output \
                 -B "${SUBJECTS_DIR}"/:/subjects_dir \
                 -B ${FREESURFER_HOME}/:/freesurfer \
                 "${fastsurfer_sif}" \
                 /fastsurfer/run_fastsurfer.sh \
                 --t1 /output/T1w.nii.gz \
                 --sid $SUBJECT_ID \
                 --sd /subjects_dir/ \
                 --fs_license /freesurfer/license.txt \
                 --parallel --3T