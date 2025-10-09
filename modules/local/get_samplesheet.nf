import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;

/*
 *  Given recursive output, data, as described below, return the samplesheet, contained in the first
 *  element, meta.  Nextflow does not allow a process task to output a path that lies outside the task's
 *  workdir, so the path is output as val type.
 *
 */
process GET_SAMPLESHEET {
    input:
    val data

    exec:
    log.info "GET_SAMPLESHEET: data: $data"
    ss = data[0].samplesheet // data.head().collect { a -> a.params_file }

    output:
    val ss
}
