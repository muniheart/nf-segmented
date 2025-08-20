// Utility function for parsing a CSV file
def parseCsvFile(filePath) {
    def file = new File(filePath)
    def header = file.readLines().first().split(',').collect { it.trim() }
    def data = file.readLines().tail().collect { line ->
        def values = line.split(',').collect { it.trim() }
        [header, values].transpose().collectEntries()
    }
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
    path csv_files  // Channel with a list of file paths

    output:
    val parsed_data  // A list of list of maps for each CSV file

    exec:
    // Use Groovy directly in the exec section, no triple quotes needed
    def results = []
    csv_files.each { file ->
        results << parseCsvFile(file)
    }

    // Return the results
    return results
}
