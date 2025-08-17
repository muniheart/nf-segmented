// @Grab(group='org.apache.ivy', module='ivy', version='2.5.0')

// import org.apache.ivy.util.MessageLogger;
import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;
// import java.io.StringWriter;
import java.io.File;

include { SPLIT_SAMPLESHEET } from "../workflows/split_samplesheet.nf"

def parse_yaml( infile ) {
    InputStream inputStream = new FileInputStream( infile.toFile() );
	Yaml yaml = new Yaml();
    // nested nextflow will be run once per params file.
    // Order of arguments to `+` allows  YAML params to override default params.
    meta = yaml.load( inputStream )
                .collect { x ->
                    // Convert ParamsMap to map.
                    x.main = [ params as Map, x.main ].collectEntries()
                    return x
                }
    return Channel.fromList( meta )
}

process PARSE_YAML {
    input:
    path meta_file

    script:
    InputStream inputStream = new FileInputStream( meta_file.toFile() );
	Yaml yaml = new Yaml();
    // nested nextflow will be run once per params file.
    // Order of arguments to `+` allows  YAML params to override default params.
    meta = yaml.load( inputStream )
                .collect { x ->
                    x.main = params + x.main
                    return x
                }
    """
    :
    """

    output:
    val meta
}

process WRITE_PARAMS_YAML {
    input:
    val params

    script:
    def options = new DumperOptions()
    options.setDefaultFlowStyle(DumperOptions.FlowStyle.BLOCK)
    def yaml = new Yaml(options)
    def yamlString = yaml.dump(params)

    """
    echo -e \"\"\"${yamlString}\"\"\" > params.yaml
    """

    output:
    path 'params.yaml'
}

workflow PARSE_META_YAML {
    take:
    meta_file
    
    main:
    log.info "PARSE_META_YAML: meta_file: ${meta_file}"
    ch_meta = parse_yaml( meta_file )
    log.info "PARSE_META_YAML: ch_meta class: ${ch_meta.getClass()}"
    log.info "PARSE_META_YAML: ch_meta: ${ch_meta}"
    ch_meta.subscribe { log.info "PARSE_META_YAML: ch_meta: ${it}" }

    ch_meta.map { it.nested } | WRITE_PARAMS_YAML

    ch_batch_size = ch_meta.map {
        it.main.containsKey( 'batch_size' ) ? it.main.batch_size : params.batch_size
    }
    ch_input = ch_meta.map {
        tuple(
            it.nested,
            it.nested.containsKey( 'input' ) && it.nested.input ? it.nested.input :
            it.main.containsKey( 'samplesheet' ) && it.main.samplesheet ? it.main.samplesheet : params.samplesheet
        )
    }
    ch_input.subscribe { log.info "ch_input: ${it}" }
    ch_batch_size.subscribe { log.info "ch_batch_size: ${it}" }
    ch_samplesheet = ch_input // SPLIT_SAMPLESHEET( ch_input, ch_batch_size )

    // Order of channels to `merge` operator chosen to expand ch_samplesheet for each value of ch_meta.

    ch_out = ch_meta.map { it.nested }.map { it.combinations() }

    emit:
    ch_out
}

