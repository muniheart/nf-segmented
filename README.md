# nf-segmented

Run a pipeline in segments to reduce the total number of inodes consumed.  This could be useful to nextflow users with 
limited file system resources, for example HPC users.

# Introduction

This project provides a wrapper pipeline that can be used to run another pipeline of interest, referred to hereafter as
the nested pipeline.  The nested pipeline is run in a recursive manner using the `process.scan` method applied to a
channel of pipeline parameter files.
On an initial run of the nested pipeline, the workdir is set to `work_1`.  Upon termination, a squash-fs image, `work_1.sqfs`,
of the workdir is created.  On the second run, this image is bind-mounted to the container at its path
of origin, the workdir is set to `work_2`, and the nested pipeline is resumed.  Task results that were cached on the previous run are retrieved from the mounted image.  On subsequent runs, all images from prior runs are bind-mounted to the container, each at its path of origin, to enable retrieval of cached results.  The nested pipeline is advanced in this manner, consuming the channel of parameter files and producing workdir images.

The savings in inodes of this scheme can be realized once a workdir image has been created.  The workdir contents can be removed to release the storage space and its allocated inodes.
 
# Requirements

Singularity or apptainer containerization is required to allow the mounting of squash-fs images.  The slurm executor is
used and must be enabled in the container.  [Squashfs-tools](https://github.com/plougher/squashfs-tools) is required for the creation of images.  The nested pipeline should be downloaded along with all required databases and datasets.

# Acknowledgements
I would like to thank [Mahesh Binzer-Panchal](https://github.com/mahesh-panchal) for sharing his project [nf-cascade](https://github.com/mahesh-panchal/nf-cascade) which provided the seed for this project.
