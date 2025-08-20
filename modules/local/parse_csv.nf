// Utility function for parsing a CSV file
def parseCsvFile(filePath) {
    log.info "parseCsvFile: filePath: $filePath"
    log.info "ParseCsvFile: filePath.getClass(): ${filePath.getClass()}"

    return []
//  def file = new File(filePath)
//  log.info "ParseCsvFile: file.getClass(): $file.getClass()"

    def header = file.readLines().first().split(',').collect { it.trim() }
    def data = file.readLines().tail().collect { line ->
        def values = line.split(',').collect { it.trim() }
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
