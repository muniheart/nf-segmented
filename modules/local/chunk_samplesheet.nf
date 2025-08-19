/*
** Sort samplesheet, then split into batches of roughly size M, not splitting groups across sample identifier.
**
**
*/
List<List<List>> groupTuplesNearSize(List<List> tuples, int M = params.batch_size ) {
    // Group by 0-th element
    def grouped = tuples.groupBy { it.sample }.values() as List

    def batches = []
    def currentBatch = []
    def currentSize = 0

    grouped.each { group ->
        if (currentSize + group.size() > M && currentBatch) {
            batches << currentBatch
            currentBatch = []
            currentSize = 0
        }

        currentBatch += group
        currentSize += group.size()
    }

    if (currentBatch) {
        batches << currentBatch
    }

    return batches
}
