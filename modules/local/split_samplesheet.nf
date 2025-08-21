process SPLIT_SAMPLESHEET {
    input:
    tuple val(meta), val(params), val(samplesheet)

    output:
    tuple val(meta), val(params), path('*.csv')

    script:
    """
    python3 ../templates/split_csv.py \
        --input $samplesheet \
        --output-prefix samplesheet_ \
        --max-records ${meta.batch_size}\
        --key sample
    """
}
