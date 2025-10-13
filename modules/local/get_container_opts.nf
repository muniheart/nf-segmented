process GET_CONTAINER_OPTS {
    input:
    val image_mounts
    val cache_dir
    val env_file

    output:
    val opts

    script:
    env_vars = \
        [
            "NXF_APPTAINER_CACHEDIR=\${NXF_APPTAINER_CACHEDIR}",
            "NXF_HOME=\${NXF_HOME}",
            "NXF_OFFLINE=\${NXF_OFFLINE}",
//          "NXF_CACHE_DIR=${cache_dir.resolveSymLink()}",
            "${params.env_vars}"
        ].join(",")

    bind_mounts = \
        [
            params.bind_mounts,
//          cache_dir.resolveSymLink(),
        ].findAll().join(",")

    opts = [
        env_vars            ? "--env ${env_vars}" : "",
        params.mount_images ? ( image_mounts.relative ? "-B ${image_mounts.relative}" : "" ) : "",
        bind_mounts         ? "-B ${bind_mounts}" : "",
        env_file            ? "--env-file ${env_file}" : ""
    ].findAll().join(" ").trim() ?: ''
    """
    :
    """
}
