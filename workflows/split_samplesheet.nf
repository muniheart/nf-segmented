include { records_to_string; WRITE_CSV } from "../modules/local/write_csv.nf"
include { groupTuplesNearSize } from "../modules/local/chunk_samplesheet.nf"

def read_csv( infile ) {
    Channel.fromPath( infile ).splitCsv( header: true )
        .toSortedList { a,b ->
                a.sample <=> b.sample ?: a.run_accession <=> b.run_accession
        }
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
    ch_0 = ch_in.branch { meta, params_files ->
        single: meta.batch_size<=0
        multiple: meta.batch_size>0
    }

    /*
     *  batch ch_in.multiple. pass samplesheet path of ch_in.single.
     *
     */
    
    ch_1 = ch_0.multiple.map { meta,x ->
        def lines = read_csv( meta.samplesheet )
        log.info "lines: $lines"

        if (false) {
        def batches = groupTuplesNearSize( lines, meta.batch_size )
        def csv_strings = batches.map { write_csv_string(it) }
        [ meta, x, csv_strings ]
        .transpose( by: 2 )
        }
    }

    ch_1.subscribe { log.info "ch_1: $it" }

    emit:
    ch_1
}
