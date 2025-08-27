process EXTRACT_NESTED_PARAMS {
    input:
    path meta_file

    output:
    path 'params_*.yaml'

    script:
    """
    python3 ${projectDir}/templates/extract_nested_params.py
    """
}
