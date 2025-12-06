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
    path_str = mount_targets.join(' ')
    log.info "mount_targets: $mount_targets"

    """
    :
    # mksquashfs \$(realpath --relative-to ${workflow.workdir} $path_str) work.sqfs -no-strip
    """
}
