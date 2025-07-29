#!/bin/bash

# Auto-detect location of the toolbox bin directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLBOX_BIN="${SCRIPT_DIR}/functions"
export TOOLBOX_BIN

# -----------------------------
# Microstructure Profiling Toolbox Wrapper
# -----------------------------
show_help() {
    echo "Usage: $0 [--micro-image FILE] [--anat-dir DIR] --subject-id ID --subjects-dir DIR --output-dir DIR --fs-dir DIR  --sing-dir DIR [--num_surfaces 14]"
    echo
    echo "Arguments:"
    echo "  --micro-image FILE         Path to a precomputed microstructural image (optional)"
    echo "  --anat-dir DIR             Path to a BIDS anat/ directory (optional, necessary for creation of T1wDividedByT2w image and cortical surface construction)"
    echo "  --subject-id ID            Subject ID (e.g., sub-001) [required]"
    echo "  --subjects-dir DIR         Path to Freesurfer-style SUBJECTS_DIR [required] (if the directory doesn't contain surfaces for the specified subject, Fastsurfer will be run)"
    echo "  --output-dir DIR           Output directory for toolbox results [required]"
    echo "  --fs-dir DIR               Path to the FreeSurfer directory [required] (should contain standard license file, 'license.txt')"
    echo "  --sing-dir DIR             Path to the directory with singularities [required] (must contain micapipe-v0.2.3.simg and, if Freesurfer output is not yet available, fastsurfer_gpu.sif)"
    echo "  --num-surfaces N           Number of intracortical surfaces (default: 14)"
    echo "  --surface-output NAME      Name of standard surface for output, currently compatible with any fsaverage (default: fsaverage5)"
    echo "  --ratio-type NAME          Type of image for ratio with T1w (default: T2w). In principle, accepts any BIDS suffix that is housed in anat"
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
FREESURFER_HOME=""
SING_DIR=""
NUM_SURFACES=14  # default
SURF_OUT=fsaverage5  # default
RATIO_TYPE=T2w  # default

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
            FREESURFER_HOME="$2"
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
        --surface-output)
            SURF_OUT="$2"
            shift 2
            ;;
        --ratio-type)
            RATIO_TYPE="$2"
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
if [[ -z "$SUBJECT_ID" || -z "$SUBJECTS_DIR" || -z "$OUTPUT_DIR" || -z "$FREESURFER_HOME" || -z "$SING_DIR" ]]; then
    echo "[ERROR] --subject-id, --subjects-dir, --output-dir, --fs-dir and --sing-dir are all required."
    exit 1
fi
export FREESURFER_HOME
export SUBJECTS_DIR
export SING_DIR

if ! command -v singularity &> /dev/null; then
    echo "[ERROR] Singularity not found - unable to continue"
    exit 1
fi

MICAPIPE_IMG="$SING_DIR/micapipe-v0.2.3.simg"
if [[ ! -f $MICAPIPE_IMG ]]; then
    echo "[ERROR] micapipe-v0.2.3.simg not found at: $SING_DIR"
    exit 1
fi

# Validate NUM_SURFACES is a positive integer
if ! [[ "$NUM_SURFACES" =~ ^[0-9]+$ ]]; then
    echo "[ERROR] --num-surfaces must be a positive integer."
    exit 1
fi

# Create output directory if needed
mkdir -p "$OUTPUT_DIR"/"$SUBJECT_ID" || {
    echo "[ERROR] Failed to create output directory: "$OUTPUT_DIR"/"$SUBJECT_ID""
    exit 1
}

# -----------------------------
# Compile microstructure image
# -----------------------------
if [[ -n "$MICRO_IMAGE" ]]; then
    echo "[INFO] Using precomputed microstructure image: $MICRO_IMAGE"
    RESLICE_MICRO=0
else
    echo "[INFO] Producing T1wDivided${RATIO_TYPE} based on data in: $ANAT_DIR"
    MICRO_IMAGE="$OUTPUT_DIR"/"$SUBJECT_ID"/T1wDividedBy${RATIO_TYPE}.nii.gz
    if [[ ! -f $MICRO_IMAGE ]] ; then
        bash "$TOOLBOX_BIN/compute_t1t2_ratio.sh" "$ANAT_DIR" "$SUBJECT_ID" "$OUTPUT_DIR" "$RATIO_TYPE"
    fi
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
    bash "$TOOLBOX_BIN/run_fastsurfer.sh" "$ANAT_DIR" "$SUBJECT_ID" "$SUBJECTS_DIR" "$OUTPUT_DIR"
    RESLICE_MICRO=1    # Defines whether reslicing of affine registration will be used for co-registration of micro-image. Dependent on surface generation from T1 in micro-image.
else
    RESLICE_MICRO=0
    echo "[INFO] Found Freesurfer directory: "$SUBJECTS_DIR"/"$SUBJECT_ID""
fi

