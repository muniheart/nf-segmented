process SPLIT_SAMPLESHEET {
    input:
    tuple val(index), val(meta), path(samplesheet, name: 'samplesheet.csv')

    output:
    tuple val(index), path('*.csv')

    script:
    log.info "SPLIT_SAMPLESHEET: index: $index; meta: $meta; samplesheet: $samplesheet"
    if ( meta.batch_size > 0 ) {
        if ( meta.samplesheet_groupby ) {
            """
            if [ "$CLUSTER_ID" = "fir" ]; then
                module load scipy-stack/2025a
            elif [ "$CLUSTER_ID" = "sockeye" ]; then
                module load gcc/9.4.0 openblas/0.3.15 py-pandas/1.2.4
            else
                echo "ERROR: CLUSTER_ID with value '$CLUSTER_ID' is not recognized."
                exit 1
            fi
        
            python3 ${projectDir}/templates/split_csv.py \
                --input samplesheet.csv \
                --output-prefix samplesheet \
                --max-records ${meta.batch_size}\
                --key ${meta.samplesheet_groupby}
            """
        } else {
            """
            if [ "$CLUSTER_ID" = "fir" ]; then
                module load scipy-stack/2025a
            elif [ "$CLUSTER_ID" = "sockeye" ]; then
                module load gcc/9.4.0 openblas/0.3.15 py-pandas/1.2.4
            else
                echo "ERROR: CLUSTER_ID with value '$CLUSTER_ID' is not recognized."
                exit 1
            fi
        
            python3 ${projectDir}/templates/split_csv.py \
                --input samplesheet.csv \
                --output-prefix samplesheet \
                --max-records ${meta.batch_size}\
            """
        }
    } else {
    """
    cp samplesheet.csv samplesheet_1.csv
    """
    }
}
