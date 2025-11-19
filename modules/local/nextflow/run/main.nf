/*
 * I can't find a container with both nextflow and squashfs-tools.  Using system installed squashfs-tools
 * causes PATH problems for nextflow.  I will use separate containers for the two tools.
 */
def as_list = { x -> x ? ( x instanceof List ? x : [x] ) : [] }

process NEXTFLOW_RUN {
    container "https://depot.galaxyproject.org/singularity/nextflow%3A25.04.6--h2a3209d_0"

    input:
    val pipeline_name                   // String
    val nextflow_opts                   // String
    path samplesheet                    // pipeline samplesheet
    val databases                      // pipeline databases sheet
    path additional_config, stageAs: 'nextflow.config'      // custom configs
//  path outdir, stageAs: 'results'     // create link to params.outdir
//  val cache_dir                       // common nextflow cache-dir for all tasks
    val env_file                        // file with env var strings defining workdir paths.
    path workdirs                       // previous tasks' workdirs.
    path params_file                    // params-file, extracted from data[0].
    val image_param                     // absolute and relative image mount specs.
    val container_opts                  // precomputed string of containerOptions.
    val data                            // [ meta, [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ]

    script:
//  log.info "task.ext.args: ${task.ext.args}"
//  log.info "task.ext: ${task.ext}"
    def meta = data[0]
    def i = task.index
//  log.info "NEXTFLOW_RUN: task: ${task}"
//  log.info "NEXTFLOW RUN: i: ${i}"

//  Place workdir at depth 2 so removal of its files won't invalidate task cache.
    workdir = "work_${i}/decouple_hash"
    nextflow_opts += " -w $workdir"
    nextflow_opts += params.dump_hashes ? " -dump-hashes json" : ""
    nextflow_opts += workflow.resume || i>1 ? " -resume" : ""

    task_name = task.process.split(':')[-1].toLowerCase()
    child_outdir = file( params.outdir ).resolve( task_name )
    log_file = child_outdir.resolve( ".${task_name}_${i}.log" )

//  log.info "as_list(data): ${as_list(data)}"

    databases   = meta.containsKey( 'databases'   ) && meta.databases   ? meta.databases   : databases

    // Construct nextflow command
    def nxf_cmd = [
        "nextflow -log $log_file run",
            nextflow_opts,
            pipeline_name,
            params_file ? "-params-file ${params_file}" : '',
            samplesheet ? "--input $samplesheet" : '',
            databases ? "--databases $databases" : '',
            "--outdir $child_outdir",
            "${image_param}"
    ].findAll().join(" ")

//  log.info "workflow: ${workflow}"

    """
    echo ${params.slurm.passwd_line} >> /etc/passwd
    echo ${params.slurm.group_line} >> /etc/group

    alias nextflow=/usr/local/bin/nextflow

    $nxf_cmd

    mksquashfs ${workdir}/* ${image} -no-compression

    if ! ( ${params.keep_workdir } ); then
        # Remove contents of work-dir.
        rm -rf ${workdir}/*
    fi
    """

    stub:
//  log.info "task.ext.args: ${task.ext.args}"
//  log.info "task.ext: ${task.ext}"
    def meta = data[0]
    def i = task.index
//  log.info "NEXTFLOW_RUN: task: ${task}"
//  log.info "NEXTFLOW RUN: i: ${i}"

//  Place workdir at depth 2 so removal of its files won't invalidate task cache.
    workdir = "work_${i}/decouple_hash"
    nextflow_opts += " -w $workdir"
    nextflow_opts += params.dump_hashes ? " -dump-hashes json" : ""
    nextflow_opts += workflow.resume || i>1 ? " -resume" : ""

    task_name = task.process.split(':')[-1].toLowerCase()
    child_outdir = file( params.outdir ).resolve( task_name )
    log_file = child_outdir.resolve( ".${task_name}_${i}.log" )

//  log.info "as_list(data): ${as_list(data)}"

    databases   = meta.containsKey( 'databases'   ) && meta.databases   ? meta.databases   : databases

    // Construct nextflow command
    def nxf_cmd = [
        "nextflow -log $log_file run",
            nextflow_opts,
            pipeline_name,
            params_file ? "-params-file ${params_file}" : '',
            additional_config ? additional_config.split(/\s+/).collect { "-c $it" }.join(' ') : '',
            samplesheet ? "--input $samplesheet" : '',
            databases ? "--databases $databases" : '',
            "--outdir $child_outdir",
            "${image_param}"
    ].findAll().join(" ")

//  log.info "workflow: ${workflow}"

    """
    echo "${task.process}: stub"
    mkdir -p ${workdir}/ab/cdef012
    touch nextflow.log $image
    """

    output:
    path "work_*", emit: work_dir_parent
    stdout emit: log
}
