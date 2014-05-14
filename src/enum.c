
// Copyright (c) 1999-2013 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

#include <stdio.h>
#include <assert.h>

#include "root.h"
#include "enum.h"
#include "mtype.h"
#include "scope.h"
#include "id.h"
#include "expression.h"
#include "module.h"
#include "declaration.h"
#include "init.h"

/********************************* EnumDeclaration ****************************/

EnumDeclaration::EnumDeclaration(Loc loc, Identifier *id, Type *memtype)
    : ScopeDsymbol(id)
{
    //printf("EnumDeclaration() %s\n", toChars());
    this->loc = loc;
    type = new TypeEnum(this);
    this->memtype = memtype;
    maxval = NULL;
    minval = NULL;
    defaultval = NULL;
    sinit = NULL;
    isdeprecated = false;
    protection = PROTundefined;
    parent = NULL;
    added = false;
    inuse = 0;
}

Dsymbol *EnumDeclaration::syntaxCopy(Dsymbol *s)
{
    Type *t = NULL;
    if (memtype)
        t = memtype->syntaxCopy();

    EnumDeclaration *ed;
    if (s)
    {   ed = (EnumDeclaration *)s;
        ed->memtype = t;
    }
    else
        ed = new EnumDeclaration(loc, ident, t);
    ScopeDsymbol::syntaxCopy(ed);
    if (isAnonymous())
    {
        for (size_t i = 0; i < members->dim; i++)
        {
            EnumMember *em = (*members)[i]->isEnumMember();
            em->ed = ed;
        }
    }
    return ed;
}

void EnumDeclaration::setScope(Scope *sc)
{
    if (semanticRun > PASSinit)
        return;
    ScopeDsymbol::setScope(sc);
}

int EnumDeclaration::addMember(Scope *sc, ScopeDsymbol *sds, int memnum)
{
#if 0
    printf("EnumDeclaration::addMember() %s\n", toChars());
    for (size_t i = 0; i < members->dim; i++)
    {
        EnumMember *em = (*members)[i]->isEnumMember();
        printf("    member %s\n", em->toChars());
    }
#endif

    /* Anonymous enum members get added to enclosing scope.
     */
    ScopeDsymbol *scopesym = isAnonymous() ? sds : this;

    if (!isAnonymous())
    {
        ScopeDsymbol::addMember(sc, sds, memnum);

        if (!symtab)
            symtab = new DsymbolTable();
    }

    if (members)
    {
        for (size_t i = 0; i < members->dim; i++)
        {
            EnumMember *em = (*members)[i]->isEnumMember();
            em->ed = this;
            //printf("add %s to scope %s\n", em->toChars(), scopesym->toChars());
            em->addMember(sc, scopesym, 1);
        }
    }
    added = true;
    return 1;
}


