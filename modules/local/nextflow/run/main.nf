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
    path databases                      // pipeline databases sheet
    path additional_config              // custom configs
    path outdir, name: 'results'        // create link to params.outdir
    path cache_dir                      // common nextflow cache-dir for all tasks
    path env_file                       // file with env var strings defining workdir paths.
    val data                           // [ meta, [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ]

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

    log.info "as_list(data): ${as_list(data)}"

    image_param = "${task.ext.image_mounts_absolute}" ? "--image_mounts ${task.ext.image_mounts_absolute}" : ''
    log.info "image_param: ${image_param}"

    samplesheet = meta.containsKey( 'samplesheet' ) && meta.samplesheet ? meta.samplesheet : samplesheet
    databases   = meta.containsKey( 'databases'   ) && meta.databases   ? meta.databases   : databases

    // Construct nextflow command
    def nxf_cmd = [
        'nextflow -log nextflow.log run',
            nextflow_opts,
            pipeline_name,
            meta.params_file ? "-params-file ${meta.params_file}" : '',
            additional_config ? "-c $additional_config" : '',
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

    output:
    path "$workdir", emit: work_dir
    stdout emit: log
    path 'nextflow.log'
}
