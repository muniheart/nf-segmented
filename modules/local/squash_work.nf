process SQUASH_WORK {
    input:
    path work_dir_parent

    output:
    val "$task.ext.work_image"

    script:
    log.info "SQUASH_WORK: work_dir_parent: $work_dir_parent"
    if ( false ) {
    src = workflow.workdir.relativize( work_dir_parent )
    log.info "SQUASH_WORK: src: $src"
    """
    cd ${workflow.workDir}
    mksquashfs $src $task.ext.work_image -no-compression

    # params.keep_workdir: ${params.keep_workdir}
    if ! ( ${params.keep_workdir } ); then
        # Remove contents of work-dir.
        rm -rf ${work_dir_parent}/decouple_hash/*
    fi
    """
    } else {
    """
    :
    """
    }
}
