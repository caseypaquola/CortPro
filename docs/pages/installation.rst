.. _installation:

.. title:: How to install CortPro

Installation
=================

CortPro is designed to run within containerised environments to simplify dependency management.  
The toolbox relies on the **micapipe** container, along with FreeSurfer and Singularity.

-------------------------------------------------------------------------------

System requirements
-------------------

- **Operating system**: Linux or MacOS
- **Hardware**: multi-core CPU; GPU optional (for FastSurfer acceleration)  
- **Disk space**: depends on input MRI resolution and number of subjects  
- **Memory**: 16 GB RAM recommended  

-------------------------------------------------------------------------------

Dependencies
-------------------

To run CortPro, you will need:

1. **Singularity**  
   - Must be installed and available on ``$PATH``.  
   - See official installation instructions: `<https://docs.sylabs.io/guides/3.0/user-guide/installation.html>`_.

2. **FreeSurfer**  
   - Required for cortical surface reconstruction and alignment procedures.  
   - A valid ``license.txt`` must be present in your FreeSurfer directory.  
   - Download FreeSurfer: `<https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall>`_.

3. **Singularity images**  
   - Required container: ``cortpro.sif``  (see how to download below) 
   - Optional container: ``fastsurfer_gpu.sif`` (for when FreeSurfer outputs are missing).  

-------------------------------------------------------------------------------

Quick setup
-------------------

1. **Clone the repository**

.. code-block:: bash

   git clone https://github.com/yourusername/CortPro.git
   cd CortPro

2. **Set up environment variables**

Make sure your environment can find FreeSurfer. For example:

.. code-block:: bash

   # depends on your system, but for example:
   module load freesurfer/7.4
   export FREESURFER_HOME=/opt/freesurfer/7.4/
   source $FREESURFER_HOME/SetUpFreeSurfer.sh

3. **Download containers**

.. code-block:: bash

   # provide the location of your singularity images
   sing_dir=/data/singularity

   # download the cortpro image
   singularity pull ${sing_dir}/cortpro.sif docker://ghcr.io/caseypaquola/cortpro:latest

   # ensure cortpro.sif and (optional) fastsurfer_gpu.sif are present in the directory
   ls -l $sing_dir

-------------------------------------------------------------------------------

Verifying installation
-----------------------

After setup, try running the help command:

.. code-block:: bash

   ./microstructure_profiling.sh --help

If the script runs and prints the usage information, your installation is complete 🎉  

-------------------------------------------------------------------------------

Troubleshooting
-------------------

- **Singularity not found** → Ensure it is installed and available on your ``$PATH``.  
- **FreeSurfer license error** → Place a valid ``license.txt`` inside your FreeSurfer directory.  
- **Container not found** → Check that ``micapipe-v0.2.3.simg`` is in the directory specified by ``--sing-dir``.  
- **GPU errors with FastSurfer** → Confirm CUDA drivers are correctly installed and match your hardware.  

-------------------------------------------------------------------------------

Next steps
-------------------

- Learn how to run the pipeline in :doc:`usage <usage>`  
