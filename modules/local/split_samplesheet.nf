process SPLIT_SAMPLESHEET {
    input:
    tuple val(meta), val(params), val(samplesheet)

    output:
    tuple val(meta), val(params), path('*.csv')

    script:
    """
    module load gcc/9.4.0 openblas/0.3.15 py-pandas/1.2.4

    python3 ../templates/split_csv.py \
        --input $samplesheet \
        --output-prefix samplesheet_ \
        --max-records ${meta.batch_size}\
        --key sample
    """
}
