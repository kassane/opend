// REQUIRES: Plugins

// RUN: split-file %s %t --leading-lines
// RUN: %ldc -g %t/plugin.d %plugin_compile_flags -of=%t/plugin%so
// RUN: %ldc -wi -c -o- --plugin=%t/plugin%so %t/testcase.d 2>&1 | FileCheck %t/testcase.d

//--- plugin.d
import dmd.dmodule;
import dmd.errors;
import dmd.location;
import dmd.visitor;
import dmd.declaration;
import dmd.dsymbol;

extern(C++) class MyVisitor : SemanticTimeTransitiveVisitor {
    alias visit = SemanticTimeTransitiveVisitor.visit;

    override void visit(VarDeclaration vd) {
        if (vd.aliasTuple)
            warning(vd.loc, "It works!");
    }
}

extern(C) void runSemanticAnalysis(Module m) {
    scope v = new MyVisitor();
    if (!m.members)
        return;
    m.members.foreachDsymbol((s) {
        s.accept(v);
    });
}

//--- testcase.d
alias AliasSeq(TList...) = TList;

int i = 0;
struct A {
    ~this() {
        i *= 2;
    }
}

void main() {
    {
        // CHECK: testcase.d([[@LINE+1]]): Warning:
        AliasSeq!(A, A) params;
        i = 1;
    }

    assert(i == 4);
}
