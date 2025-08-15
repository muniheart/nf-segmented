import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;
import java.io.FileWriter;

include { SPLIT_SAMPLESHEET } from "./workflows/split_samplesheet.nf"

process PARSE_YAML {
    input:
    path( meta_file )

    exec:
	Yaml yaml = new Yaml();
    // nested nextflow will be run once per params file.
    ch_meta = yaml.load( new File( meta_file ).text )
    /*
     *  Could use flag to indicate whether or not params should be injected.
     *  Order of arguments to `+` allows  YAML params to override default params.
     */
    ch_meta = ch_meta.collect { it -> { it.main = params + it.main; return it } }

    output:
    val ch_meta
}

process WRITE_PARAMS_YAML {
    input:
    val params

    exec:
    DumperOptions options = new DumperOptions();
    options.setIndent(2);
    Yaml writerYaml = new Yaml(options);

    FileWriter writer = new FileWriter("params.yaml");
    writerYaml.dump(data, writer);

    output:
    path "params.yaml"
}

workflow PARSE_META_YAML {
    take:
    meta_file
    
    main:
    ch_meta = PARSE_YAML( meta_file )

    ch_nested_params = ch_meta.map { it.nested } | WRITE_PARAMS_YAML

    ch_samplesheet = ch_meta.collect {
        SPLIT_SAMPLESHEET( it.nested.input ?: it.main.samplesheet, it.main.batch_size )
    }

    // Order of channels to `merge` operator chosen to expand ch_samplesheet for each value of ch_meta.

    ch_out = ch_meta.map { it.nested }.merge( ch_samplesheet ).map { it.combinations() }

    emit:
    ch_out
}

