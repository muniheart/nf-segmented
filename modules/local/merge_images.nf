process MERGE_IMAGES {
    input:
    val container_opts
    path mount_targets

    output:
    path 'work.sqfs'
    stdout

    script:
    """
    for i in ${mount_targets.join(' ')}; do
        wd=\$( realpath \$i --relative-to ${workflow.workDir} )
        ( \
            cd ${workflow.workDir} && \
            mksquashfs \$wd \$NXF_TASK_WORKDIR/work.sqfs -no-strip -recovery-path \$NXF_TASK_WORKDIR \
        )
    done
    """
}
