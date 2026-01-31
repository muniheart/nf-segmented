process SQUASH_WORK {
    input:
    path work_dir_parent

    output:
    val task.ext.work_image

    script:
    src = workflow.workdir.relativize( work_dir_parent )
    """
    cd ${workflow.workDir}
    mksquashfs $src $task.ext.work_image -no-compression

    # params.keep_workdir: ${params.keep_workdir}
    if ! ( ${params.keep_workdir } ); then
        # Remove contents of work-dir.
        rm -rf ${work_dir_parent}/decouple_hash/*
    fi
    """
}
