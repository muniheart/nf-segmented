workflow PARSE_META_CSV {
    take:
    meta_file

    main:
    // nested nextflow will be run once per params file.
    ch_meta = Channel.fromPath( meta_file, checkIfExists: true )
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

    emit:
    ch_meta
}

