@Grab(group='com.csvreader', module='csvreader', version='1.0')

import com.csvreader.CsvWriter
import java.io.FileWriter

/*
** The following code was found at,
**
** https://github.com/bentsherman/nf-boost/blob/6d2bb44f46311334a0078155920a75949329f45e/src/main/groovy/nextflow/boost/BoostExtension.groovy#L95
**
*/

/**
* Save a list of records to a CSV file.
*
* @param opts
* @param records
* @param path
*/
void mergeCsv(Map opts=[:], List records, Path path) {
    if( records.size() == 0 )
        throw new IllegalArgumentException('In `mergeCsv` function -- at least one record must be provided')

    new CsvWriter(opts).apply(records, path)
}

process RECORDS_TO_CSV {
  publishDir 'results'

  input:
  val records

  output:
  path '*csv'

  exec:
  def path = task.workDir.resolve("records_${task.index}.csv")
  mergeCsv(records, path, header: true, sep: ',')
}
