module tdd.c.td_log;

extern (C) {
    alias td_log_fatal_error_callback_ptr = void function(const char *);
    int td_set_log_file_path(const char *file_path);
    void td_set_log_max_file_size(long max_file_size);
    void td_set_log_verbosity_level(int new_verbosity_level);
    void td_set_log_fatal_error_callback(td_log_fatal_error_callback_ptr callback);
}