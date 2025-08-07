process WRITE_ENVIRONMENT {
    input:
    val data

    output:
    path( 'env.txt' )

    script:
    key_val_strs = data.subList( 1, data.size() ).withIndex()
        .collect { a, index -> "wk${index+1}=${a[1].resolveSymLink()}" }.join(" ")

    """
    truncate -s 0 env.txt
    if [ -n "$key_val_strs" ]; then
        for KV in ${key_val_strs}; do
            echo \$KV >> env.txt
        done
    fi
    """
}
