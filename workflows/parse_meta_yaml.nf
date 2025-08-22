// @Grab(group='org.apache.ivy', module='ivy', version='2.5.0')

// import org.apache.ivy.util.MessageLogger;
import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;
// import java.io.StringWriter;
import java.io.File;

include { SPLIT_SAMPLESHEET     } from "../modules/local/split_samplesheet.nf"
include { EXTRACT_NESTED_PARAMS } from "../modules/local/extract_nested_params.nf"

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

/*
 *
 * Unnest k-th element A.
 *
 */
def unnestAt = { A, k ->
    def v = A[k]
    if (!(v instanceof List)) {
        throw new IllegalArgumentException("A[${k}] must be a list")
    }
    return v.collect { element ->
        A[0..<k] + [element] + A[(k + 1)..<A.size()]
    }
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
    tuple val(meta), path(params_file)

    script:
    def options = new DumperOptions()
    options.setDefaultFlowStyle(DumperOptions.FlowStyle.BLOCK)
    def yaml = new Yaml(options)
    def yamlString = yaml.dump(params)
    params_file = "params_${task.index}.yaml"

    """
    echo -e \"\"\"${yamlString}\"\"\" > $params_file
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
     * Extract nested params from meta file, writing a YAML format params-file for each segment.
     *
     */
    ch_nested_params = EXTRACT_NESTED_PARAMS( meta_file )

    /*
     * Extract samplesheet, batch_size from segments.
     *
     */
    ch_meta = ch_segments.map { it ->
        def samplesheet = it.nested.containsKey( 'input' ) && it.nested.input ? it.nested.input :
            it.main.containsKey( 'samplesheet' ) && it.main.samplesheet ? it.main.samplesheet : params.samplesheet
        def batch_size = it.main.containsKey( 'batch_size' ) ? it.main.batch_size : params.batch_size
        def meta = [ samplesheet: samplesheet, batch_size: batch_size ]
        return meta
    }
    ch_meta.subscribe { log.info "PARSE_META_YAML: ch_meta: $it" }

    ch_nested_params = ch_meta.merge( ch_nested_params ) { a,b -> [meta:a, params_file:b] }
    ch_nested_params.subscribe { log.info "ch_nested_params: ${it}" }

    /*
     * Group by meta.
     */
    ch_3=ch_nested_params.groupTuple()
    ch_3.subscribe { log.info "ch_3: ${it}" }

    ch_4=ch_3
        .map { it ->
            return it + [ file( it[0].samplesheet, checkIfExists: true ) ]
        }
    ch_4.subscribe { log.info "ch_4: ${it.inspect()}" }

    ch_5 = ch_4 | SPLIT_SAMPLESHEET
    ch_5.subscribe { log.info "PARSE_META_YAML: ch_5: ${it}" }

    ch_6 = ch_5.map { it -> it.tail().combinations { a,b -> [ params:a, samplesheet:b ] }

	ch_6.subscribe { log.info "PARSE_META_YAML: ch_out: $it" }

    ch_out = ch_6
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


//  ch_out = ch_segments.map{ it.nested }.merge( ch_input ) { a,b -> [ [a],as_list(b) ] }
//      .flatMap { it.combinations { a,b -> [ params:a, samplesheet:b ] } }

    emit:
    ch_3
}

