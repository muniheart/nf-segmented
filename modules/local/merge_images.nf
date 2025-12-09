process MERGE_IMAGES {
    input:
    val container_opts
    path mount_targets

    output:
    path 'work.sqfs'
    stdout

    script:
    x = mount_targets.collect { it.toRealPath() }
    rel_paths = x.collect { workflow.workDir.resolve( it ).toString() }.join(' ')
    """
    cd ${workflow.workDir}
    for i in ${x.join(' ')}; do
        wd=\$( realpath \$i --relative-to ${workflow.workDir} )
        mksquashfs \$wd \$NXF_TASK_WORKDIR/work.sqfs -no-strip -recovery-path \$NXF_TASK_WORKDIR
    done
    """
}
