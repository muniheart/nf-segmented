import java.nio.file.Path

include { get_image_mount_args } from "./get_inputs_from_data.nf"

process MERGE_IMAGES {
    input:
    val container_opts
    val mount_targets

    output:
    path 'work.sqfs'
    stdout

    script:
//  path_str = mount_targets.join(' ')
//  log.info "path_str: $path_str"
    log.info "mount_targets: $mount_targets"
//  mount_targets.each { log.info "mount_targets: ${it.getClass()}; $it" }

    """
    ls -ld *
    # mksquashfs \$(realpath --relative-to ${workflow.workdir} $path_str) work.sqfs -no-strip
    touch work.sqfs
    """
}