# -----------------------------
# Generate intracortical surfaces
# -----------------------------
echo "[INFO] Creating intracortical surfaces"
total_surfaces=$((NUM_SURFACES + 2))
for hemi in lh rh ; do
    python3 ${TOOLBOX_BIN}/generate_equivolumetric_surfaces.py \
            ${SUBJECTS_DIR}/${SUBJECT_ID}/surf/${hemi}.pial \
            ${SUBJECTS_DIR}/${SUBJECT_ID}/surf/${hemi}.white \
            $total_surfaces \
            ${OUTPUT_DIR}/${SUBJECT_ID}/${hemi}. \
            /tmp/ \
            --software freesurfer --subject_id $SUBJECT_ID
done
rm -rfv ${OUTPUT_DIR}/${SUBJECT_ID}/${hemi}.0.0.pial ${OUTPUT_DIR}/${SUBJECT_ID}/${hemi}.1.0.pial # removing pial and wm surfaces

# -----------------------------
# Co-register microstructure image
# -----------------------------
if [[ ! -f "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_space-fsnative_desc-micro.nii.gz ]] ; then
    if [[ "$RESLICE_MICRO" == 1 ]]; then
        echo "[INFO] Reslicing micro-image to surface space"
        mri_vol2vol --mov ${MICRO_IMAGE} \
            --targ ${SUBJECTS_DIR}/${SUBJECT_ID}/mri/rawavg.mgz \
            --regheader \
            --o "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_space-fsnative_desc-micro.nii.gz \
            --no-save-reg
    else
        echo "[INFO] Performing affine registration of micro-image to surface space"
        cp ${MICRO_IMAGE} $OUTPUT_DIR/$SUBJECT_ID/"$SUBJECT_ID"_space-nativepro_desc-micro.nii.gz
        singularity exec -B $SUBJECTS_DIR/:/subjects_dir \
                    -B $OUTPUT_DIR/:/out_dir \
                    -B $TOOLBOX_BIN/:/toolbox_bin \
                    "${MICAPIPE_IMG}" \
                    /toolbox_bin/coregister_micro.sh "$SUBJECT_ID"
    fi
fi


if [[ -f "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_space-fsnative_desc-micro.nii.gz ]] ; then
    # -----------------------------
    # Sample microstructure profiles
    # -----------------------------
    # create symbolic link to fsaverage
    ln -s $FREESURFER_HOME/subjects/$SURF_OUT $SUBJECTS_DIR

    for hemi in lh rh ; do
        [[ $hemi == lh ]] && HEMI=L || HEMI=R
            # find all intracortical surfaces, list by creation time, sample intensities and convert to fsaverage
            x=$(ls -t ${OUTPUT_DIR}/${SUBJECT_ID}/${hemi}.0.*)
            for n in $(seq 1 1 ${NUM_SURFACES}) ; do
                
                which_surf=$(sed -n "${n}p" <<< "$x")
                filename=${which_surf##*/}
                if [[ ! -f ${SUBJECTS_DIR}/${SUBJECT_ID}/surf/$filename ]] ; then
                    cp $which_surf ${SUBJECTS_DIR}/${SUBJECT_ID}/surf/$filename
                fi
                shortname=${filename#*.}
                
                # sample along intracortical surface
                mri_vol2surf --mov "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_space-fsnative_desc-micro.nii.gz \
                    --regheader ${SUBJECT_ID} \
                    --hemi ${hemi} \
                    --surf $shortname \
                    --o "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_hemi-${HEMI}_surf-fsspace_MP-${n}.mgh \
                    --interp trilinear
                
                # transform to fsaverage5
                mri_surf2surf --hemi ${hemi} \
                    --srcsubject $SUBJECT_ID --srcsurfval "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_hemi-${HEMI}_surf-fsspace_MP-${n}.mgh \
                    --trgsubject $SURF_OUT --trgsurfval "$OUTPUT_DIR"/"$SUBJECT_ID"/"$SUBJECT_ID"_hemi-${HEMI}_surf-${SURF_OUT}_MP-${n}.mgh
            done
        ((Nsteps++))
    done

    ##------------------------------------------------------------------------------#
    # Generate MPs for easy reading
    echo "[INFO] Collating microstructure profiles and computing moments for shape analysis"
    singularity exec -B $OUTPUT_DIR/:/out_dir \
                     -B $TOOLBOX_BIN/:/toolbox_bin \
                        "${MICAPIPE_IMG}" \
                        python3 /toolbox_bin/collate_MP.py --output_dir /out_dir/ --subject_id "$SUBJECT_ID" --num_surfaces "$NUM_SURFACES" --surface_output "$SURF_OUT"

    ##------------------------------------------------------------------------------#
    # Clean up tmp folder and drop datalad files
    #rm -rf "$OUTPUT_DIR"/"$SUBJECT_ID"/*.mgh
    #rm -rf "$OUTPUT_DIR"/"$SUBJECT_ID"/*.pial
    #rm -rf "$OUTPUT_DIR"/"$SUBJECT_ID"/*synthseg*
    #rm -rf "$OUTPUT_DIR"/"$SUBJECT_ID"/*Warped*
    #rm -rf "$OUTPUT_DIR"/"$SUBJECT_ID"/*.mat
    echo "[INFO] Toolbox completed for subject $SUBJECT_ID."

fi