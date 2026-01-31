import java.io.File;

process INIT_WORK_IMAGE {

    exec:
    assert ( params.work_image != null && params.work_image != '' ) : "params.work_image: $params.work_image"
    image = new File( "$params.work_image" )
    if ( ! workflow.resume || ! image.exists() ) {
        cmd = "rm -f $params.work_image && cd $workflow.workDir && mksquashfs . $params.work_image -e \"... *\""
        file("$task.workDir/mksquashfs-cmd.sh").text = cmd
        cmd.execute()
    }
}
