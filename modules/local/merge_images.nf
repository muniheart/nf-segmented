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
    """
    mksquashfs \$(realpath --relative-to ${workflow.workdir} *) work.sqfs -no-strip
    """
}
