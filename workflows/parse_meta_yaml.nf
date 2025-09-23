// @Grab(group='org.apache.ivy', module='ivy', version='2.5.0')

// import org.apache.ivy.util.MessageLogger;
import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;
// import java.io.StringWriter;
import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;

// import java.io.Path;
// import java.io.File;

include { SPLIT_SAMPLESHEET         } from "../modules/local/split_samplesheet.nf"
include { EXTRACT_NESTED_PARAMS     } from "../modules/local/extract_nested_params.nf"
include { makeNumericFileComparator } from "../modules/local/filename_comparator.nf"
include { ASSIGN_INDEX              } from "../modules/local/assign_index.nf"

def as_list = { it instanceof List ? it : [it] }
def add_index( ch ) {
    def k=0
    ch.map { it -> [k++] + it }
}

def parse_yaml( infile ) {
    InputStream inputStream = new FileInputStream( infile.toFile() );
	Yaml yaml = new Yaml();
    // nested nextflow will be run once per params file.
    // Order of arguments to `+` allows  YAML params to override default params.
    meta = yaml.load( inputStream )
                .collect( { x ->
                    // Convert ParamsMap to map.
                    x.main = [ params as Map, x.main ].collectEntries()
                    // Create unique key for future splitting/rejoining.
                    return x
                } )
                .withIndex().collect { it,index -> [index]+it }
    return Channel.fromList( meta )
}

/*
 *  Variable substitution is not available before pipeline execution.  The best I can do is
 *  resolve a relative path against params.input.
 *
 */
def extract_samplesheet( ch ) {
    ch.map { it ->
        Path p = Paths.get( it[1].samplesheet )
        log.info "extract_samplesheet: p: $p"
        if ( ! p.isAbsolute() ) {
            Path dir = Paths.get( "${params.input}" )
            p = dir.resolve( p )
        }
        log.info "extract_samplesheet: p: $p"
        File res = p.toFile()
        log.info "extract_samplesheet: res: $res"
        assert res.exists()
        return it + [ p ]
    }
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
    def compare_on_segment_index = makeNumericFileComparator( "params_([0-9]+).yaml" )
    ch_nested_params = EXTRACT_NESTED_PARAMS( meta_file ) |
        toSortedList { a,b -> compare_on_segment_index(a,b) } |
        flatten | map { it -> tuple(it) } | add_index
    ch_nested_params.subscribe { "0: PARSE_META_YAML: ch_nested_params: $it" }

//  ch_nested_params = ch_nested_params | add_index // .toSortedList { a,b -> compare_on_segment_index(a,b) } | flatMap { it } | add_index
    ch_nested_params.subscribe { "0.2: PARSE_META_YAML: ch_nested_params: $it" }

//  ch_nested_params = ch_nested_params.map( { it -> it.withIndex().collect { v,i -> [i]+v } } )
//  ch_nested_params.subscribe { "1: PARSE_META_YAML: ch_nested_params: $it" }
//  ch_nested_params = ch_nested_params.flatMap {it}
//  ch_nested_params.subscribe { "2: PARSE_META_YAML: ch_nested_params: $it" }

    /*
     * Extract samplesheet, batch_size from segments.
     *
     */
    ch_meta = ch_segments.map { index,it ->
        def samplesheet = it.nested.containsKey( 'input' ) && it.nested.input ? it.nested.input :
            it.main.containsKey( 'samplesheet' ) && it.main.samplesheet ? it.main.samplesheet : params.samplesheet
        def batch_size = it.main.containsKey( 'batch_size' ) ? it.main.batch_size : params.batch_size
        return [ index, [ samplesheet: samplesheet, batch_size: batch_size ] ]
    }
    ch_meta.subscribe { log.info "PARSE_META_YAML: ch_meta: $it" }

    /*
     * split samplesheet before joining meta and nested_params.
     * 
     */
    ch_0 = ch_meta.groupTuple( by: 1 ) | extract_samplesheet | SPLIT_SAMPLESHEET |
        map { a,b -> [as_list(a),as_list(b)] } | map { it -> it.combinations() } | flatMap {it}
       
    ch_0.subscribe { log.info "PARSE_META_YAML: ch_0: $it" }

    ch_1 = ch_0.combine( ch_nested_params, by: 0 ).toSortedList { a,b -> a[0] <=> b[0] } .flatMap {it} .map { i,a,b -> [samplesheet:a, params_file:b] }
    ch_1.subscribe { log.info "PARSE_META_YAML: ch_1: $it" }

    emit:
    ch_1        // ch_out
}
