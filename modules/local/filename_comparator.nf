/**
 * Returns a binary comparator closure for sorting files based on numeric index in filenames.
 *
 * @param pattern    A regex pattern with a capturing group for the numeric index.
 * @param group      The capture group index to extract the number from (default: 1).
 * @return           A binary comparator closure suitable for Channel.toSortedList().
 */
def makeNumericFileComparator(String pattern, int group = 1) {
    return { f1, f2 ->
        def extract = { name ->
            def matcher = name =~ pattern
            matcher && matcher[0].size() > group ? matcher[0][group].toInteger() : 0
        }

        def num1 = extract(f1.getName())
        def num2 = extract(f2.getName())
        return num1 <=> num2
    }
}
