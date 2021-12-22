
/* Compiler implementation of the D programming language
 * Copyright (C) 1999-2021 by The D Language Foundation, All Rights Reserved
 * written by Walter Bright
 * https://www.digitalmars.com
 * Distributed under the Boost Software License, Version 1.0.
 * https://www.boost.org/LICENSE_1_0.txt
 * https://github.com/dlang/dmd/blob/master/src/dmd/import.h
 */

#pragma once

#include "dsymbol.h"

class Identifier;
struct Scope;
class Module;
class Package;

class Import : public Dsymbol
{
public:
    /* static import aliasId = pkg1.pkg2.id : alias1 = name1, alias2 = name2;
     */

    DArray<Identifier*> packages;      // array of Identifier's representing packages
    Identifier *id;             // module Identifier
    Identifier *aliasId;
    int isstatic;               // !=0 if static import
    Visibility visibility;

    // Pairs of alias=name to bind into current namespace
    Identifiers names;
    Identifiers aliases;

    Module *mod;
    Package *pkg;               // leftmost package/module

    AliasDeclarations aliasdecls; // corresponding AliasDeclarations for alias=name pairs

    const char *kind() const;
    Visibility visible();
    Import *syntaxCopy(Dsymbol *s);    // copy only syntax trees
    void load(Scope *sc);
    void importAll(Scope *sc);
    Dsymbol *toAlias();
    void addMember(Scope *sc, ScopeDsymbol *sds);
    void setScope(Scope* sc);
    Dsymbol *search(const Loc &loc, Identifier *ident, int flags = SearchLocalsOnly);
    bool overloadInsert(Dsymbol *s);

    Import *isImport() { return this; }
    void accept(Visitor *v) { v->visit(this); }
};
