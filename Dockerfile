# syntax = docker/dockerfile:1.3
# vim:foldmethod=marker:foldlevel=1:filetype=dockerfile

# We are using multi-staged builds.
# In the "build" image we are building a conda environment with everything we need inside
# We "pack" this environment using conda-pack and then copy it to the "runtime" image

# build
FROM continuumio/miniconda3 AS build

# redsymbol.net/articles/unofficial-bash-strict-mode/
SHELL ["/bin/bash", "-xeuo", "pipefail", "-c"]

# Install mamba since this will make the creation of the environment faster
# This will not increase the size of the final image due to the multi-stage build
RUN conda install -c conda-forge -y mamba
RUN mamba install -c conda-forge -y conda-pack

# Create the environment:
COPY environment.yml .
RUN mamba env create -f environment.yml

# Use conda-pack to create a standalone environment
# in /venv:
RUN conda-pack -n pyposeidon -o /tmp/env.tar; \
    mkdir /venv; \
    cd /venv; \
    tar xf /tmp/env.tar; \
    rm /tmp/env.tar

# The runtime-stage image;
FROM debian:11.2 AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1

# redsymbol.net/articles/unofficial-bash-strict-mode/
SHELL ["/bin/bash", "-xeuo", "pipefail", "-c"]

# Configure apt
# We keep downloaded packages because we will be mounting /var/cache/apt and /var/lib/apt as caches
RUN echo 'APT::Install-Recommends "false";' | tee -a /etc/apt/apt.conf.d/99-install-suggests-recommends; \
    echo 'APT::Install-Suggests "false";' | tee -a /etc/apt/apt.conf.d/99-install-suggests-recommends; \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache; \
    rm -f /etc/apt/apt.conf.d/docker-clean; \
    echo 'Configuring apt: OK';

# Copy /venv from the previous stage:
COPY --from=build /venv /venv

# install xvfb tini and gosu
RUN --mount=type=cache,target=/var/cache/apt,id=var_cache_apt \
    --mount=type=cache,target=/var/lib/apt,id=var_lib_apt \
    apt update; \
    apt install -yq \
        gosu \
        libgl1-mesa-glx \
        tini \
        xvfb \
    ; \
    apt autoremove --purge -y; \
    echo 'apt install: OK'

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
