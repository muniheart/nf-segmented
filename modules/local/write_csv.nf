// @Grab(group='com.csvreader', module='csvreader', version='1.0')
@Grab(group='com.opencsv', module='opencsv', version='4.6')
import com.opencsv.CSVWriter
import java.io.StringWriter

/*
** The following code was found at,
**
** https://github.com/bentsherman/nf-boost/blob/6d2bb44f46311334a0078155920a75949329f45e/src/main/groovy/nextflow/boost/BoostExtension.groovy#L95
**
** and modified to use opencsv to write csv format string.
*/

/**
* Save a list of records to a CSV file.
*
* @param opts
* @param records
* @param path
*/
process RECORDS_TO_CSV {
    publishDir 'results'

    input:
    val records

    output:
    path '*csv'

    script:
    // StringWriter to capture the CSV output
    StringWriter stringWriter = new StringWriter()
    CSVWriter csvWriter = new CSVWriter(stringWriter)

    // Write data to the CSVWriter
    records.each { row ->
        csvWriter.writeNext(row as String[])
    }

    // Close the writer
    csvWriter.close()

    // Get the CSV string
    String csvString = stringWriter.toString()

    """
    echo -e \"\"\"${csvString}\"\"\" >batch_${task.index}.csv
    """
}
