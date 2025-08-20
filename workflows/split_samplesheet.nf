include { records_to_string; WRITE_CSV } from "../modules/local/write_csv.nf"
include { groupTuplesNearSize } from "../modules/local/chunk_samplesheet.nf"
include { parseAllCsvFiles } from "../modules/local/parse_csv.nf"

def read_csv( infile ) {
    ch_out = Channel.fromPath( infile ).splitCsv( header: true )
        .toSortedList { a,b ->
                a.sample <=> b.sample ?: a.run_accession <=> b.run_accession
        }
    ch_out.subscribe { log.info "read_csv: ch_out: $it" }
    return ch_out
}

/*
 * Need to keep samplesheet paired with params so we can modify params.input, or otherwise pass
 * each samplesheet batch to the nested workflow.
 *
 */
workflow SPLIT_SAMPLESHEET {
    take:
    ch_in       // [ meta [ sampsheet:, batch_size: ], params_files [] ]  

    main:
    ch_0 = ch_in.branch { meta, params_files, ss_file ->
        single: meta.batch_size<=0
        multiple: meta.batch_size>0
    }

    /*
     *  batch ch_in.multiple. pass samplesheet path of ch_in.single.
     *
     */
    
    ch_1 = ch_0.multiple.collect { it -> it[2] }
        .parseAllCsvFiles()

    ch_1.subscribe{ log.info "ch_1: $it" }

        if (false) {
        def lines = read_csv( meta.samplesheet )
        log.info "lines: $lines"

        def batches = groupTuplesNearSize( lines, meta.batch_size )
        def csv_strings = batches.map { write_csv_string(it) }
        [ meta, x, csv_strings ]
        .transpose( by: 2 )
        }

    ch_1.subscribe { log.info "ch_1: $it" }

    emit:
    ch_1
}
