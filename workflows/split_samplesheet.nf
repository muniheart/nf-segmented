include { records_to_string; WRITE_CSV } from "../modules/local/write_csv.nf"
include { groupTuplesNearSize } from "../modules/local/chunk_samplesheet.nf"

/*
 * Need to keep samplesheet paired with params so we can modify params.input, or otherwise pass
 * each samplesheet batch to the nested workflow.
 *
 */
workflow SPLIT_SAMPLESHEET {
    take:
    samplesheet
    batch_size

    main:
    ch_out = samplesheet

    if ( batch_size > 0 ) {
        ch_out = Channel.fromPath( samplesheet ).splitCsv( header: true )
            .toSortedList { a,b ->
                a.sample <=> b.sample ?: a.run_accession <=> b.run_accession
            }
            .map { it -> groupTuplesNearSize( it ) }
            .flatMap { it }
            .map { records_to_string( it ) }
            | write_csv()
    }

    emit:
    ch_out
}
