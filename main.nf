nextflow.enable.dsl=2
nextflow.preview.recursion=true

import org.yaml.snakeyaml.Yaml

include { NEXTFLOW_RUN as NFCORE_DEMO } from "./modules/local/nextflow/run/main"
include { SQUASH_WORK } from "./modules/local/squash_work.nf"
include { WRITE_ENVIRONMENT } from "./modules/local/write_environment.nf"
include { GET_WORKDIRS } from "./modules/local/get_workdirs.nf"

as_path = { it ? file( it ) : Channel.value([]) }

workflow iteration {
    take:
    data                                // [ meta, [work_1.sqfs,work_1], ..., [work_{i-1}.sqfs,work_{i-1}] ]

    main:
    data.subscribe { log.info "iteration: data: ${it}" }
    log.info "iteration: data.getClass(): ${data.getClass()}"
    log.info "iteration: data: ${data}"

    def cache_dir = file( workflow.workDir.resolve('local/nf_segmented').toUriString() )
    assert cache_dir.mkdirs()

    WRITE_ENVIRONMENT( data )

    workdirs = GET_WORKDIRS( data )

    NFCORE_DEMO(
        params.nfcore_demo_pipeline,     // Select nf-core pipeline
        params.nfcore_demo_opts,   // workflow opts supplied as params for flexibility
        as_path( params.nfcore_demo_samplesheet ),
        as_path( params.nfcore_demo_databases ),
        as_path( params.nfcore_demo_add_config ),
        params.outdir,
        cache_dir,
        WRITE_ENVIRONMENT.out,
        workdirs,
        data
    )

    SQUASH_WORK( NFCORE_DEMO.out.work_dir )

    emit:
    SQUASH_WORK.out
}

workflow {
    // nested nextflow will be run once per params file.
    ch_meta = Channel.fromPath( params.meta, checkIfExists: true )
                    .splitCsv( header: true )
                    .map { rec ->
                        {
                            rec.params_file = file( rec.params_file, checkIfExists: true )
                            rec.samplesheet = rec.containsKey( 'samplesheet' ) && rec.samplesheet ?
                                                file( rec.samplesheet, checkIfExists: true ) : null
                            rec.databases   = rec.containsKey( 'databases'   ) && rec.databases ?
                                                file( rec.databases,   checkIfExists: true ) : null
                            return rec
                        }
                    }
    ch_meta.subscribe { log.info "ch_meta: ${it}" }

    ch_out = iteration.scan( ch_meta )
    ch_out.subscribe { log.info "ch_out: $it" }
}
