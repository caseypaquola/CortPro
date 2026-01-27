#!/bin/bash
#==========================================================
# voxelwise_snr.sh
#
# Compute voxel-wise SNR map for a T1-weighted image using:
# Smoothed Image Substraction technique (McCann et al., 2013)
# "This method has been formulated as an alternative to existing 
# single-image approaches. It eliminates degradation of the noise 
# estimate by removing low-frequency trends in the signal-producing 
# region via filtering, prior to obtaining the noise measurement. 
# These trends arise for a number of reasons, such as elevated signal 
# close to coil elements, the dielectric effect in ionic solutions, 
# inhomogeneities in the RF field or geometric distortion. They are 
# consistent features in repeated acquisitions and as such are not present 
# in subtraction images. Any contribution they make to noise in single-image 
# techniques should therefore be minimized. This technique assumes that 
# these trends are spectrally distinct from the noise content."
#
# Dependencies:
# - FSL (fslmaths)
#
# Usage:
# ./voxelwise_snr.sh <SUBJECT_ID> <sigma>
#
# Arguments:
# $1 - SUBJECT_ID
# $2 - Gaussian smoothing sigma (defines spotlight size)
#
#==========================================================

SUBJECT_ID=$1
SIGMA=$2

FSLDIR=/opt/fsl-6.0.2/
MICRO_IMAGE=/out_dir/$SUBJECT_ID/"$SUBJECT_ID"_space-fsnative_desc-micro.nii.gz
PREFIX=/out_dir/$SUBJECT_ID/"$SUBJECT_ID"_tmp_

echo "Voxel-wise SNR computation using McCann smoothed image subtraction method"
echo "Gaussian smoothing sigma: $SIGMA"

# Filenames inside Singularity (/run_dir/)
SMOOTH_IMAGE="${PREFIX}_smooth.nii.gz"
NOISE_IMAGE="${PREFIX}_noise.nii.gz"
NOISE_SQ="${PREFIX}_noise_sq.nii.gz"
MEAN_NOISE="${PREFIX}_mean_noise.nii.gz"
MEAN_NOISE_SQ="${PREFIX}_mean_noise_sq.nii.gz"
MEAN_NOISE_SQ_MUL="${PREFIX}_mean_noise_mul.nii.gz"
LOCAL_VAR="${PREFIX}_local_var.nii.gz"
LOCAL_STD="${PREFIX}_local_std.nii.gz"
LOCAL_STD_EPS="${PREFIX}_local_std_eps.nii.gz"
SNR_MAP="/out_dir/$SUBJECT_ID/"$SUBJECT_ID"_space-fsnative_desc-micro_SNR.nii.gz"

# 1) Smooth T1
echo "[1] Smoothing T1w image..."
$FSLDIR/bin/fslmaths $MICRO_IMAGE -s "${SIGMA}" "${SMOOTH_IMAGE}"

# 2) Noise image = original - smooth
echo "[2] Noise image..."
$FSLDIR/bin/fslmaths "${MICRO_IMAGE}" -sub "${SMOOTH_IMAGE}" "${NOISE_IMAGE}"

# 3) Noise^2
echo "[3] Squaring noise..."
$FSLDIR/bin/fslmaths "${NOISE_IMAGE}" -mul "${NOISE_IMAGE}" "${NOISE_SQ}"

# 4) Local means E[x] and E[x^2]
echo "[4] Local smoothing for means..."
$FSLDIR/bin/fslmaths "${NOISE_IMAGE}" -s "${SIGMA}" "${MEAN_NOISE}"
$FSLDIR/bin/fslmaths "${NOISE_SQ}" -s "${SIGMA}" "${MEAN_NOISE_SQ}"

# 5) (E[x])^2
echo "[5] Square local mean..."
$FSLDIR/bin/fslmaths "${MEAN_NOISE}" -mul "${MEAN_NOISE}" "${MEAN_NOISE_SQ_MUL}"

# 6) Local variance
echo "[6] Local variance..."
$FSLDIR/bin/fslmaths "${MEAN_NOISE_SQ}" -sub "${MEAN_NOISE_SQ_MUL}" "${LOCAL_VAR}"

# 7) Threshold negative values
echo "[7] Threshold negative values to zero..."
$FSLDIR/bin/fslmaths "${LOCAL_VAR}" -thr 0 "${LOCAL_VAR}"

# 8) Local std
echo "[8] Local std (sqrt variance)..."
$FSLDIR/bin/fslmaths "${LOCAL_VAR}" -sqrt "${LOCAL_STD}"

# 9) Add epsilon
EPS=1e-6
echo "[9] Adding epsilon ${EPS} to local std..."
$FSLDIR/bin/fslmaths "${LOCAL_STD}" -add "${EPS}" "${LOCAL_STD_EPS}"

# 10) SNR map
echo "[10] Creating SNR map (T1 / local_std)..."
$FSLDIR/bin/fslmaths "${MICRO_IMAGE}" -div "${LOCAL_STD_EPS}" "${SNR_MAP}"

echo "Voxel-wise SNR map saved to: $SNR_MAP"