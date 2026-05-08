.. _usage:

How to use CortPro
==================

CortPro is run via a single shell script, ``microstructure_profiling.sh``.
This script orchestrates preprocessing, intracortical surface sampling, and microstructure profiling.

-------------------------------------------------------------------------------

General command
---------------

.. code-block:: bash

   # Run from the top-level directory of the cloned repository
   ./microstructure_profiling.sh \
      --subject-id sub-001 \
      --subjects-dir /path/to/subjects_dir/ \
      --output-dir /path/to/output/ \
      --fs-dir /path/to/freesurfer/ \
      --sing-dir /path/to/singularity/ \
      [--micro-image /path/to/micro.nii.gz] \
      [--anat-dir /path/to/bids/sub-001/anat/] \
      [--t1-file /path/to/T1w.nii.gz --t2-file /path/to/T2w.nii.gz] \
      [--ratio-type T2w] \
      [--skip-bias-correct] \
      [--keep-inter-files] \
      [--num-surfaces 14] \
      [--surface-output fsaverage5]

-------------------------------------------------------------------------------

Required arguments
------------------

+--------------------+-----------------------------------------------------------------+
| Argument           | Description                                                     |
+====================+=================================================================+
| ``--subject-id``   | Subject identifier (e.g., ``sub-001``).                         |
+--------------------+-----------------------------------------------------------------+
| ``--subjects-dir`` | Path to FreeSurfer-style ``SUBJECTS_DIR``.                      |
+--------------------+-----------------------------------------------------------------+
| ``--output-dir``   | Output directory for results.                                   |
+--------------------+-----------------------------------------------------------------+
| ``--fs-dir``       | Path to FreeSurfer installation (must contain ``license.txt``). |
+--------------------+-----------------------------------------------------------------+
| ``--sing-dir``     | Path to Singularity images (parent directory containing         |
|                    | ``micapipe-v0.2.3.simg``).                                      |
+--------------------+-----------------------------------------------------------------+

-------------------------------------------------------------------------------

Optional arguments
------------------

+--------------------------+------------------------------------------------------------+
| Argument                 | Description                                                |
+==========================+============================================================+
| ``--micro-image``        | Precomputed microstructure image (e.g., T1w/T2w).          |
+--------------------------+------------------------------------------------------------+
| ``--anat-dir``           | BIDS anatomical directory. Required if ``--micro-image``   |
|                          | is not provided or if surfaces need to be created.         |
+--------------------------+------------------------------------------------------------+
| ``--num-surfaces``       | Number of intracortical surfaces to sample (default: 14).  |
+--------------------------+------------------------------------------------------------+
| ``--surface-output``     | Standard surface space for output. Supports ``fsnative``   |
|                          | and ``fsaverage`` (default: ``fsaverage5``).               |
+--------------------------+------------------------------------------------------------+
| ``--ratio-type``         | Type of image to use for ratio with T1w (default: T2w).    |
+--------------------------+------------------------------------------------------------+
| ``--skip-bias-correct``  | Skip bias correction of T1w/T2w.                           |
+--------------------------+------------------------------------------------------------+
| ``--keep-inter-files``   | Keep all intermediarily produced files (the space eater).  |
+--------------------------+------------------------------------------------------------+
| ``--run-SNR``            | Compute intracortical SNR.                                 |
+--------------------------+------------------------------------------------------------+
| ``-h, --help``           | Display help message and exit.                             |
+--------------------------+------------------------------------------------------------+

-------------------------------------------------------------------------------

Example workflows
-----------------

**Case 1: Full run (no preprocessing yet completed)**

.. code-block:: bash

   ./microstructure_profiling.sh \
      --anat-dir $anat_dir \
      --subject-id $subject_id \
      --subjects-dir $subjects_dir \
      --output-dir $output_dir \
      --fs-dir $fs_dir \
      --sing-dir $sing_dir

**Case 2: Precomputed micro-image, no FreeSurfer output available**

.. code-block:: bash

   ./microstructure_profiling.sh \
      --micro-image $micro_image \
      --anat-dir $anat_dir \
      --subject-id $subject_id \
      --subjects-dir $subjects_dir \
      --output-dir $output_dir \
      --fs-dir $fs_dir \
      --sing-dir $sing_dir

-------------------------------------------------------------------------------

Outputs
-------

CortPro produces two key output files:

* **``MP.csv``**: Cortical depth × vertex matrix of microstructural intensity.
* **``MPmoments.csv``**: Statistical characterisation of profiles based on moments.


