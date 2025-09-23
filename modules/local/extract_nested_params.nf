process EXTRACT_NESTED_PARAMS {
    input:
    path meta_file

    output:
    path 'params_*.yaml'

    script:
    """
    if [ "$CLUSTER_ID" == "sockeye" ]]; then
        module load gcc/9.4.0 py-pyyaml/6.0
    fi

    python3 ${projectDir}/templates/extract_nested_params.py $meta_file
    """
}
