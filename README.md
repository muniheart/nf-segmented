# nf-segmented

Run a pipeline in segments to reduce the total number of inodes consumed.  This could be useful to nextflow users with 
limited file system resources, for example HPC users.

# Introduction

This project provides a wrapper pipeline that can be used to run another pipeline of interest, referred to hereafter as
the nested pipeline.  The nested pipeline is run in a recursive manner using the process.scan method applied to a
channel of pipeline parameter files.
On an initial run of the nested pipeline, the workdir is set to `work_1`.  Upon termination, a squash-fs image, `work_1.sqfs`,
of the workdir is created.  On the second run, this image is mounted at its path
of origin, `-resume` is passed to enable retrieval of task results contained in the workdir image, and the workdir is
set to `work_2`.  The nested pipeline is advanced in this manner, consuming the channel of parameter files
and producing workdir images.

Once an image is created, the workdir contents can be removed to release inodes.
 
# Requirements

Singularity or apptainer containerization is required to allow the mounting of squash-fs images.  The slurm executor is
used and must be enabled in the container.  Required databases and datasets should be locally available and paths in the
database.csv file should indicate the locations of decompressed databases.

# Acknowledgements
I would like to thank @mahesh-panchal for sharing his project `nf-cascade` which provided the seed for this project.
