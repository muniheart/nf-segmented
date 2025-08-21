/*
** The following code was found at,
**
** https://github.com/bentsherman/nf-boost/blob/6d2bb44f46311334a0078155920a75949329f45e/src/main/groovy/nextflow/boost/BoostExtension.groovy#L95
**
** and modified to use opencsv to write csv format string.
*/

process WRITE_CSV {
    input:
    tuple val(meta), val(params), val(csv_lines)

    output:
    tuple val(meta), val(params), path(csv_file)

    script:
    csv_file = "samplesheet_${task.index}.csv"

    """
    echo -e \"\"\"$csv_lines\"\"\" > $csv_file
    """
}

def records_to_string( records ) {
    header = records.head().collect { (it*.key) }.flatten().join(",")
    log.info "header: ${header.inspect()}"
    body = records.collect { (it*.value).join(",") }.join("\n")
    log.info "body: ${body.inspect()}"
    res = [ header,body,'' ].join("\n")
    log.info "res.getClass(): ${res.getClass()}"
    log.info "res: ${res.inspect()}"
    return res
}
