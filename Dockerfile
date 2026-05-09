# Adapted from Neurodocker and Reproenv.
FROM debian:bullseye-slim

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"

RUN export ND_ENTRYPOINT="/neurodocker/startup.sh" \
    && apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           apt-utils \
           bzip2 \
           ca-certificates \
           curl \
           locales \
           unzip \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG="en_US.UTF-8" \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> "$ND_ENTRYPOINT" \
    &&   echo 'set -e' >> "$ND_ENTRYPOINT" \
    &&   echo 'export USER="${USER:=`whoami`}"' >> "$ND_ENTRYPOINT" \
    &&   echo 'if [ -n "$1" ]; then "$@"; else /usr/bin/env bash; fi' >> "$ND_ENTRYPOINT"; \
    fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker

# --- FSL SETUP ---
ENV FSLDIR="/opt/fsl-6.0.7.1" \
    PATH="/opt/fsl-6.0.7.1/bin:$PATH" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLTCLSH="/opt/fsl-6.0.7.1/bin/fsltclsh" \
    FSLWISH="/opt/fsl-6.0.7.1/bin/fslwish" \
    FSLGECUDAQ="cuda.q"

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           bc ca-certificates curl dc file libfontconfig1 libfreetype6 \
           libgl1-mesa-dev libgl1-mesa-dri libglu1-mesa-dev libgomp1 \
           libice6 libopenblas0 libxcursor1 libxft2 libxinerama1 \
           libxrandr2 libxrender1 libxt6 nano python3 sudo wget \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Installing FSL ..." \
    && curl -fsSL https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py | python3 - -d /opt/fsl-6.0.7.1 -V 6.0.7.1

# --- ANTs SETUP ---
ENV ANTSPATH="/opt/ants-2.4.3/" \
    PATH="/opt/ants-2.4.3:$PATH"
RUN curl -fsSL -o ants.zip https://github.com/ANTsX/ANTs/releases/download/v2.4.3/ants-2.4.3-centos7-X64-gcc.zip \
    && unzip ants.zip -d /opt && mv /opt/ants-2.4.3/bin/* /opt/ants-2.4.3 && rm ants.zip

# --- PYTHON & NEUROMAPS SETUP ---

# 1. System requirements
RUN apt-get update -qq && apt-get install -y -q --no-install-recommends \
    bzip2 ca-certificates curl libglib2.0-0 libxext6 libsm6 libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Miniforge (Miniconda + Mamba pre-installed)
# This avoids the "conda install mamba" failure entirely.
RUN curl -fsSL -o /tmp/miniforge.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
    && bash /tmp/miniforge.sh -b -p /opt/miniforge \
    && rm -f /tmp/miniforge.sh

# 3. Create the environment using Mamba directly
# Removing strict pins on minor versions to allow the solver to breathe
RUN /opt/miniforge/bin/mamba create -n cortpro -y \
    python=3.9 \
    numpy=1.26 \
    pandas=2.2 \
    scipy=1.11 \
    scikit-learn=1.3

# 4. Install Neuro packages using the env-specific pip
RUN /opt/miniforge/envs/cortpro/bin/pip install --no-cache-dir \
    nibabel==5.2.1 \
    nilearn==0.10.4 \
    neuromaps==0.0.5 \
    packaging

# 5. Set Path and Python Shield
ENV PATH="/opt/miniforge/envs/cortpro/bin:$PATH" \
    PYTHONNOUSERSITE=1

# 6. Cleanup
RUN /opt/miniforge/bin/mamba clean --all --yes

ENTRYPOINT ["/neurodocker/startup.sh"]
