
.. **CortPro**
   ============================
.. title:: CortPro: Your cortical profiling toolbox

.. raw:: html

   <style type="text/css">
      hr {
      width: 100%;
      height: 1px;
      background-color: #4e799e;
      margin-top: 24px;
      }
   </style>


**Welcome to CORTPRO**
==========================================

🧠 CortPro (**Cortical Profiler**) is an open-source toolbox for generating and analysing **intracortical microstructure profiles**.  
It provides a flexible framework to profile cortical depth-dependent signals across imaging modalities and resolutions—from MRI to 3D histology.

🚀 With only two inputs—an anatomical MRI suitable for cortical surface reconstruction (e.g., T1w) and a microstructure-sensitive image (e.g., qT1, T1w/T2w, MT)—CortPro enables reproducible microstructural mapping and advanced profiling workflows.

-------------------------------------------------------------------------------

What CortPro does
------------------
- Generation and characterisation of intracortical microstructure profiles  
- Co-registration of microstructural images to cortical surfaces  
- Flexible sampling precision (user-defined number of cortical depths)  
- Versatile across modalities (MRI, histology, etc.)  
- (Optional) Bias-corrected T1w/T2w images  
- (Optional) Cortical surface reconstruction  

**Key outputs include:**  
- ``MP.csv`` → intensity changes across cortical depths (rows = depths, columns = vertices)  
- ``MPmoments.csv`` → shape characterisation of profiles based on statistical moments (u0–u4)  

-------------------------------------------------------------------------------

Tips for Getting Started
****************************

* Review the :doc:`installation instructions <pages/installation>` to set up dependencies (Singularity, FreeSurfer, micapipe).  
* Check the :doc:`general usage guide <pages/usage>` for command-line examples.  
* Explore tutorials to see practical workflows and applications across different modalities.  
* Reach out if you have questions, suggestions, or want to contribute 🤙  

-------------------------------------------------------------------------------

.. raw:: html

   <br>


.. toctree::
   :maxdepth: 1
   :hidden:
   :caption: Getting started
   
   pages/usage


__________________________________________________________________________________________________

.. raw:: html

   <br>


Core developers 
------------------

- Casey Paquola, INM-7, Forschungszentrum Jülich (`<https://multiscale-neurodevelopment.github.io/>`_)
