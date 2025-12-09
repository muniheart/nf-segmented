process GET_CONTAINER_OPTS {
    input:
    val image_mounts
    val env_file

    output:
    val opts

    exec:
    env_vars = \
        [
            "NXF_APPTAINER_CACHEDIR=\${NXF_APPTAINER_CACHEDIR}",
            "NXF_HOME=\${NXF_HOME}",
            "NXF_OFFLINE=\${NXF_OFFLINE}",
            "${ params.env_vars ?: '' }"
        ].findAll().join(",")

    bind_mounts = \
        [
            params.bind_mounts,
        ].findAll().join(",")

    opts = [
        env_vars            ? "--env ${env_vars}" : "",
        params.mount_images ? ( task.ext.is_final ? "-B ${image_mounts.final}" :
                                    ( image_mounts.relative ? "-B ${image_mounts.relative}" : "" ) ) : "",
        bind_mounts         ? "-B ${bind_mounts}" : "",
        env_file            ? "--env-file ${env_file}" : ""
    ].findAll().join(" ").trim() ?: ''
}
