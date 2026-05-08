Quality Control
============================================================================

While CortPro is designed to be flexible and robust across diverse datasets, things can of course still do wrong. If your final moment maps look suspicious, or if you want to more closely inspect the internal processeses in the CortPro, here are some QC steps to start with.


Surface-to-Volume Alignment
-----------------------------------

The most common source of error in cortical profiling is a misalignment between your microstructural volume (e.g., T1w/T2w or R1 map) and the reconstructed cortical surfaces (pial and white matter boundaries). Even a sub-millimeter shift can lead to the sampling of cerebrospinal fluid (CSF) or white matter, significantly biasing your moments.

To inspect this alignment, we have provided a dedicated utility script:

.. code-block:: bash

    bash functions/qc_registration.sh $OUTPUT_DIR $SUBJECT_ID $SUBJECTS_DIR

.. note::
   **Parameter Note:** These variables ($OUTPUT_DIR, $SUBJECT_ID, and $SUBJECTS_DIR) should be the same as those used in your primary CortPro execution.

The script will automatically create a dedicated subfolder within your output directory:

``$OUTPUT_DIR/$SUBJECT_ID/QC/``

Inside this folder, you will find several ``.png`` files showing the surfaces overlaid on the microstructural volume at various anatomical slices (Axial, Sagittal, and Coronal).

*   **The Red Line (Pial Surface):** This should follow the outer boundary of the cortex, perfectly tracing the interface between the gray matter and the CSF.
*   **The Blue Line (White Matter Surface):** This should follow the "inner" boundary, tracing the transition from the base of the cortex into the underlying white matter.

.. image:: ./images/tutorial_qc_registration.png
   :height: 350px
   :align: center
   :alt: Example of successful surface-to-volume registration






