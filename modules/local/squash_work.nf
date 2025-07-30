process SQUASH_WORK {
    input:
    path work_dir

    output:
    path image

    script:
    image = "${work_dir}.sqfs"

    """
    mksquashfs ${work_dir}/* ${image} -no-compression

    # params.keep_workdir: ${params.keep_workdir}
    if ! ( ${params.keep_workdir } ); then
        # Remove contents of work-dir.
        rm -rf ${work_dir}/*
    fi
    """
}
