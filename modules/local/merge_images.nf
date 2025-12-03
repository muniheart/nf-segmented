include { get_image_mount_args } from "./get_inputs_from_data.nf"

process MERGE_IMAGES {
    input:
    val data

    output:
    path 'work.sqfs'
    stdout

    script:
    image_mounts = get_image_mount_args( data, resolve_source=true )

    // TaskPath.relativeize may mask Path.relativeize.  May need to cast to Path.
    workdirs = data.collect { a,b -> workflow.workDir.relativize( b ) }

    """
    echo mksquashfs ${workdirs.join(' ')} work.sqfs
    """
}