void EnumDeclaration::semantic(Scope *sc)
{
    //printf("EnumDeclaration::semantic(sd = %p, '%s') %s\n", sc->scopesym, sc->scopesym->toChars(), toChars());
    //printf("EnumDeclaration::semantic() %p %s\n", this, toChars());
    if (!members && !memtype)               // enum ident;
        return;

    if (semanticRun >= PASSsemanticdone)
        return;             // semantic() already completed
    if (semanticRun == PASSsemantic)
    {
        assert(memtype);
        ::error(loc, "circular reference to enum base type %s", memtype->toChars());
        errors = true;
        semanticRun = PASSsemanticdone;
        return;
    }
    semanticRun = PASSsemantic;

    if (!symtab)
        symtab = new DsymbolTable();

    Scope *scx = NULL;
    if (scope)
    {
        sc = scope;
        scx = scope;            // save so we don't make redundant copies
        scope = NULL;
    }

    unsigned dprogress_save = Module::dprogress;

    if (sc->stc & STCdeprecated)
        isdeprecated = true;
    userAttribDecl = sc->userAttribDecl;

    parent = sc->parent;
    protection = sc->protection;

    /* The separate, and distinct, cases are:
     *  1. enum { ... }
     *  2. enum : memtype { ... }
     *  3. enum ident { ... }
     *  4. enum ident : memtype { ... }
     *  5. enum ident : memtype;
     *  6. enum ident;
     */

    type = type->semantic(loc, sc);

    if (memtype)
    {
        memtype = memtype->semantic(loc, sc);

        /* Check to see if memtype is forward referenced
         */
        if (memtype->ty == Tenum)
        {   EnumDeclaration *sym = (EnumDeclaration *)memtype->toDsymbol(sc);
            if (!sym->memtype || !sym->members || !sym->symtab || sym->scope)
            {
                // memtype is forward referenced, so try again later
                scope = scx ? scx : sc->copy();
                scope->setNoFree();
                scope->module->addDeferredSemantic(this);
                Module::dprogress = dprogress_save;
                //printf("\tdeferring %s\n", toChars());
                semanticRun = PASSinit;
                return;
            }
        }
        if (memtype->ty == Tvoid)
        {
            error("base type must not be void");
            memtype = Type::terror;
        }
        if (memtype->ty == Terror)
        {
            errors = true;
            if (members)
            {
                for (size_t i = 0; i < members->dim; i++)
                {
                    Dsymbol *s = (*members)[i];
                    s->errors = true;               // poison all the members
                }
            }
            semanticRun = PASSsemanticdone;
            return;
        }
    }

    semanticRun = PASSsemanticdone;

    if (!members)               // enum ident : memtype;
        return;

    if (members->dim == 0)
    {
        error("enum %s must have at least one member", toChars());
        errors = true;
        return;
    }

    Module::dprogress++;

    Scope *sce;
    if (isAnonymous())
        sce = sc;
    else
    {
        sce = sc->push(this);
        sce->parent = this;
    }
    sce = sce->startCTFE();
    sce->setNoFree();                   // needed for getMaxMinValue()

    /* Each enum member gets the sce scope
     */
    for (size_t i = 0; i < members->dim; i++)
    {
        EnumMember *em = (*members)[i]->isEnumMember();
        if (em)
            em->scope = sce;
    }

    if (!added)
    {
        /* addMember() is not called when the EnumDeclaration appears as a function statement,
         * so we have to do what addMember() does and install the enum members in the right symbol
         * table
         */
        ScopeDsymbol *scopesym = NULL;
        if (isAnonymous())
        {
            /* Anonymous enum members get added to enclosing scope.
             */
            for (Scope *sct = sce; 1; sct = sct->enclosing)
            {
                assert(sct);
                if (sct->scopesym)
                {
                    scopesym = sct->scopesym;
                    if (!sct->scopesym->symtab)
                        sct->scopesym->symtab = new DsymbolTable();
                    break;
                }
            }
        }
        else
            // Otherwise enum members are in the EnumDeclaration's symbol table
            scopesym = this;

        for (size_t i = 0; i < members->dim; i++)
        {
            EnumMember *em = (*members)[i]->isEnumMember();
            if (em)
            {
                em->ed = this;
                em->addMember(sc, scopesym, 1);
            }
        }
    }

    for (size_t i = 0; i < members->dim; i++)
    {
        EnumMember *em = (*members)[i]->isEnumMember();
        if (em)
            em->semantic(em->scope);
    }
    //printf("defaultval = %lld\n", defaultval);

    //if (defaultval) printf("defaultval: %s %s\n", defaultval->toChars(), defaultval->type->toChars());
    //members->print();
}

/******************************
 * Get the value of the .max/.min property as an Expression
 * Input:
 *      id      Id::max or Id::min
 */

