Myelin profiles: What to expect when applying CortPro to myelin-sensitive MRI
============================================================================

The aim of this tutorial is to provide a prototypical example of CortPro outputs, helping you understand what to expect when applying these tools to your own data.

The Exemplar Dataset
--------------------

For this tutorial, we utilize the **MICA-MICs dataset** (`Royer et al., 2022 <https://pubmed.ncbi.nlm.nih.gov/36109562/>`_), which can be accessed via the `Microstructural Marketplace <https://osf.io/e6f7d/overview>`_. This dataset serves as an ideal case for myelin-sensitive MRI because it features quantitative T1 (R1) maps. 

R1 is a well-validated marker for cortical myelin content. For a deeper understanding of the biophysical validation of R1 as a myelin marker, we highly recommend the work by `Stüber et al. (2014) <https://pubmed.ncbi.nlm.nih.gov/24607447/>`_.

Visualizing the Raw Profiles
----------------------------

At the most granular level, we begin with **intracortical profiles**. These represent the change in MRI signal within the cortical mantle from the pial surface to the white matter boundary.

At the vertex level, individual profiles can be quite varied (see below, left). If we apply a parcellation scheme to the data, these profiles become consistently smoother (see below, right).

.. image:: ./images/tutorial_profiles.png
   :height: 350px
   :align: center
   :alt: Comparison of vertex-wise vs. parcellated profiles

Quantifying Shape with Central Moments
---------------------------------------

To move from visual inspection to statistical analysis, CortPro surmises the shape of these profiles using **central moments**. This technique is inspired by classical histology work (`Schleicher, et al., 1999 <https://pubmed.ncbi.nlm.nih.gov/9918738/>`_) and provides a mathematical summary of the distribution of signal across depths. For a primer on the math, see the `Wikipedia entry on central moments <https://en.wikipedia.org/wiki/Central_moment>`_.

When projecting these moments onto the cortical surface, we observe specific spatial patterns:

*   **$\mu_0$ through $\mu_2$** (Mean, Standard Deviation, and Skewness) typically reveal unique patterns of spatial differentiation across the cortex.
*   **$\mu_3$ and $\mu_4$** (Kurtosis and beyond) often appear very similar to $\mu_2$ when using myelin-sensitive MRI.

.. note::
   **A Note on Resolution:** In histology, the high spatial resolution results in bumpy, highly differentiated profiles where higher moments provide unique information. In MRI, the profiles are smoother by nature. We retain these higher moments in the CortPro package for researchers working with ultra-high resolution data. 

At the individual subject level, vertex-wise maps (shown below on the fsLR 32k surface) are not inherently smooth. However, when averaging across a group (e.g., $n=40$), the large-scale biological patterns become strikingly apparent and spatially continuous.

.. image:: ./images/tutorial_moments.png
   :height: 350px
   :align: center
   :alt: Individual vs Group averaged moment maps

Numerical Distributions: What is "Normal"?
------------------------------------------

The numerical range of your moment values is highly dependent on your input data:

1.  **$\mu_0$ (The Mean):** This is tied to the intensity range of your image. Since we are using R1 here, $\mu_0$ values relate directly to $s^{-1}$ (the inverse of relaxation time).
2.  **Higher Moments:** These pertain to the depth distribution. In our default pipeline for myelin-sensitive MRI with 14 intracortical samples, **$\mu_1$** (the centroid) is usually balanced near the center (around depth 7). You can generally expect **$\mu_2$** to be roughly half the value of $\mu_1$.

.. image:: ./images/tutorial_distributions.png
   :height: 350px
   :align: center
   :alt: Statistical distribution of moments

.. note::
   **Exluding the medial wall:** Make sure you exclude the medial wall when inspecting the distributions, otherwise you'll see an abnormal spike in the histograms.

For a comprehensive breakdown of the sampling process and the mathematical framework behind these moments, please refer to our full paper in `Imaging Neuroscience <https://doi.org/10.1162/IMAG.a.1212>`_.
