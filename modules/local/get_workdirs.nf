/*
 *  Given recursive output, data, as described below, return a list of task workdirs.  Nextflow does
 *  not allow a process task to output a path that lies outside the task's workdir, so the list of paths
 *  is output as val type.
 *
 */
process GET_WORKDIRS {
    input:
    val data                       // [ meta, [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ]

    exec:
    workdirs = data.tail().collect { a,b -> b }

    output:
    val workdirs                    // [ work_1, work_2, ..., work_{i-1} ]
}

