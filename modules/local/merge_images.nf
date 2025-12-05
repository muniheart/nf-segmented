include { get_image_mount_args } from "./get_inputs_from_data.nf"

process MERGE_IMAGES {
    input:
    val container_opts
    val data

    output:
    path 'work.sqfs'
    stdout

    script:
    // TaskPath.relativeize may mask Path.relativeize.  May need to cast to Path.
    workdirs = data.collect { a,b -> workflow.workDir.relativize( b ) }

    """
    mksquashfs ${workdirs.join(' ')} work.sqfs -no-strip
    """
}
