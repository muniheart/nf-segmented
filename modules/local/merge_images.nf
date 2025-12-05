import java.nio.file.Path

include { get_image_mount_args } from "./get_inputs_from_data.nf"

process MERGE_IMAGES {
    input:
    val container_opts
    path mount_targets

    output:
    path 'work.sqfs'
    stdout

    script:
    // TaskPath.relativeize may mask Path.relativeize.  May need to cast to Path.
    rel_paths = mount_targets.collect { w -> workflow.workDir.relativize( w.toString() ) }

    """
    mksquashfs ${rel_paths.join(' ')} work.sqfs -no-strip
    """
}
