process SQUASH_WORK {
    input:
    val work_dir_parent             // Use val type to get absolute path.

    output:
    val task.ext.work_image

    exec:
    // Create path to work_image, if non-existent.
    file( task.ext.work_image ).getParent().mkdirs()

    // Get path of image source, relative to workflow workdir.
    src = workflow.workDir.relativize( work_dir_parent )
    cmd = "mksquashfs $src $task.ext.work_image"
    file( "$task.workDir/mksquashfs.sh" ).text = cmd
    cmd.execute( null, workflow.workDir.toFile() )

    if ( ! params.keep_workdir ) {
        cmd = "rm -rf decouple_hash/*"
        file( "$task.workDir/mksquash.fs" ).append( cmd )
        cmd.execute( null, work_dir_parent.toFile() )
    }
}
