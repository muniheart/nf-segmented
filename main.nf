nextflow.enable.dsl=2
nextflow.preview.recursion=true

include { NEXTFLOW_RUN as NFCORE_DEMO } from "./modules/local/nextflow/run/main"
include { SQUASH_WORK } from "./modules/local/squash_work.nf"
include { WRITE_ENVIRONMENT } from "./modules/local/write_environment.nf"
include { GET_WORKDIRS } from "./modules/local/get_workdirs.nf"
include { PARSE_META_YAML } from "./workflows/parse_meta_yaml.nf"
include { PARSE_META_CSV } from "./workflows/parse_meta_csv.nf"

// def as_path = { it ? (it instanceof Path ? it : file( it )) : null }
def as_path = { it -> it ? file( it, checkIfExists: true ) : Channel.value([]) }

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
    def ch_meta = null

    if ( params.meta ) {
        meta_file = file( params.meta, checkIfExists: true )
        ch_meta = meta_file.name.endsWith( '.yaml' ) ? PARSE_META_YAML( meta_file ) :
            meta_file.name.endsWith( '.csv' ) ? PARSE_META_CSV( meta_file ) : null
        assert ch_meta
    }

    if ( ch_meta )
        ch_meta.subscribe { log.info "ch_meta: ${it}" }

//  /*
//   * Don't use combine.  ch_samplesheet is list of paths.  I want to pair corresponding elements
//   * of ch_meta*.nested and ch_samplesheet, then unnest.
//   */

//  /*
//   * E = [A,B].combinations { it -> it.collectEntries() }
//   * Given A=[a1,a2,a3], B=[b1,b2], generate [[a1,b1],[a1,b2],[a2,b1],[a2,b2],[a3,b1],[a3,b2]] then
//   * combine dictionaries ai,bj as ai+bj, [a1+b1,a1+b2,a2+b1,a2+b2,a3+b1,a3+b2]
//   *
//   * CAREFUL! the order of merge was chosen to get [p1,s1],[p1,s2],...,[p2,s1],[p2,s2],...
//   * where pI is i-th params file and sj is j-th samplesheet, but this fixes the order of arguments to
//   * collectEntries and arguments seen last will take precidence, I think.
//   */

// /*
//  * Need the following to continue:
//  *  - meta file is parsed to generate params file per segment.
//  *  - samplesheet channel, a path, or list of files per segment
//  *    - This will be generated using `fromList`, with each element either the default samplesheet
//  *      or the segment-specific samplesheets, using collect { it.samplesheet ?: default_samplesheet }.
//  *    - Need to think about when we split samplesheet.
//  *       - using meta.csv, multiple samplesheets per segment could be input.  these don't need to be split.
//  *       - using one samplesheet per segment.
//  *
//  *  - generate combinations of these per segment.
//  *    - Does the order matter?  We want to be sure that the last segment, that runs MULTIQC, is run after all
//  *      previous segments for all previous samplesheets.
//  *      Yes.  Must generate combinations: ( seg_1, ss_11 ), ( seg_1, ss_12 ), ... ( seg_2, ss_21 ), ...
//  *      so that we are sure that the segments are processed in order.
//  */

    ch_out = iteration.scan( ch_meta )
//  ch_out.subscribe { log.info "ch_out: $it" }
}
