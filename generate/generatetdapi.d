/+dub.sdl:
dependency "tlscheme2json" version="~>1.0.4"
+/

import std.stdio;
import std.ascii : newline;
import tlscheme2json : TLScheme2Json;
import tlscheme2json : BASECLASS_NAME;
import tlscheme2json : TLClass;
import tlscheme2json : TLMethod;

enum MODULE_NAME = "tdd.tdapi";
enum SHORTMODULE_NAME = "tdapi";
enum FUNCTIONCLASS_NAME = "TLFunction";
enum SERIALIZATION_MODULE = "vibe.data.json";
enum SERIALIZATION_RENAME = "name";

string tdapi;

void main() {
    auto tlClasses = TLScheme2Json.get();
    
    writeln("Generating tdapi.d module...");
    tdapi ~= fileHeader;
    tdapi ~= baseClass;

    foreach(tlClass; tlClasses) {
        tdapi ~= generateClass(tlClass);
    }

    writeln("Writing the module to a file");
    auto file = new File(SHORTMODULE_NAME ~ ".d", "w");
    file.write(tdapi);
    file.close;
}

string fileHeader() {
    return 
    "module " ~ MODULE_NAME ~ ";" ~ newline ~
    "import " ~ SERIALIZATION_MODULE ~ ";" ~ newline ~
    newline;
}

string baseClass() {
    return
    "class " ~ BASECLASS_NAME ~ " {" ~ newline ~
    newline ~
    "}" ~ newline ~
    newline ~
    "class " ~ FUNCTIONCLASS_NAME ~ " {" ~ newline ~
    newline ~
    "}" ~ newline ~
    newline;
}

string generateClass(TLClass tlClass) {
    string inheritance;

    if (tlClass.isFunction && tlClass.inheritance == BASECLASS_NAME) {
        inheritance = FUNCTIONCLASS_NAME;
    } else {
        inheritance = toClassName(tlClass.inheritance);
    }

    return 
    "class " ~ toClassName(tlClass.name) ~ " : " ~ inheritance ~ " {" ~ newline ~
    generateFields(tlClass.methods, tlClass.name) ~
    generateConstructor(tlClass.methods) ~ newline 
    ~ "}" ~ newline
    ~ newline;
}

string generateFields(TLMethod[] methods, string className) {
    string fields;

    fields ~= "\tpublic enum TLClassType = \"" ~ className ~ "\";";
    fields ~= newline;
    fields ~= "\t@" ~ SERIALIZATION_RENAME ~ "(\"@type\") public string TLObjectType = \"" ~ className ~ "\";";

    if(methods.length > 0) {
        fields ~= newline;
    }

    foreach(field; methods) {
        fields ~= ("\t" ~ generateField(field));
    }

    if(methods.length > 0) {
        fields ~= newline;
    }

    return fields;
}

string generateField(TLMethod method) {
    string field;

    field ~= "public " ~ generateType(method.type) ~ " " ~ toMethodName(method.name) ~ ";" ~ newline;
    return field;
}

string generateConstructor(TLMethod[] methods) {
    string constructor;

    if (methods.length > 0) {
        constructor ~= "\t@safe public this() {" ~ newline ~
        newline ~
        "\t}";
        constructor ~= newline;
        constructor ~= newline;
        constructor ~= "\t@safe public this(";
        
        foreach(i, method; methods) {
            constructor ~= generateType(method.type);
            constructor ~= " ";
            constructor ~= toMethodName(method.name);

            if(i != (methods.length -1)) {
                constructor ~=", ";
            }
        }

        constructor ~= ") {";
        constructor ~= newline;

        foreach(method; methods) {
            constructor ~= "\t\t";
            constructor ~= "this.";
            constructor ~= toMethodName(method.name);
            constructor ~= " = ";
            constructor ~= toMethodName(method.name);
            constructor ~= ";";
            constructor ~= newline;
        }

        constructor ~= "\t}";
    }

    return constructor;
}

string generateType(string type) {
    import std.algorithm.searching : canFind;
    import std.array : replace;
    import std.string : stripRight;

    switch(type) {
        case "double" : {
            return "double";
        }

        case "string" : {
            return "string";
        }

        case "int32" : {
            return "int";
        }

        case "int53" : {
            return "long";
        }

        case "int64" : {
            return "long";
        }

        case "bytes" : {
            return "byte[]";
        }

        case "boolFalse" : {
            return "bool";
        }

        case "boolTrue" : {
            return "bool";
        }

        case "Bool" : {
            return "bool";
        }

        default : {
            if(type.canFind("vector<")) {
                auto typeArray = type.replace("vector<", "").stripRight(">");
                return generateType(typeArray) ~ "[]";
            } else {
                return toClassName(type);
            }
        }
    }
}

string toClassName(string name) {
    import std.string : capitalize;

    if(name == "error") {
        name = "TLError";
    }

    auto firstChar = name[0 .. 1].capitalize;
    return firstChar ~ name[1 .. name.length];
}

string toMethodName(string name) {
    import std.array : split;
    import std.string : capitalize;

    if(name == "align") {
        return "align_";
    }

    if(name == "version") {
        return "version_";
    }

    if(name == "scope") {
        return "scope_";
    }

    if(name == "name") {
        return "name_";
    }
    
    string newName;
    auto nameSplit = name.split("_");

    foreach(i, str; nameSplit) {
        if(i == 0) {
            newName ~= str;
        } else {
            newName ~= str.capitalize;
        }
    }

    return newName;
}