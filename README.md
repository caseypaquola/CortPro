# 🧠 Microstructure Profiling Toolbox

The **Microstructure Profiling Toolbox** is an open-source pipeline for generating and analyzing intracortical microstructural profiles using anatomical MRI. It automates surface reconstruction, intracortical surface generation, microstructure image processing, and profile sampling. Designed with reproducibility and flexibility in mind, the toolbox leverages tools like FreeSurfer, Fastsurfer, and Singularity-based containers.

---

## 🚀 Features

- Automatic generation of T1w/T2w ratio images
- Fastsurfer-based surface reconstruction (if FreeSurfer data is missing)
- Generation of intracortical equivolumetric surfaces
- Co-registration of microstructural images to cortical surfaces
- Sampling of microstructure across cortical depths
- Projection to standard space (`fsaverage5`)
- Extraction of statistical moments from profiles

---

## 📦 Requirements

- **Singularity** installed and available on `$PATH` [Install instructions](https://sylabs.io/guides/latest/user-guide/)
- FreeSurfer with valid `license.txt` [Download](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall)
- Singularity container: `micapipe-v0.2.3.simg`
- Optional container: `fastsurfer_gpu.sif` (if FreeSurfer output is missing)

---

## 📂 Directory Structure

```text
toolbox_root/
├── microstructure_profiling.sh     # Main entry point
├── functions/                      # Helper scripts (e.g., compute_t1t2_ratio.sh, run_fastsurfer.sh)
├── micapipe-v0.2.3.simg            # Singularity image
└── README.md                       # You're here

---

## 🔧 Usage

```bash microstructure_profiling.sh \
  --subject-id sub-001 \
  --subjects-dir /path/to/subjects_dir \
  --output-dir /path/to/output \
  --fs-dir /path/to/freesurfer \
  --sing-dir /path/to/singularity \
  [--micro-image /path/to/micro.nii.gz] \
  [--anat-dir /path/to/bids/anat] \
  [--num-surfaces 14]```

#Required Arguments
--subject-id	Subject identifier (e.g., sub-001)
--subjects-dir	Path to FreeSurfer-style SUBJECTS_DIR
--output-dir	Output directory for results
--fs-dir	Path to FreeSurfer (must contain license.txt)
--sing-dir	Path to Singularity images (must contain micapipe-v0.2.3.simg)

# Optional Arguments
--micro-image	Precomputed microstructure image (T1w/T2w)
--anat-dir	BIDS anatomical directory (needed if --micro-image is not provided or surfaces need to be created)
--num-surfaces	Number of intracortical surfaces (default: 14)
-h, --help	Show help message