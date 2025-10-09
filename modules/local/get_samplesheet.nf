import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;
import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;

def parse_yaml( infile ) {
    InputStream inputStream = new FileInputStream( infile.toFile() );
	Yaml yaml = new Yaml();
    // nested nextflow will be run once per params file.
    // Order of arguments to `+` allows  YAML params to override default params.
    p = yaml.load( inputStream )
    log.info "parse_yaml: p: $p"
    return p
}

/*
 *  Given recursive output, data, as described below, return the samplesheet, contained in the first
 *  element, meta.  Nextflow does not allow a process task to output a path that lies outside the task's
 *  workdir, so the path is output as val type.
 *
 */
process GET_SAMPLESHEET {
    input:
    val pfile

    exec:
    log.info "GET_SAMPLESHEET: pfile: $pfile"
    p = parse_yaml( pfile )
    ss = p.samplesheet

    output:
    val ss
}
