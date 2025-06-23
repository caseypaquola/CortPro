#!/bin/bash

# Resolve script path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLBOX_BIN="${SCRIPT_DIR}/bin"

# Export for sub-scripts to use as well
export TOOLBOX_BIN

# -----------------------------
# Microstructure Profiling Toolbox Wrapper
# -----------------------------
show_help() {
    echo "Usage: $0 [--micro-image FILE] [--anat-dir DIR] --subject-id ID --subjects-dir DIR"
    echo
    echo "Arguments:"
    echo "  --micro-image FILE         Path to a precomputed microstructural image (optional)"
    echo "  --anat-dir DIR             Path to a BIDS anat/ directory (necessary for creation of T1wDividedByT2w image and cortical surface construction)"
    echo "  --subject-id ID            Subject ID (e.g., sub-001) [required]"
    echo "  --subjects-dir DIR         Path to Freesurfer-style SUBJECTS_DIR [required] (if the directory doesn't contain surfaces for the specified subject, Fastsurfer will be run)"
    echo "  --output-dir DIR           Output directory for toolbox results [required]"
    echo "  --fs-dir DIR               Path to the FreeSurfer directory [required] (should contain standard license file, 'license.txt')"
    echo "  --sing-dir DIR             Path to the directory with singularities [required] (must contain micapipe-v0.2.3.simg and, if Freesurfer output is not yet available, fastsurfer_gpu.sif)"
    echo "  --num-surfaces N           Number of intracortical surfaces (default: 14)"
    echo "  -h, --help                 Display this help message"
}

# -----------------------------
# Parse Arguments
# -----------------------------
MICRO_IMAGE=""
ANAT_DIR=""
SUBJECT_ID=""
SUBJECTS_DIR=""
OUTPUT_DIR=""
FS_DIR=""
SING_DIR=""
NUM_SURFACES=14  # default

while [[ $# -gt 0 ]]; do
    case "$1" in
        --micro-image)
            MICRO_IMAGE="$2"
            shift 2
            ;;
        --anat-dir)
            ANAT_DIR="$2"
            shift 2
            ;;
        --subject-id)
            SUBJECT_ID="$2"
            shift 2
            ;;
        --subjects-dir)
            SUBJECTS_DIR="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --fs-dir)
            FS_DIR="$2"
            shift 2
            ;;
        --sing-dir)
            SING_DIR="$2"
            shift 2
            ;;
        --num-surfaces)
            NUM_SURFACES="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "[ERROR] Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done


# -----------------------------
# Validate Required Inputs
# -----------------------------
if [[ -z "$SUBJECT_ID" || -z "$SUBJECTS_DIR" || -z "$OUTPUT_DIR" || -z "$FS_DIR" || -z "$SING_DIR" ]]; then
    echo "[ERROR] --subject-id, --subjects-dir, --output-dir, --fs-dir and --sing-dir are all required."
    exit 1
fi
export FREESURFER_HOME=$FS_DIR
export SUBJECTS_DIR="$SUBJECTS_DIR"
export singularities=$SING_DIR

if ! command -v singularity &> /dev/null; then
    echo "[ERROR] Singularity not found - unable to continue"
    exit 1
fi

if [[ ! -f $singularities/micapipe-v0.2.3.simg ]]; then
    echo "[ERROR] micapipe-v0.2.3.simg not found at: $singularities"
    exit 1
fi

# Validate NUM_SURFACES is a positive integer
if ! [[ "$NUM_SURFACES" =~ ^[0-9]+$ ]]; then
    echo "[ERROR] --num-surfaces must be a positive integer."
    exit 1
fi

# Create output directory if needed
mkdir -p "$OUTPUT_DIR"/"$SUBJECT_ID" || {
    echo "[ERROR] Failed to create output directory: "$OUTPUT_DIR"/"$SUBJECT_ID"
    exit 1
}

# -----------------------------
# Compile microstructure image
# -----------------------------
if [[ -n "$USE_PRECOMPUTED" ]]; then
    echo "[INFO] Using precomputed microstructure image: $MICRO_IMAGE"
    RESLICE_MICRO=0
else
    echo "[INFO] Producing T1wDividedT2w based on data in: $ANAT_DIR"
    ${TOOLBOX_BIN}/compute_t1t2_ratio.sh "$ANAT_DIR" "$SUBJECT_ID" "$OUT_DIR"
    MICRO_IMAGE="$OUTPUT_DIR"/"$SUBJECT_ID"/T1wDividedByT2w.nii.gz
fi


