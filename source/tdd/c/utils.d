module tdd.c.utils;

const(char*) fromString(string str) {
    import std.string : toStringz;
    return toStringz(str);
}

string toString(const(char*) str) {
    import std.conv : to;
    return to!string(str);
}