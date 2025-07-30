# nf-segmented

This project was created to mitigate the inode limitation associated with some HPC.  It runs a pipeline of
interest in a segmented execution to reduce the total number of inodes consumed by intermediate files ( workdir )
during the lifetime of a pipeline run.
It may be of interest to nextflow users who have limited file system resources, such as users of HPC, or
users that want to run multiple pipelines on numerous or large datasets.  The functionality provided here 
is distinct from that provided by the nextflow setting of 'cleanup: true', which reduces inode pressure by removing
intermediate files ( workdir ) after a complete pipeline run: here, inodes are reclaimed throughout the execution
of a pipeline.

# Introduction
A wrapper pipeline is used to run a pipeline of interest, referred to as
the nested pipeline.  The nested pipeline is run inside a singularity container in a recursive manner using the
process.scan method applied to a channel of pipeline parameter files.
Segmentation of the nested pipeline is defined by the sequence of input parameter files
which is constructed to
progressivly enables pipeline functionality.  Execution of
a segment is performed by workflow `iteration` which takes one input, `data`, and emits one value, a file-system
image.

workflow iteration {
    input:
    data

    // Run one segment of nested pipeline.
    NFCORE_DEMO(data,...)

    // Create SquashFS image of workdir.
    SQUASH_WORK( NFCORE_DEMO.out.work_dir )

    emit:
    SQUASH_WORK.out
}

workflow {
    // Read meta file into ch_params.
    ch_params = Channel.fromPath( ...)

    iteration.scan( ch_params )
}

The `process.scan` method is an experimental recursive method.
Given the input channel of,
ch_param = [ params_1.yaml, params_2.yaml, params_3.yaml ]
the `iteration` workflow will be called 3 times with these inputs and outputs:
input                                               output
params_1.yaml                                       work_1.sqfs
[ params_2.yaml, work_1.sqfs ]                      work_2.sqfs
[ params_3.yaml, work_1.sqfs, work_2.sqfs ]         work_3.sqfs

Mounting of workdir images of previous segments is handled in `conf/modules` where a bind-mount directive for
each image is added to the `containerOptions` that is passed to singularity.  Each workdir is bind-mounted
to the container at its path of origin, maintaining the integrity of the cache.

# Requirements

Singularity or apptainer containerization is required to allow the mounting of squash-fs images.  The slurm executor is
used and must be enabled in the container.  [Squashfs-tools](https://github.com/plougher/squashfs-tools) is required for the creation of images.  The nested pipeline should be downloaded along with all required databases and datasets.

# Acknowledgements
I would like to thank [Mahesh Binzer-Panchal](https://github.com/mahesh-panchal) for sharing his project [nf-cascade](https://github.com/mahesh-panchal/nf-cascade) which provided the seed for this project.
