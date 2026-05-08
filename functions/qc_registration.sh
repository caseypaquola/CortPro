#!/bin/bash

OUTPUT_DIR=$1
SUBJECT_ID=$2
SUBJECTS_DIR=$3

if [ $# -lt 3 ]; then
  echo "Usage: $0 <output_dir> <subject_id> <freesurfer_home>"
  exit 1
fi

# Define and create the QC directory
SUBJECT_QC="${OUTPUT_DIR}/${SUBJECT_ID}/QC"
mkdir -p "${SUBJECT_QC}"

# Path definitions
IMG="${OUTPUT_DIR}/${SUBJECT_ID}/${SUBJECT_ID}_space-fsnative_desc-micro.nii.gz"
SURF_DIR="${SUBJECTS_DIR}/subjects/${SUBJECT_ID}/surf" # Standard FS path structure

# ----------------------------------------------------------------              
# Function Definition
# ----------------------------------------------------------------
take_sshot () {
  local img="$1"
  local surf="$2"
  local view="$3"
  local x="$4"
  local y="$5"
  local z="$6"
  local outfile="$7"

  # Check if image exists before calling freeview
  if [[ ! -f "${img}" ]]; then
    echo "Error: Image not found at ${img}"
    return 1
  fi

  xvfb-run freeview "${img}" \
    -f \
    "${surf}/lh.white:edgecolor=blue" \
    "${surf}/lh.pial:edgecolor=red" \
    "${surf}/rh.white:edgecolor=blue" \
    "${surf}/rh.pial:edgecolor=red" \
    -viewport "${view}" \
    -ras "${x}" "${y}" "${z}" \
    -ss "${outfile}"
}

take_sshot "${IMG}" "${SURF_DIR}" coronal 0 0 0 "${SUBJECT_QC}/${SUBJECT_ID}_space-fsnative_desc-registration_QC_coronal_1.png"
take_sshot "${IMG}" "${SURF_DIR}" coronal 0 -20 10 "${SUBJECT_QC}/${SUBJECT_ID}_space-fsnative_desc-registration_QC_coronal_2.png"
take_sshot "${IMG}" "${SURF_DIR}" coronal 0 25 0 "${SUBJECT_QC}/${SUBJECT_ID}_space-fsnative_desc-registration_QC_coronal_3.png"
take_sshot "${IMG}" "${SURF_DIR}" axial 0 0 15 "${SUBJECT_QC}/${SUBJECT_ID}_space-fsnative_desc-registration_QC_axial_1.png"
take_sshot "${IMG}" "${SURF_DIR}" axial 0 0 -10 "${SUBJECT_QC}/${SUBJECT_ID}_space-fsnative_desc-registration_QC_axial_2.png"
take_sshot "${IMG}" "${SURF_DIR}" sagittal -25 0 0 "${SUBJECT_QC}/${SUBJECT_ID}_space-fsnative_desc-registration_QC_sagittal_1.png"
take_sshot "${IMG}" "${SURF_DIR}" sagittal 25 0 0 "${SUBJECT_QC}/${SUBJECT_ID}_space-fsnative_desc-registration_QC_sagittal_2.png"
