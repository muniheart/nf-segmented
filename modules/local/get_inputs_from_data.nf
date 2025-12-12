include { get_container_opts } from "./get_container_opts.nf"

/*
 *  val data                       // [ meta, [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ] intermediate
 *                                 // [       [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ] final
 *
 *  Each element data[i], i>0, is a pair: ( symlink to image of workdir, symlink to workdir ).
 *
 *  Call with 'resolve_source=false' to generate bind-mounts for NFCORE_DEMO container.
 *  Call with 'resolve_source=true' to generate bind-mounts for nested containers.
 *
 */
/*
 *  When resolving mount path relative to workdir of MERGE_IMAGES task ( final: true ), the evaluation of
 *  task.workdir must be delayed so it can be resolved relative to the proper task.  This is done using environment
 *  variable NXF_TASK_WORKDIR.
 *
 */
def get_image_mount_args( data, resolve_source=false, is_final=false )
{
    data.collect {
        a,b -> {
            src = resolve_source ? a.resolveSymLink() : a
            tgt = b.resolveSymLink()
            if ( is_final ) {
                tgt = [
                    "\\$NXF_TASK_WORKDIR",
                    workflow.workDir.relativize( tgt )
                ].join('/')
            }
            "$src:$tgt:image-src=/"
        }
    }.join(",")
}

/*
 *  Given recursive output, data, as described below, return the params_file, contained in the first
 *  element, meta.  Nextflow does not allow a process task to output a path that lies outside the task's
 *  workdir, so the list of paths is output as val type.
 *
 */
process GET_INPUTS_FROM_DATA {
    input:
    val data                       // [ meta, [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ] intermediate
                                   // [       [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ] final

    exec:
    log.info "GET_INPUTS_FROM_DATA: data: $data"
    pfile = data[0].params_file
    ss = data[0].samplesheet
    images = data.tail().collect { a,b -> a }
    workdirs = data.tail().collect { a,b -> b }
    image_mounts = [
        relative: get_image_mount_args( data.tail() ),
        absolute: get_image_mount_args( data.tail(), resolve_source=true ),
        final: get_image_mount_args( data.tail(), is_final=true )
    ]

    image_param = "${image_mounts.absolute}" ? "--image_mounts ${image_mounts.absolute}" : ''

    if ( params.define_workdir_vars ) {
        // Create BASH env file that defines a variable for each work-dir.
        key_val_strs = data.subList( 1, data.size() ).withIndex()
            .collect { a, index -> "wk${index+1}=${a[1].resolveSymLink()}" }.join(" ")
    
        work_env = file( "${task.workDir}/work.env" )
        work_env.text = key_val_strs
    } else {
        work_env = null
    }
    container_opts = get_container_opts( image_mounts, work_env, task.ext.is_final )

    output:
    val pfile,          emit: params_file
    val ss,             emit: samplesheet
    val images,         emit: images
    val workdirs,       emit: workdirs
    val image_mounts,   emit: image_mounts
    val image_param,    emit: image_param
    val work_env,       emit: work_env
    val container_opts, emit: container_opts
}
