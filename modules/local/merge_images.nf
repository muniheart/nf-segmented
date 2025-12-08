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
    x = mount_targets.collect { it.toRealPath() }
//  y = mount_targets.collect { it.toAbsolutePath() }
    rel_paths = x.collect { workflow.workDir.resolve( it ).toString() }.join(' ')
    if ( false ) {
    """
    ls -ld *
    touch work.sqfs
    """
    } else {
    """
    for i in ${x.join(' ')}; do
        wd=\$( realpath \$i --relative-to ${workflow.workDir} )
        mksquashfs \$wd work.sqfs -no-strip
    done
    """
    }
}
