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
//  path_str = mount_targets.join(' ')
//  log.info "path_str: $path_str"
//  log.info "mount_targets: $mount_targets"
//  mount_targets.each { log.info "mount_targets: ${it.getClass()}; $it" }
    rel_paths = mount_targets.collect { workflow.workDir.resolve( it ) }.join(' ')
    if ( false ) {
    """
    ls -ld *
    touch work.sqfs
    """
    } else {
    """
    echo "mksquashfs $rel_paths work.sqfs -no-strip"
    touch work.sqfs
    """
    }
}
