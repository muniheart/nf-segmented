/*
 *  val data                       // [ meta, [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ]
 *
 *  Each element data[i], i>0, is a pair: ( symlink to image of workdir, symlink to workdir ).
 *
 *  Call with 'resolve_source=false' to generate bind-mounts for NFCORE_DEMO container.
 *  Call with 'resolve_source=true' to generate bind-mounts for nested containers.
 *
 */
def get_image_mount_args( data, resolve_source=false )
{
    data.tail()
    .collect { a,b -> "${ resolve_source ? a.resolveSymLink() : a }:${b.resolveSymLink()}:image-src=/" }
    .join(",")
}

/*
 *  Given recursive output, data, as described below, return the params_file, contained in the first
 *  element, meta.  Nextflow does not allow a process task to output a path that lies outside the task's
 *  workdir, so the list of paths is output as val type.
 *
 */
process GET_INPUTS_FROM_DATA {
    input:
    val data                       // [ meta, [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ]

    exec:
    log.info "GET_INPUTS_FROM_DATA: data: $data"
    pfile = data[0].params_file // data.head().collect { a -> a.params_file }
    ss = data[0].samplesheet // data.head().collect { a -> a.params_file }
    workdirs = data.tail().collect { a,b -> b }
    image_mounts = [
        relative: get_image_mount_args( data ),
        absolute: get_image_mount_args( data, true )
    ]
    
    output:
    val pfile,          emit: params_file
    val ss,             emit: samplesheet
    val workdirs,       emit: workdirs
    val image_mounts,   emit: image_mounts
}
