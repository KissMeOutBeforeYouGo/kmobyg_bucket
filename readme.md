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
