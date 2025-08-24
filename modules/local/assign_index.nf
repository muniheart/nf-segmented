process ASSIGN_INDEX {
    input:
    val in_tuple        // [ meta, ... ]

    output:
    val out_tuple

    exec:
    out_tuple = in_tuple
    out_tuple.meta.index = task.index
}
