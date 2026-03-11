import java.lang.Math;
import java.lang.Exception;

class WorkdirTopOutException extends Exception {
    WorkdirTopOutException(String message = "Workdir has topped out.") {
        super(message)
    }
}

def make_workdir_path( index, base, depth, suffix=null ) {
    p = []
    while ( p.size()<depth ) {
        p.add( 0, sprintf("0o%o",index % base ) )
        index = index.intdiv( base )
    }
    log.info "make_workdir_path: p: $p"
    if ( index >= base )
        throw new WorkdirTopOutException()
    if ( suffix )
        p.add( suffix )
    p.join("/")
}