Expression *EnumDeclaration::getMaxMinValue(Loc loc, Identifier *id)
{
    //printf("EnumDeclaration::getMaxValue()\n");
    bool first = true;

    Expression **pval = (id == Id::max) ? &maxval : &minval;

    if (inuse)
    {
        error(loc, "recursive definition of .%s property", id->toChars());
        goto Lerrors;
    }
    if (*pval)
        return *pval;

    if (scope)
        semantic(scope);
    if (errors)
        goto Lerrors;
    if (semanticRun == PASSinit || !members)
    {
        error("is forward referenced looking for .%s", id->toChars());
        goto Lerrors;
    }
    if (!(memtype && memtype->isintegral()))
    {
        error(loc, "has no .%s property because base type %s is not an integral type",
                id->toChars(),
                memtype ? memtype->toChars() : "");
        goto Lerrors;
    }

    for (size_t i = 0; i < members->dim; i++)
    {
        EnumMember *em = (*members)[i]->isEnumMember();
        if (!em)
            continue;
        if (em->errors)
            goto Lerrors;

        Expression *e = em->value;
        if (first)
        {
            *pval = e;
            first = false;
        }
        else
        {
            /* In order to work successfully with UDTs,
             * build expressions to do the comparisons,
             * and let the semantic analyzer and constant
             * folder give us the result.
             */

            /* Compute:
             *   if (e > maxval)
             *      maxval = e;
             */
            Expression *ec = new CmpExp(id == Id::max ? TOKgt : TOKlt, em->loc, e, *pval);
            inuse++;
            ec = ec->semantic(em->scope);
            inuse--;
            ec = ec->ctfeInterpret();
            if (ec->toInteger())
                *pval = e;
        }
    }
    return *pval;

Lerrors:
    *pval = new ErrorExp();
    return *pval;
}

Expression *EnumDeclaration::getDefaultValue(Loc loc)
{
    //printf("EnumDeclaration::getDefaultValue() %p %s\n", this, toChars());
    if (defaultval)
        return defaultval;

    if (scope)
        semantic(scope);
    if (errors)
        goto Lerrors;
    if (semanticRun == PASSinit || !members)
    {
        error(loc, "forward reference of %s.init", toChars());
        goto Lerrors;
    }

    for (size_t i = 0; i < members->dim; i++)
    {
        EnumMember *em = (*members)[i]->isEnumMember();
        if (!em)
            continue;
        defaultval = em->value;
        return defaultval;
    }

Lerrors:
    defaultval = new ErrorExp();
    return defaultval;
}

Type *EnumDeclaration::getMemtype(Loc loc)
{
    if (loc.linnum == 0)
        loc = this->loc;
    if (scope)
    {
        /* Enum is forward referenced. We don't need to resolve the whole thing,
         * just the base type
         */
        if (memtype)
            memtype = memtype->semantic(loc, scope);
        else
        {
            if (!isAnonymous() && members)
                memtype = Type::tint32;
        }
    }
    if (!memtype)
    {
        if (!isAnonymous() && members)
            memtype = Type::tint32;
        else
        {
            error(loc, "is forward referenced looking for base type");
            return Type::terror;
        }
    }
    return memtype;
}

bool EnumDeclaration::oneMember(Dsymbol **ps, Identifier *ident)
{
    if (isAnonymous())
        return Dsymbol::oneMembers(members, ps, ident);
    return Dsymbol::oneMember(ps, ident);
}

void EnumDeclaration::toCBuffer(OutBuffer *buf, HdrGenState *hgs)
{
    buf->writestring("enum ");
    if (ident)
    {   buf->writestring(ident->toChars());
        buf->writeByte(' ');
    }
    if (memtype)
    {
        buf->writestring(": ");
        memtype->toCBuffer(buf, NULL, hgs);
    }
    if (!members)
    {
        buf->writeByte(';');
        buf->writenl();
        return;
    }
    buf->writenl();
    buf->writeByte('{');
    buf->writenl();
    buf->level++;
    for (size_t i = 0; i < members->dim; i++)
    {
        EnumMember *em = (*members)[i]->isEnumMember();
        if (!em)
            continue;
        em->toCBuffer(buf, hgs);
        buf->writeByte(',');
        buf->writenl();
    }
    buf->level--;
    buf->writeByte('}');
    buf->writenl();
}

