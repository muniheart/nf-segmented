import java.io.File;

process INIT_WORK_IMAGE {

    exec:
    image = new File( params.work_image )
    if ( ! ( workflow.resume && image.exists() ) {
        cmd = "mksquashfs ${workflow.workDir} ${params.work_image} -e \"... *\""
        file("$task.workDir/mksquashfs-cmd.sh").text = cmd
        cmd.execute()
    }
}
