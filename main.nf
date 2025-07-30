nextflow.enable.dsl=2
nextflow.preview.recursion=true

include { NEXTFLOW_RUN as NFCORE_DEMO } from "./modules/local/nextflow/run/main"
include { SQUASH_WORK } from "./modules/local/squash_work.nf"

workflow iteration {
    take:
    data

    main:
    data.subscribe { log.info "iteration: data: ${it}" }
    log.info "iteration: data.getClass(): ${data.getClass()}"
    log.info "iteration: data: ${data}"

    def cache_dir = file( workflow.workDir.resolve('local/nf_nimbly').toUriString() )
    assert cache_dir.mkdirs()

    NFCORE_DEMO(
        params.nfcore_demo_pipeline,     // Select nf-core pipeline
        params.nfcore_demo_opts,   // workflow opts supplied as params for flexibility
        params.nfcore_demo_samplesheet,
        params.nfcore_demo_databases,
        { it ? file( it ) : Channel.value([]) }( params.nfcore_demo_add_config ),
        params.outdir,
        cache_dir,
        data                            // params-file, images
    )

    SQUASH_WORK( NFCORE_DEMO.out.work_dir )

    emit:
    SQUASH_WORK.out
}

workflow {
    // nested nextflow will be run once per params file.
    ch_params = Channel.fromPath( params.meta, checkIfExists: true )
                    .splitCsv( header: true )
                    .map { line -> file( line.params_file, checkIfExists: true ) }

    ch_params.subscribe { log.info "ch_params: ${it}" }

    log.info "squash_work workflow"
    log.info "squash_work: params.meta: ${params.meta}"
    ch_params.subscribe { log.info "ch_params: ${it.getName()}" }

    ch_out = iteration.scan( ch_params )
    ch_out.subscribe { log.info "ch_out: $it" }
}