# -----------------------------
# Check for Freesurfer output and/or run Fastsurfer
# -----------------------------
if [[ ! -f "$SUBJECTS_DIR"/"$SUBJECT_ID"/surf/lh.pial ]]; then
    echo "[WARNING] Freesurfer data not found at "$SUBJECTS_DIR"/"$SUBJECT_ID". Will try to run Fastsurfer"
    if [[ -z "$ANAT_DIR" ]]; then
        echo "[ERROR] Freesurfer output missing, and no --anat-dir provided to run Fastsurfer on."
        exit 1
    fi
    ${TOOLBOX_BIN}/run_fastsurfer.sh "$ANAT_DIR" "$SUBJECT_ID" "$SUBJECTS_DIR" "$OUT_DIR"
    RESLICE_MICRO=1    # Defines whether reslicing of affine registration will be used for co-registration of micro-image. Dependent on surface generation from T1 in micro-image.
else
    RESLICE_MICRO=0
    echo "[INFO] Found Freesurfer directory: "$SUBJECTS_DIR"/"$SUBJECT_ID""
fi

# -----------------------------
# Generate intracortical surfaces
# -----------------------------

echo "[INFO] Creating intracortical surfaces"
total_surfaces=$((num_surfaces + 2))
cd ${TOOLBOX_BIN}
for hemi in lh rh ; do
    python ${TOOLBOX_BIN}/generate_equivolumetric_surfaces.py \
            ${SUBJECTS_DIR}/${SUBJECT_ID}/surf/${hemi}.pial \
            ${SUBJECTS_DIR}/${SUBJECT_ID}/surf/${hemi}.white \
            $total_surfaces \
            ${OUT_DIR}/${SUBJECT_ID}/${hemi}. \
            /tmp/ \
            --software freesurfer --subject_id $SUBJECT_ID
done
rm -rfv ${OUT_DIR}/${SUBJECT_ID}/${hemi}.0.0.pial ${OUT_DIR}/${SUBJECT_ID}/${hemi}.1.0.pial # removing pial and wm surfaces

# -----------------------------
# Co-register microstructure image
# -----------------------------
if [[ "$RESLICE_MICRO" == 1 ]]; then
    echo "[INFO] Reslicing micro-image to surface space"
    mri_vol2vol --mov ${MICRO_IMAGE} \
        --targ ${SUBJECTS_DIR}/${SUBJECT_ID}/mri/rawavg.mgz \
        --regheader \
        --o "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_space-fsnative_desc-micro.nii.gz \
        --no-save-reg
else
    echo "[INFO] Performing affine registration of micro-image to surface space"
    cp ${MICRO_IMAGE} $OUT_DIR/$SUBJECT_ID/"$SUBJECT_ID"_space-nativepro_desc-micro.nii.gz
    singularity exec -B $SUBJECTS_DIR/:/subjects_dir \
                -B $OUT_DIR/:/out_dir \
                -B ${TOOLBOX_BIN}/:/bin \
                "${micapipe_simg}" \
                coregister_micro.sh "$SUBJECT_ID"
fi

# -----------------------------
# Sample microstructure profiles
# -----------------------------
for hemi in lh rh ; do
    [[ $hemi == lh ]] && HEMI=L || HEMI=R
        # find all intracortical surfaces, list by creation time, sample intensities and convert to fsaverage5
        x=$(ls -t ${OUT_DIR}/${SUBJECT_ID}/${hemi}.0.*)
        for n in $(seq 1 1 ${num_surfaces}) ; do
            
            which_surf=$(sed -n ${n}p <<< $x)
            filename=${which_surf##*/}
            if [[ ! -f ${SUBJECTS_DIR}/${SUBJECT_ID}/surf/$filename ]] ; then
                cp $which_surf ${SUBJECTS_DIR}/${SUBJECT_ID}/surf/$filename
            fi
            shortname=${filename#*.}
            
            # sample along intracortical surface
            mri_vol2surf --mov "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_space-fsnative_desc-micro.nii.gz \
                --regheader ${fsID} \
                --hemi ${hemi} \
                --surf $shortname \
                --o "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_hemi-${HEMI}_surf-fsspace_MP-${n}.mgh
            
            # transform to fsaverage5
            mri_surf2surf --hemi ${hemi} \
                --srcsubject $SUBJECT_ID --srcsurfval "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_hemi-${HEMI}_surf-fsspace_MP-${n}.mgh \
                --trgsubject fsaverage5 --trgsurfval "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_hemi-${HEMI}_surf-fsaverage5_MP-${n}.mgh
        done
    ((Nsteps++))
done

##------------------------------------------------------------------------------#
# Generate MPs for easy reading
echo "[INFO] Collating microstructure profiles and computing moments for shape analysis"
singularity exec -B $OUT_DIR/:/out_dir \
                    "${micapipe_simg}" \
                    python collate_MP.py --output_dir /out_dir/ --subject_id "$SUBJECT_ID"

##------------------------------------------------------------------------------#
# Clean up tmp folder and drop datalad files
#rm -rf "$OUTPUT_DIR"/"$SUBJECT_ID"/*.mgh
echo "[INFO] Toolbox completed for subject $SUBJECT_ID."