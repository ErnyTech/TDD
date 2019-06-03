module tdd.log;

public import tdd.c.td_log : FatalErrorCallback = td_log_fatal_error_callback_ptr;

static class Log {
    static ~this() {
        setFatalErrorCallback((error_ignored) {});
    } 

    static void setLogFilePath(string filePath) {
        import std.exception : enforce;
        import tdd.c.td_log : td_set_log_file_path;
        import tdd.c.utils : fromString;

        immutable(int) result = td_set_log_file_path(fromString(filePath));
        enforce(result == 1, "Error: the " ~ filePath ~ " file cannot be opened or does not exist");
    }

    static void setLogFileMaxSize(long maxSize) {
        import tdd.c.td_log : td_set_log_max_file_size;

        td_set_log_max_file_size(maxSize);
    }

    static void setVerbosityLevel(int verbosityLevel) {
        import tdd.c.td_log : td_set_log_verbosity_level;

        td_set_log_verbosity_level(verbosityLevel);
    }

    static void setFatalErrorCallback(FatalErrorCallback fatalErrorCallback) {
        import tdd.c.td_log : td_set_log_fatal_error_callback;

        td_set_log_fatal_error_callback(fatalErrorCallback);
    }
}