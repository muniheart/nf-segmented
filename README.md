# nf-segmented

This project was created to mitigate the inode limitation associated with certain HPC.  It runs a pipeline of
interest in a segmented execution to reduce the total number of inodes consumed by intermediate files ( workdir )
during the lifetime of a pipeline run.
It may be of interest to nextflow users who have limited storage resources, such as users of HPCs, or
those who want to run multiple pipelines on numerous or large datasets.  The functionality provided here 
is distinct from that provided by the nextflow setting of `'cleanup: true'`, which reduces inode pressure by removing
intermediate files ( workdir ) after a complete pipeline run. Here, inodes are reclaimed throughout the execution
of a pipeline.

# Introduction
A wrapper pipeline is used to run a pipeline of interest, referred to as
the nested pipeline.  The nested pipeline is run inside a singularity container in a recursive manner using
`process.scan`, an [experimental recursive method](https://github.com/nextflow-io/nextflow/discussions/2521), applied to a channel of maps, meta.
    meta = [ params: 'params.yaml', samplesheet: 'samplesheet.csv', databases: 'databases.csv' ]
Each meta map specifies the parameter file, samplesheet and databases file to be used for a
pipeline segment.  A sequence of meta maps can be constructed to,
- progressively enable pipeline functionality,
- select the samples processed per segment,
- select the tools and databases used per segment.

Processing of a segment is performed by workflow `iteration` which takes one input, `data`, and emits one value, a tuple,
`[ image, work ]`, where `work` is the path to a work-dir and `image` is the path to a squash-fs image of
that work-dir.

```nextflow
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
    ch_meta = Channel.fromPath( ...)

    iteration.scan( ch_meta )
}
```
Given the input channel,
```
ch_meta = [ meta_1, meta_2, meta_3 ]
```
the `iteration` workflow will be called 3 times with inputs and outputs,
```
input                                                           output
[ meta_1 ]                                                      [ image_1, work_1 ]
[ meta_2, [ image_1, work_1 ] ]                                 [ image_2, work_2 ]
[ meta_3, [ image_1, work_1 ], [ image_2, work_2 ] ]            [ image_3, work_3 ]
```
Maintaining validity of nextflow's cache for a pipeline requires that file paths recorded in the cache remain valid 
across resume runs.  This is accomplished here by mounting workdir images of prior segments to the container that runs
the nested pipeline and to the container of each containerized process of the nested pipeline.  Further, each image is mounted at the path of its source workdir.  The bind-mount directives are created in `conf/modules.config` and passed to
singularity via `process.containerOptions`.  The propagation of bind-mounts to nested containers
should be handled seamlessly by singularity and apptainer, but I found that this mechanism did not work reliably.
Instead, bind-mount directives are passed to each nested container through `containerOptions`.

# Requirements

Singularity or apptainer containerization is required to allow the mounting of squash-fs images.  The slurm executor is
used and must be enabled in the container.  [Squashfs-tools](https://github.com/plougher/squashfs-tools) is required for the creation of images.  The nested pipeline should be downloaded along with all required databases and datasets.

# Usage
Notes coming soon!

# Acknowledgements
I would like to thank [Mahesh Binzer-Panchal](https://github.com/mahesh-panchal) for sharing his project [nf-cascade](https://github.com/mahesh-panchal/nf-cascade) which provided the seed for this project.
