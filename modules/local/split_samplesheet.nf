process SPLIT_SAMPLESHEET {
    input:
    tuple val(meta), val(params_files), path(samplesheet, name: 'samplesheet.csv')

    output:
    tuple val(meta), val(params_files), path('*.csv')

    script:
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