Type *EnumDeclaration::getType()
{
    return type;
}

const char *EnumDeclaration::kind()
{
    return "enum";
}

bool EnumDeclaration::isDeprecated()
{
    return isdeprecated;
}

PROT EnumDeclaration::prot()
{
    return protection;
}

Dsymbol *EnumDeclaration::search(Loc loc, Identifier *ident, int flags)
{
    //printf("%s.EnumDeclaration::search('%s')\n", toChars(), ident->toChars());
    if (scope)
        // Try one last time to resolve this enum
        semantic(scope);

    if (!members || !symtab || scope)
    {
        error("is forward referenced when looking for '%s'", ident->toChars());
        //*(char*)0=0;
        return NULL;
    }

    Dsymbol *s = ScopeDsymbol::search(loc, ident, flags);
    return s;
}

/********************************* EnumMember ****************************/

EnumMember::EnumMember(Loc loc, Identifier *id, Expression *value, Type *type)
    : Dsymbol(id)
{
    this->ed = NULL;
    this->value = value;
    this->origValue = value;
    this->type = type;
    this->loc = loc;
    this->vd = NULL;
}

Dsymbol *EnumMember::syntaxCopy(Dsymbol *s)
{
    Expression *e = NULL;
    if (value)
        e = value->syntaxCopy();

    Type *t = NULL;
    if (type)
        t = type->syntaxCopy();

    EnumMember *em;
    if (s)
    {   em = (EnumMember *)s;
        em->loc = loc;
        em->value = e;
        em->type = t;
        em->origValue = origValue ? origValue->syntaxCopy() : NULL;
    }
    else
    {
        em = new EnumMember(loc, ident, e, t);
        em->origValue = origValue ? origValue->syntaxCopy() : NULL;
    }
    return em;
}

void EnumMember::toCBuffer(OutBuffer *buf, HdrGenState *hgs)
{
    if (type)
        type->toCBuffer(buf, ident, hgs);
    else
        buf->writestring(ident->toChars());
    if (value)
    {
        buf->writestring(" = ");
        value->toCBuffer(buf, hgs);
    }
}

const char *EnumMember::kind()
{
    return "enum member";
}

