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
    val samplesheet                    // pipeline samplesheet
    val databases                      // pipeline databases sheet
    val additional_config              // custom configs
//  path outdir, name: 'results'        // create link to params.outdir
    val cache_dir                       // common nextflow cache-dir for all tasks
    val env_file                        // file with env var strings defining workdir paths.
    val workdirs                        // previous tasks' workdirs.
    val params_file                     // params-file, extracted from data[0].
    val image_param                     // absolute and relative image mount specs.
    val container_opts                  // precomputed string of containerOptions.
    val data                            // [ meta, [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ]

    script:
    log.info "task.ext.args: ${task.ext.args}"
    log.info "task.ext: ${task.ext}"
    def meta = data[0]
    def i = task.index
    log.info "NEXTFLOW_RUN: task: ${task}"
    log.info "NEXTFLOW RUN: i: ${i}"
    workdir = "work_${i}"
    nextflow_opts += " -w $workdir"
    nextflow_opts += params.dump_hashes ? " -dump-hashes json" : ""
    nextflow_opts += i>1 ? " -resume" : ""
    child_outdir = "results/${task.process.split(':')[-1].toLowerCase()}" 

//  log.info "as_list(data): ${as_list(data)}"

    databases   = meta.containsKey( 'databases'   ) && meta.databases   ? meta.databases   : databases

    // Construct nextflow command
    def nxf_cmd = [
        'nextflow -log nextflow.log run',
            nextflow_opts,
            pipeline_name,
            params_file ? "-params-file ${params_file}" : '',
            additional_config ? additional_config.split(/\s+/).collect { "-c $it" }.join(' ') : '',
            samplesheet ? "--input $samplesheet" : '',
            databases ? "--databases $databases" : '',
            "--outdir $child_outdir",
            "${image_param}"
    ].join(" ")

    log.info "workflow: ${workflow}"

    """
    echo ${params.slurm.passwd_line} >> /etc/passwd
    echo ${params.slurm.group_line} >> /etc/group

    alias nextflow=/usr/local/bin/nextflow

    $nxf_cmd
    """

    stub:
    """
    echo "${task.process}: stub"
    mkdir -p ${workdir}/ab/cdef012
    touch nextflow.log
    """

    output:
    path "$workdir", emit: work_dir
    stdout emit: log
    path 'nextflow.log'
}
