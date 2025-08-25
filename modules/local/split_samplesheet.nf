process SPLIT_SAMPLESHEET {
    input:
    tuple val(index), val(meta), path(samplesheet, name: 'samplesheet.csv')

    output:
    tuple val(index), val(meta), path('*.csv')

    script:
    log.info "SPLIT_SAMPLESHEET: index: $index; meta: $meta; samplesheet: $samplesheet"
    if ( meta.batch_size > 0 ) {
    """
    module load gcc/9.4.0 openblas/0.3.15 py-pandas/1.2.4

    python3 ${projectDir}/templates/split_csv.py \
        --input samplesheet.csv \
        --output-prefix samplesheet \
        --max-records ${meta.batch_size}\
        --key sample
    """
    } else {
    """
    cp samplesheet.csv samplesheet_1.csv
    """
    }
}
