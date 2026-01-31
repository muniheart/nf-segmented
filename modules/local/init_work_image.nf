import java.io.File;

process INIT_WORK_IMAGE {

    output:
    val task.ext.work_image

    exec:
    image = new File( "$task.ext.work_image" )
    if ( ! workflow.resume || ! image.exists() ) {
        cmd = "rm -f $image && cd $workflow.workDir && mksquashfs . $image -e \"... *\""
        file("$task.workDir/mksquashfs-cmd.sh").text = cmd
        cmd.execute()
    }
}
