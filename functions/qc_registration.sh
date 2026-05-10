#!/bin/bash

OUTPUT_DIR=$1
SUBJECT_ID=$2
SUBJECTS_DIR=$3

# Define and create the QC directory
SUBJECT_QC="${OUTPUT_DIR}/${SUBJECT_ID}/QC"
mkdir -p "${SUBJECT_QC}"

# Path definitions
IMG="${OUTPUT_DIR}/${SUBJECT_ID}/${SUBJECT_ID}_space-fsnative_desc-micro.nii.gz"
SURF_DIR="${SUBJECTS_DIR}/${SUBJECT_ID}/surf"

# 1. Create a temporary command file
CMD_FILE="${SUBJECT_QC}/fv_commands.txt"

# 2. Write the commands to the file (one per line, no semicolons needed)
cat <<EOF > "${CMD_FILE}"
-viewport coronal -ras 0 0 0 -ss ${SUBJECT_QC}/${SUBJECT_ID}_coronal_1.png
-viewport coronal -ras 0 -20 10 -ss ${SUBJECT_QC}/${SUBJECT_ID}_coronal_2.png
-viewport coronal -ras 0 25 0 -ss ${SUBJECT_QC}/${SUBJECT_ID}_coronal_3.png
-viewport axial -ras 0 0 15 -ss ${SUBJECT_QC}/${SUBJECT_ID}_axial_1.png
-viewport axial -ras 0 0 -10 -ss ${SUBJECT_QC}/${SUBJECT_ID}_axial_2.png
-viewport sagittal -ras -25 0 0 -ss ${SUBJECT_QC}/${SUBJECT_ID}_sagittal_1.png
-viewport sagittal -ras 25 0 0 -ss ${SUBJECT_QC}/${SUBJECT_ID}_sagittal_2.png
-quit
EOF

# 3. Run freeview using the command file
freeview "${IMG}" -f \
    "${SURF_DIR}/lh.white:edgecolor=blue" \
    "${SURF_DIR}/lh.pial:edgecolor=red" \
    "${SURF_DIR}/rh.white:edgecolor=blue" \
    "${SURF_DIR}/rh.pial:edgecolor=red" \
    -cmd "${CMD_FILE}"

# 4. Cleanup (optional)
rm "${CMD_FILE}"