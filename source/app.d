import std.stdio;
import tdd.client;

void main() {
    auto client = new Client();
    client.init((response) {
        writeln(response);
        client.destroy();
        client.init();
    });

    writeln(client.clientPtr);
}
