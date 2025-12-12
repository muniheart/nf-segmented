process MERGE_IMAGES {
    input:
    val container_opts
    path images
    path mount_targets

    output:
    path 'work.sqfs'
    stdout

    script:
    """
    for t in ${mount_targets.join(' ')}; do
        wd=\$( realpath \$t --relative-to ${workflow.workDir} )
        ( \
            cd ${workflow.workDir} && \
            mksquashfs \$wd \$NXF_TASK_WORKDIR/work.sqfs -no-strip -recovery-path \$NXF_TASK_WORKDIR \
        )
    done
    for i in ${images.join(' ')}; do
        rm \$(realpath \$i)
    done
    """
}
