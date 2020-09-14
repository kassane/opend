/*
https://issues.dlang.org/show_bug.cgi?id=21219

REQUIRED_ARGS: -o- -HC
TEST_OUTPUT:
---
// Automatically generated by Digital Mars D Compiler

#pragma once

#include <stddef.h>
#include <stdint.h>


class ClassFromStruct
{
public:
    void foo();
    ClassFromStruct()
    {
    }
};

class ClassFromClass
{
public:
    virtual void foo();
};

struct StructFromStruct
{
    void foo();
    StructFromStruct()
    {
    }
};

struct StructFromClass
{
    virtual void foo();
};
---
*/

extern (C++, class) struct ClassFromStruct
{
    void foo() {}
}

extern (C++, class) class ClassFromClass
{
    void foo() {}
}

extern (C++, struct) struct StructFromStruct
{
    void foo() {}
}

extern (C++, struct) class StructFromClass
{
    void foo() {}
}