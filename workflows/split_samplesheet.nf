include { RECORDS_TO_CSV } from "../modules/local/write_csv.nf"
include { groupTuplesNearSize } from "../modules/local/chunk_samplesheet.nf"

workflow SPLIT_SAMPLESHEET {
    take:
    samplesheet
    batch_size

    main:
    ch_out = Channel.value( file( samplesheet, checkIfExists: true ) )

    if ( batch_size > 0 ) {
        ch_out = Channel.fromPath( samplesheet ).splitCsv( header: true )
            .toSortedList { a,b ->
                a.sample <=> b.sample ?: a.run_accession <=> b.run_accession
            }
            .map { it -> groupTuplesNearSize( it ) }
            .flatMap { it }
            .RECORDS_TO_CSV()
    }

    emit:
    ch_out
}
