# 🧠 microkit

**microkit** is an open-source toolbox for generating and analysing intracortical microstructure profiles. The only prerequisites for microstructure profiling are (i) an MRI suitable for cortical surface reconstruction (e.g. T1w) and (ii) a microstructure-sensitive volume (e.g. qT1, T1w/T2w, MT).

---

# 🚀 Toolbox features
- Generation and characterisation of intracortical microstructure profiles
- Co-registration of microstructural images to cortical surfaces
- Flexible adaptation of sampling precision
- Versatile application to different modalities (even 3D histology)
- (Optional) Computation of bias-corrected T1w/T2w images
- (Optional) Cortical surface reconstruction

---

## 📦 Dependencies

To simplify the installation of dependencies, the toolbox uses the micapipe container, which contains software, such as ANTS, FSL and several python packages. 

- **Singularity** installed and available on `$PATH` ([see installation instructions here](https://sylabs.io/guides/latest/user-guide/))
- FreeSurfer with valid `license.txt` ([Download it here](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall))
- Necessary container: [`micapipe-v0.2.3.simg`](https://micapipe.readthedocs.io/en/latest/pages/01.install/index.html)
- Optional container: [`fastsurfer_gpu.sif`](https://deep-mi.org/FastSurfer/dev/overview/singularity.html) (if FreeSurfer output is missing)

---

## 🔧 General usage

```
# Run from top directory of this cloned github repo
./microstructure_profiling.sh \
  --subject-id sub-001 \
  --subjects-dir /path/to/subjects_dir/ \
  --output-dir /path/to/output/ \
  --fs-dir /path/to/freesurfer/ \
  --sing-dir /path/to/singularity/ \
  [--micro-image /path/to/micro.nii.gz] \
  [--anat-dir /path/to/bids/sub-001/anat/] \
  [--num-surfaces 14] \
  [--surface-output fsaverage] \
  [--ratio-type T2w]```

#Required Arguments
--subject-id	        Subject identifier (e.g., sub-001)
--subjects-dir	      Path to FreeSurfer-style SUBJECTS_DIR
--output-dir	        Output directory for results
--fs-dir	            Path to FreeSurfer (must contain license.txt)
--sing-dir	          Path to Singularity images (should be the parent directory, that directory must contain micapipe-v0.2.3.simg)

# Optional Arguments
--micro-image	        Precomputed microstructure image (T1w/T2w)
--anat-dir	          BIDS anatomical directory (needed if --micro-image is not provided or surfaces need to be created)
--num-surfaces	      Number of intracortical surfaces (default: 14)
--surface-output      Name of standard surface for output, currently compatible with any fsaverage (default: fsaverage5) surface or fsnative
--ratio-type          Type of image for ratio with T1w (default: T2w). In principle, accepts any BIDS suffix that is housed in anat
-h, --help	          Show help message
```

---

## 🧬 Example commands

```
# Set arguments
home_dir=/data/group/mune/shortmp/toolbox_test/
module load freesurfer/7.4
fs_dir=/opt/freesurfer/7.4/
sing_dir=/data/project/nspn/singularity/
subject_id=sub-001
anat_dir="$home_dir/A1/$subject_id/anat/"
subjects_dir="$home_dir/A1/fastsurfer/"
output_dir="$home_dir/A1/MP_output/"

cd /data/group/mune/shortmp/microstructure_profiling/

# Case 1: Full run (no preprocessing yet completed)
./microstructure_profiling.sh --anat-dir $anat_dir --subject-id $subject_id --subjects-dir $subjects_dir --output-dir $output_dir --fs-dir $fs_dir --sing-dir $sing_dir

# Case 2: Precomputed micro-image, but no FreeSurfer output available
./microstructure_profiling.sh --micro-image $micro_image --anat-dir $anat_dir --subject-id $subject_id --subjects-dir $subjects_dir --output-dir $output_dir --fs-dir $fs_dir --sing-dir $sing_dir

# Case 3: FreeSurfer output available, as well as a T1 and T2 (not yet a T1w/T2w)
./microstructure_profiling.sh --micro-image $micro_image --anat-dir $anat_dir --subject-id $subject_id --subjects-dir $subjects_dir --output-dir $output_dir --fs-dir $fs_dir --sing-dir $sing_dir

# Case 4: Freesurfer output and micro-image both already available
./microstructure_profiling.sh --micro-image $micro_image --subject-id $subject_id --subjects-dir $subjects_dir --output-dir $output_dir --fs-dir $fs_dir --sing-dir $sing_dir

```

---

## Output

The key outputs of the toolbox are two .csv files
- MP: represents changes in intensity down cortical depths (rows = depths, columns = vertices on fsaverage5)
- MPmoments: shape characterisation of the profiles based on moments (rows = u0-u4, columnes = vertices on fsaverage5)
