def make_workdir_path( index, base, depth ) {
    p = []
    while ( p.size()<depth ) {
        p.add( 0, sprintf("0o%o",index % base ) )                                                                               index = index.intdiv( base )                                                                                        }                                                                                                                       log.info "make_workdir_path: p: $p"
    p.add( 0,"work" )
    p.join("/")
}
