// @Grab(group='org.apache.ivy', module='ivy', version='2.5.0')

// import org.apache.ivy.util.MessageLogger;
import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;
// import java.io.StringWriter;
import java.io.File;

include { SPLIT_SAMPLESHEET } from "../workflows/split_samplesheet.nf"

def as_list = { it instanceof List ? it : [it] }

def parse_yaml( infile ) {
    InputStream inputStream = new FileInputStream( infile.toFile() );
	Yaml yaml = new Yaml();
    // nested nextflow will be run once per params file.
    // Order of arguments to `+` allows  YAML params to override default params.
    meta = yaml.load( inputStream )
                .collect { x ->
                    // Convert ParamsMap to map.
                    x.main = [ params as Map, x.main ].collectEntries()
                    // Create unique key for future splitting/rejoining.
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
    tuple val(meta), val(params)

    output:
    tuple val(meta), path('params.yaml')

    script:
    def options = new DumperOptions()
    options.setDefaultFlowStyle(DumperOptions.FlowStyle.BLOCK)
    def yaml = new Yaml(options)
    def yamlString = yaml.dump(params)

    """
    echo -e \"\"\"${yamlString}\"\"\" > params.yaml
    """
}

workflow PARSE_META_YAML {
    take:
    meta_file
    
    main:
    log.info "PARSE_META_YAML: meta_file: ${meta_file}"
    ch_segments = parse_yaml( meta_file )
    log.info "PARSE_META_YAML: ch_segments class: ${ch_segments.getClass()}"
    log.info "PARSE_META_YAML: ch_segments: ${ch_segments}"
    ch_segments.subscribe { log.info "PARSE_META_YAML: ch_segments: ${it}" }

    /*
     * Extract params.nested, samplesheet, batch_size from params.
     *
     */
    ch_nested_params = ch_segments.map { it ->
        def samplesheet = it.nested.containsKey( 'input' ) && it.nested.input ? it.nested.input :
            it.main.containsKey( 'samplesheet' ) && it.main.samplesheet ? it.main.samplesheet : params.samplesheet
        def batch_size = it.main.containsKey( 'batch_size' ) ? it.main.batch_size : params.batch_size
        def meta = [ samplesheet: samplesheet, batch_size: batch_size ]
        return [ meta, it.nested ]
    }

    ch_nested_params.subscribe { log.info "ch_nested_params: ${it}" }

    /*
     * Write params.nested to params file and update the channel with file path.
     *
     */

    ch_2 = ch_nested_params | WRITE_PARAMS_YAML

    ch_2.subscribe { log.info "ch_2: ${it}" }
    if ( false ) {
    ch_2
        .groupTuple().map { it ->
            it[0] = file( it[0], checkIfExists: true )
            return it
        } | SPLIT_SAMPLESHEET

    /*
     * Join split samplesheets with params_files.  Unnest the samplesheet batches per segment.
     *
     */

    /*
     *  merge input and batch_size channels.  Split channel on batch_size>0.
     *  true:
     *      split samplesheet, write each to string, write each string to file, return path
     *  false:
     *      return samplesheet 
     *
     *  PITFALL: Reordering these channels will lose correspondence with ch_params.  Must add key to each and
     *  join later.
     */

    // Order of channels to `merge` operator chosen to expand ch_samplesheet for each value of ch_segments.

    }

//  ch_out = ch_segments.map{ it.nested }.merge( ch_input ) { a,b -> [ [a],as_list(b) ] }
//      .flatMap { it.combinations { a,b -> [ params:a, samplesheet:b ] } }

    emit:
    ch_segments
}

