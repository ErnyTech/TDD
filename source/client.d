module tdd.client;

enum DEFAULT_TIMEOUT = 10;
alias TdCallback = void delegate(string);

class Client {
    private shared(TdCallback) tdCallback;
    private shared(bool*) isStopped;
    private shared(bool*) isRunning;
    private shared(double*) timeout;
    public shared(void*) clientPtr;

    this() {
        import core.atomic : atomicStore;
        import tdd.c.td_json_client : td_json_client_create;

        this.clientPtr = cast(shared) td_json_client_create();
        this.isStopped = new shared(bool)(true);
        this.isRunning = new shared(bool)(false);
        setTdCallback(null);
        setTimeout(DEFAULT_TIMEOUT);
    }

    ~this() {
        import tdd.c.td_json_client : td_json_client_destroy;

        stop();
        td_json_client_destroy(cast(void*) this.clientPtr);
        this.clientPtr = null;
    }
    
    void init() {
        import std.concurrency : spawn;
        import core.atomic : atomicStore;

        if(this.clientPtr == null) {
            return;
        }

        atomicStore(*this.isStopped, false);
        atomicStore(*this.isRunning, true);
        spawn(&Client.implRun, &this.clientPtr, &this.tdCallback, this.isStopped, this.isRunning, this.timeout);   
    }

    void init(TdCallback tdCallback) {
        setTdCallback(tdCallback);
        init();
    }

    void init(TdCallback tdCallback, double timeout) {
        setTdCallback(tdCallback);
        setTimeout(timeout);
        init();
    }

    void setTdCallback(TdCallback tdCallback) {
        import core.atomic : atomicStore;
        import std.stdio;

        atomicStore(this.tdCallback, tdCallback);
    }

    void setTimeout(double timeout) {
        import core.atomic : atomicStore;

        if(this.timeout == null) {
            this.timeout = new shared(double)(timeout);
        } else {
            atomicStore(*this.timeout, timeout);
        }
    }

    void send(string request) {
        import core.atomic : atomicLoad;
        import tdd.c.td_json_client : td_json_client_send;
        import tdd.c.utils : fromString;
        import std.stdio;
        
        writeln(this.clientPtr);

        if(this.clientPtr == null) {
            return;
        }

        td_json_client_send(cast(void*) this.clientPtr, fromString(request));
    }

    string execute(string request) {
        import core.atomic : atomicLoad;
        import tdd.c.td_json_client : td_json_client_execute;
        import tdd.c.utils : toString;
        import tdd.c.utils : fromString;

        if(this.clientPtr == null) {
            return "";
        }
        
        auto result = td_json_client_execute(cast(void*) this.clientPtr, fromString(request));
        return toString(result);
    }

    void stop() {
        import core.atomic : atomicLoad;
        import core.atomic : atomicStore;
        import std.stdio;

        if(!*this.isRunning || *this.isStopped) {
            return;
        }

        atomicStore(*this.isStopped, true);
        while(atomicLoad(*this.isRunning)) {}
        writeln("SHUTTING DOWN COMP");
    }

    private static void implRun(shared(void**) clientPtr, shared(TdCallback*) tdCallback, shared(bool*) isStopped, shared(bool*) isRunning, shared(double*) timeout) {
       import std.concurrency : spawn;
       import std.array : empty;
       import core.atomic : atomicLoad;
       import core.atomic : atomicStore;
       import tdd.c.td_json_client : td_json_client_receive;
       import tdd.c.utils : toString;
       import std.stdio;
       
       while(true) {
           if(atomicLoad(*isStopped)) {
               atomicStore(*isRunning, false);
               writeln("SHUTTING DOWN");
               break;
           }

           if(atomicLoad(tdCallback) == null) {
               continue;
           }
           
           auto client = atomicLoad(*clientPtr);
           
           if(cast(void*) clientPtr == null) {
                continue;
           }
           
           auto response_cstr = td_json_client_receive(cast(void*) client, atomicLoad(*timeout));
           auto response = toString(response_cstr);

           if(response == null || response.empty) {
               continue;
           }
           
           spawn(&Client.implSendResponse, tdCallback, response);
       }
    }
    
    private static implSendResponse(shared(TdCallback*) tdCallback, string response) {
        import core.atomic : atomicLoad;
   
        auto callback = atomicLoad(*tdCallback);
        callback(response);
    }
}
