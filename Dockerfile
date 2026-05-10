# 1. Base Image
FROM debian:bullseye-slim

# 2. Environment & Entrypoint Setup
ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh" \
    PYTHONNOUSERSITE=1

RUN apt-get update -qq && apt-get install -y -q --no-install-recommends \
           apt-utils bzip2 ca-certificates curl locales unzip wget gnupg2 software-properties-common \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG="en_US.UTF-8" \
    && mkdir -p /neurodocker \
    && echo '#!/usr/bin/env bash\nset -e\nif [ -n "$1" ]; then "$@"; else /usr/bin/env bash; fi' > "$ND_ENTRYPOINT" \
    && chmod -R 777 /neurodocker

# --- FSL 6.0.7.1 ---
ENV FSLDIR="/opt/fsl-6.0.7.1" \
    PATH="/opt/fsl-6.0.7.1/bin:$PATH" \
    FSLOUTPUTTYPE="NIFTI_GZ"
RUN apt-get update -qq && apt-get install -y -q --no-install-recommends \
    bc dc file libfontconfig1 libfreetype6 libgl1-mesa-dev libglu1-mesa-dev \
    libgomp1 libice6 libopenblas0 libxcursor1 libxft2 libxinerama1 \
    libxrandr2 libxrender1 libxt6 python3 sudo \
    && curl -fsSL https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py | python3 - -d /opt/fsl-6.0.7.1 -V 6.0.7.1 \
    && rm -rf /var/lib/apt/lists/*

# --- ANTs 2.4.3 ---
ENV ANTSPATH="/opt/ants-2.4.3/" \
    PATH="/opt/ants-2.4.3:$PATH"
RUN curl -fsSL -o ants.zip https://github.com/ANTsX/ANTs/releases/download/v2.4.3/ants-2.4.3-centos7-X64-gcc.zip \
    && unzip ants.zip -d /opt && mv /opt/ants-2.4.3/bin/* /opt/ants-2.4.3 && rm ants.zip

# --- WORKBENCH & PYTHON ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    connectome-workbench \
    python3.9 \
    python3.9-dev \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --- PYTHON DEPENDENCIES ---
RUN pip3 install --no-cache-dir \
    numpy>=1.26.0 \
    scipy>=1.11.0 \
    pandas>=2.2.0 \
    nibabel>=5.2.0 \
    nilearn>=0.10.0

ENTRYPOINT ["/neurodocker/startup.sh"]
