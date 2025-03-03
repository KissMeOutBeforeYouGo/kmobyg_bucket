# Bucket repo

This repository contains random unrelated stuff so I (and potentially someone else) can use them as reference. Note that all of them require modification in order to be actually usable as they were built for very specific tasks.

## Descriptions

You may find more in-depth explanations as comments in files directly.

**NOTE:** you can build ALSE (or any Debian derivative) basecontainer using `debootstrap`

- dockerfiles
    - *nvidia-astra-base.dockerfile:* basecontainer on top of Astra Linux Special Edition 1.7.5 set up to use Nvidia ML frameworks;
    - *nv-opencv.dockerfile:* another basecontainer built on top of *nvidia-astra-base* with OpenCV and FFmpeg configured to use Nvidia CUDA;

---

- bash-scripts:
    - *nvidia-get-cap.sh:* simple script used to convert ML models for different Nvidia GPUs;
    - *build-postgres.sh:* script for building PostgreSQL from source tarball on Astra Linux 1.7.5. Takes `-v` arg, where you specify version you want to build (defaults to 12.17)
    - *build-python.sh:* script for building Python3 from source tarball on Astra Linux 1.7.5. Takes `-v` arg, where you specify version you want to build (defaults to 3.8.18)
    - *bootstrap-postgres.sh:* simplest form of bootstrapping and running postgres inside the container. Tested on custom postgres build (12.17)
