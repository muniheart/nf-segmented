/*
** The following code was found at,
**
** https://github.com/bentsherman/nf-boost/blob/6d2bb44f46311334a0078155920a75949329f45e/src/main/groovy/nextflow/boost/BoostExtension.groovy#L95
**
** and modified to use opencsv to write csv format string.
*/

process WRITE_CSV {
    input:
    val csv_string

    script:
    csv_file = params_${task.index}.csv

    """
    echo -e \"\"\"$csv_string\"\"\" > $csv_file
    """

    output:
    path csv_file
}

def records_to_string( records ) {
    header = records[0].collect { (it*.key) }.flatten().join(",")
    log.info "header: $header"
    body = records.collect { (it*.value).join(",") }. join("\n")
    return header + "\n" + body
}
