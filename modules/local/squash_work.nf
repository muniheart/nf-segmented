process SQUASH_WORK {
    input:
    val work_dir_parent             // Use val type to get absolute path.

    output:
    val task.ext.work_image

    script:
    // Create path to work_image, if non-existent.
    file( task.ext.work_image ).getParent().mkdirs()

    // Get path of image source, relative to workflow workdir.
    src = workflow.workDir.relativize( work_dir_parent )

    cmd = [
        "cd $workflow.workDir",
        "mksquashfs $src $task.ext.work_image",
        params.keep_workdir ? null : "rm -rf $src/decouple_hash/*"
    ].findAll().join(" && ")

    """
    $cmd
    """
}
