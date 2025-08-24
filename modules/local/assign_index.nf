process ASSIGN_INDEX {
    input:
    val in_tuple        // [ meta, ... ]

    output:
    val out_tuple

    exec:
    out_tuple = in_tuple.clone()
    out_tuple[0].index = task.index
}
