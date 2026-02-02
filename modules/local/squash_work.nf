process SQUASH_WORK {
    input:
    path work_dir_parent

    output:
    val "$task.ext.work_image"

    script:
    log.info "SQUASH_WORK: work_dir_parent: $work_dir_parent"
    log.info "SQUASH_WORK: task.ext.work_image: ${task.ext.work_image}"
    """
    image_dir=\$(dirname ${task.ext.work_image})
    mkdir -p \$image_dir
    cd ${workflow.workDir}
    mksquashfs $work_dir_parent ${task.ext.work_image} -no-compression

    # params.keep_workdir: ${params.keep_workdir}
    if ! ( ${params.keep_workdir } ); then
        # Remove contents of work-dir.
        rm -rf ${work_dir_parent}/decouple_hash/*
    fi
    """
}
