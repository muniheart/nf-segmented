import java.nio.file.Files
import java.nio.file.Paths

// Utility function for parsing a CSV file
def parseCsvFile(filePath) {
    log.info "parseCsvFile: filePath: $filePath"
    log.info "parseCsvFile: filePath.getClass(): ${filePath.getClass()}"

    def lines = Files.readAllLines( filePath )
    log.info "parseCsvFile: lines: $lines"
    def header = lines.first().split(',').collect { it.trim() }
    log.info "parseCsvFile: header: $header"

    def data = lines.tail().collect { line ->
        def values = line.split(',',-1).collect { it.trim() }
        [header, values].transpose().collectEntries()
    }
    log.info "parseCsvFile: data: $data"
    return data
}

workflow test_parse_csv {
    // Read all CSV files in one channel
    Channel
        .fromPath('data/*.csv')
        .set { csv_files }

    // Process all files in a single process
    parseAllCsvFiles(csv_files)
        .view()
}

process parseAllCsvFiles {
    input:
    val csv_files  // Value Channel with a list of file paths.

    output:
    val parsed_data  // A list of list of maps for each CSV file

    exec:
    // Use Groovy directly in the exec section, no triple quotes needed
    def results = []

    log.info "parseAllCsvFiles: csv_files: $csv_files"
    
    csv_files.each { file ->
        x = parseCsvFile(file)
        log.info "x: $x"
        results.add( x )
    }

    parsed_data = results
}
