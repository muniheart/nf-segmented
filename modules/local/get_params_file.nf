/*
 *  Given recursive output, data, as described below, return the params_file, contained in the first
 *  element, meta.  Nextflow does not allow a process task to output a path that lies outside the task's
 *  workdir, so the list of paths is output as val type.
 *
 */
process GET_PARAMS_FILE {
    def params_file

    input:
    val data                       // [ meta, [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ]

    exec:
    log.info "GET_PARAMS_FILE: data: $data"
    params_file = data[0].params_file // data.head().collect { a -> a.params_file }

    output:
    val params_file
}