void EnumMember::semantic(Scope *sc)
{
    //printf("EnumMember::semantic() %s\n", toChars());
    if (errors || semanticRun >= PASSsemanticdone)
        return;
    if (semanticRun == PASSsemantic)
    {
        error("circular reference to enum member");
    Lerrors:
        errors = true;
        semanticRun = PASSsemanticdone;
        return;
    }
    assert(ed);
    ed->semantic(sc);
    if (ed->errors)
        goto Lerrors;

    if (errors || semanticRun >= PASSsemanticdone)
        return;

    semanticRun = PASSsemantic;
    if (scope)
        sc = scope;

    // The first enum member is special
    bool first = (this == (*ed->members)[0]);

    if (type)
    {
        type = type->semantic(loc, sc);
        assert(value);          // "type id;" is not a valid enum member declaration
    }

    if (value)
    {
        Expression *e = value;
        assert(e->dyncast() == DYNCAST_EXPRESSION);
        e = e->semantic(sc);
        e = resolveProperties(sc, e);
        e = e->ctfeInterpret();
        if (first && !ed->memtype && !ed->isAnonymous())
        {
            ed->memtype = e->type;
            if (ed->memtype->ty == Terror)
            {
                ed->errors = true;
                goto Lerrors;
            }
        }

        if (ed->memtype && !type)
        {
            e = e->implicitCastTo(sc, ed->memtype);
            e = e->ctfeInterpret();

            // save origValue for better json output
            origValue = e;

            if (!ed->isAnonymous())
                e = e->castTo(sc, ed->type);
        }
        else if (type)
        {
            e = e->implicitCastTo(sc, type);
            e = e->ctfeInterpret();
            assert(ed->isAnonymous());

            // save origValue for better json output
            origValue = e;
        }
        value = e;
    }
    else if (first)
    {
        Type *t;
        if (ed->memtype)
            t = ed->memtype;
        else
        {
            t = Type::tint32;
            if (!ed->isAnonymous())
                ed->memtype = t;
        }
        Expression *e = new IntegerExp(loc, 0, Type::tint32);
        e = e->implicitCastTo(sc, t);
        e = e->ctfeInterpret();

        // save origValue for better json output
        origValue = e;

        if (!ed->isAnonymous())
            e = e->castTo(sc, ed->type);
        value = e;
    }
    else
    {
        /* Find the previous enum member,
         * and set this to be the previous value + 1
         */
        EnumMember *emprev = NULL;
        for (size_t i = 0; i < ed->members->dim; i++)
        {
            EnumMember *em = (*ed->members)[i]->isEnumMember();
            if (em)
            {
                if (em == this)
                    break;
                emprev = em;
            }
        }
        assert(emprev);
        if (emprev->semanticRun < PASSsemanticdone)    // if forward reference
            emprev->semantic(emprev->scope);    // resolve it
        if (emprev->errors)
            goto Lerrors;

        Expression *eprev = emprev->value;
        Type *tprev = eprev->type->equals(ed->type) ? ed->memtype : eprev->type;

        Expression *emax = tprev->getProperty(ed->loc, Id::max, 0);
        emax = emax->semantic(sc);
        emax = emax->ctfeInterpret();

        // Set value to (eprev + 1).
        // But first check that (eprev != emax)
        assert(eprev);
        Expression *e = new EqualExp(TOKequal, loc, eprev, emax);
        e = e->semantic(sc);
        e = e->ctfeInterpret();
        if (e->toInteger())
        {
            error("initialization with (%s.%s + 1) causes overflow for type '%s'", emprev->ed->toChars(), emprev->toChars(), ed->type->toBasetype()->toChars());
            goto Lerrors;
        }

        // Now set e to (eprev + 1)
        e = new AddExp(loc, eprev, new IntegerExp(loc, 1, Type::tint32));
        e = e->semantic(sc);
        e = e->castTo(sc, eprev->type);
        e = e->ctfeInterpret();

        // save origValue (without cast) for better json output
        if (e->op != TOKerror)  // avoid duplicate diagnostics
        {
            assert(emprev->origValue);
            origValue = new AddExp(loc, emprev->origValue, new IntegerExp(loc, 1, Type::tint32));
            origValue = origValue->semantic(sc);
            origValue = origValue->ctfeInterpret();
        }

        if (e->op == TOKerror)
            goto Lerrors;
        if (e->type->isfloating())
        {
            // Check that e != eprev (not always true for floats)
            Expression *etest = new EqualExp(TOKequal, loc, e, eprev);
            etest = etest->semantic(sc);
            etest = etest->ctfeInterpret();
            if (etest->toInteger())
            {
                error("has inexact value, due to loss of precision");
                goto Lerrors;
            }
        }
        value = e;
    }

    assert(origValue);
    semanticRun = PASSsemanticdone;
}

Expression *EnumMember::getVarExp(Loc loc, Scope *sc)
{
    semantic(sc);
    if (errors)
        return new ErrorExp();
    if (!vd)
    {
        assert(value);
        vd = new VarDeclaration(loc, type, ident, new ExpInitializer(loc, value->copy()));

        vd->storage_class = STCmanifest;
        vd->semantic(sc);

        vd->protection = ed->isAnonymous() ? ed->protection : PROTpublic;
        vd->parent = ed->isAnonymous() ? ed->parent : ed;
        vd->userAttribDecl = ed->isAnonymous() ? ed->userAttribDecl : NULL;
    }
    Expression *e = new VarExp(loc, vd);
    return e->semantic(sc);
}
