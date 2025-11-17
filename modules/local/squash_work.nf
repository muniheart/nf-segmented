process SQUASH_WORK {
    input:
    path work_dir_parent

    output:
    tuple path(image), path(work_dir_parent, includeInputs: true)

    script:
    image = "${work_dir_parent}.sqfs"

    """
    mksquashfs ${work_dir_parent} ${image} -no-compression

    # params.keep_workdir: ${params.keep_workdir}
    if ! ( ${params.keep_workdir } ); then
        # Remove contents of work-dir.
        rm -rf ${work_dir_parent}/nested/*
    fi
    """
}
