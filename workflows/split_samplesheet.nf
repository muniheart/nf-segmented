include { records_to_string; WRITE_CSV } from "../modules/local/write_csv.nf"
include { groupTuplesNearSize } from "../modules/local/chunk_samplesheet.nf"
include { parseCsvFile; parseAllCsvFiles } from "../modules/local/parse_csv.nf"

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
    ch_in       // [ meta [ sampsheet:, batch_size: ], params_files [], ss_file ]  

    main:

    ch_in.subscribe { log.info "SPLIT_SAMPLESHEET: ch_in: $it" }

    ch_0 = ch_in.branch { meta, params_files, ss_file ->
        single: meta.batch_size<=0
        multiple: meta.batch_size>0
    }

    /*
     *  batch ch_in.multiple. pass samplesheet path of ch_in.single.
     *
     */
    
    ch_1 = ch_0.multiple.collect { meta, params, ss_path ->
        def records = parseCsvFile( ss_path )
        log.info "records: $records"
        def batches = groupTuplesNearSize( records, meta.batch_size )
        log.info "batches: $batches"
        def lines = batches.collect { records_to_string(it) }
        log.info "lines: $lines"
        [ meta, params, lines ]
    }

    ch_1.subscribe{ log.info "ch_1: $it" }
    if (false) {
    ch_out = ch_1 | WRITE_CSV
    ch_out.subscribe{ log.info "ch_out: $it" }
    } else {
        ch_out=ch_1
    }

    emit:
    ch_out
}
