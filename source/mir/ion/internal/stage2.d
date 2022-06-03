module mir.ion.internal.stage2;

version (LDC) import ldc.attributes;
import mir.bitop;
import mir.ion.internal.simd;

version (LDC)
{
    version (AArch64)
        version = Neon;
}

version (X86)
    version = X86_Any;

version (X86_64)
    version = X86_Any;

@system pure nothrow @nogc:

version (Neon)
{
    alias stage2 = stage2_impl_neon;
}
else
void stage2(
    size_t n,
    scope const(ubyte[64])* vector,
    scope ulong[2]* pairedMask,
    )
{
    alias AliasSeq(T...) = T;
    alias params = AliasSeq!(n, vector, pairedMask);
    version (LDC)
    {
        version (X86_Any)
        {
            // static if (!__traits(targetHasFeature, "avx512bw"))
            // {
                import cpuid.x86_any;
                // if (avx512bw)
                //     return stage2_impl_skylake_avx512(params);
                static if (!__traits(targetHasFeature, "avx2"))
                {
                    if (avx2)
                        return stage2_impl_broadwell(params);
                    static if (!__traits(targetHasFeature, "avx"))
                    {
                        if (avx)
                            return stage2_impl_sandybridge(params);
                        static if (!__traits(targetHasFeature, "sse4.2"))
                        {
                            if (sse42) // && popcnt is assumed to be true
                                return stage2_impl_westmere(params);
                            return stage2_impl_generic(params);
                        }
                        else
                            return stage2_impl_westmere(params);
                    }
                    else
                        return stage2_impl_sandybridge(params);
                }
                else
                    return stage2_impl_broadwell(params);
            // }
            // else
            //     return stage2_impl_skylake_avx512(params);
        }
        else
            return stage2_impl_generic(params);
    }
    else
        return stage2_impl_generic(params);
}

version (X86_Any)
{

    version (LDC) @target("arch=westmere")
    private void stage2_impl_westmere(
        size_t n,
        scope const(ubyte[64])* vector,
        scope ulong[2]* pairedMask,
        )
    {
        pragma(inline, false);
        __vector(ubyte[16]) whiteSpaceMask = [
            ' ', 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, '\t', '\n', 0x80, 0x80, '\r', 0x80, 0x80
        ];
        // , 2C : 3A [ 5B ] 5D { 7B } 7D
        __vector(ubyte[16]) operatorMask = [
            ',', '}', 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, ':', '{',
        ];

        alias equal = equalMaskB!(__vector(ubyte[16]));

        do
        {
            import mir.internal.utility;
            auto v =  cast(__vector(ubyte[16])[4])*vector++;
            align(16) ushort[4][2] result;
            static foreach (i; Iota!(v.length))
            {{
                auto s = v[i] - ',';
                auto m = v[i] | ubyte(0x20);
                auto b = __builtin_ia32_pshufb(whiteSpaceMask, v[i]);
                auto a = __builtin_ia32_pshufb(operatorMask, s);
                result[1][i] = equal(v[i], b);
                result[0][i] = equal(m, a);
            }}
            *pairedMask++ = cast(ulong[2]) result;
        }
        while(--n);
    }

    version (LDC) @target("arch=sandybridge")
    private void stage2_impl_sandybridge(
        size_t n,
        scope const(ubyte[64])* vector,
        scope ulong[2]* pairedMask,
        )
    {
        pragma(inline, false);
        __vector(ubyte[16]) whiteSpaceMask = [
            ' ', 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, '\t', '\n', 0x80, 0x80, '\r', 0x80, 0x80
        ];
        // , 2C : 3A [ 5B ] 5D { 7B } 7D
        __vector(ubyte[16]) operatorMask = [
            ',', '}', 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, ':', '{',
        ];

        alias equal = equalMaskB!(__vector(ubyte[16]));

        do
        {
            auto v =  cast(__vector(ubyte[16])[4])*vector++;
            align(8) ushort[4][2] result;
            import mir.internal.utility: Iota;
            static foreach (i; Iota!(v.length))
            {{
                auto s = v[i] - ',';
                auto m = v[i] | ubyte(0x20);
                auto b = __builtin_ia32_pshufb(whiteSpaceMask, v[i]);
                auto a = __builtin_ia32_pshufb(operatorMask, s);
                result[1][i] = equal(v[i], b);
                result[0][i] = equal(m, a);
            }}
            *pairedMask++ = cast(ulong[2]) result;
        }
        while(--n);
    }

    version (LDC) @target("arch=broadwell")
    private void stage2_impl_broadwell(
        size_t n,
        scope const(ubyte[64])* vector,
        scope ulong[2]* pairedMask,
        )
    {
        pragma(inline, false);
        __vector(ubyte[32]) whiteSpaceMask = [
            ' ', 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, '\t', '\n', 0x80, 0x80, '\r', 0x80, 0x80,
            ' ', 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, '\t', '\n', 0x80, 0x80, '\r', 0x80, 0x80,
        ];
        __vector(ubyte[32]) operatorMask = [
            ',', '}', 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, ':', '{',
            ',', '}', 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, ':', '{',
        ];

        alias equal = equalMaskB!(__vector(ubyte[32]));

        do
        {
            auto v =  cast(__vector(ubyte[32])[2])*vector++;
            align(8) uint[v.length][2] result;
            import mir.internal.utility: Iota;
            static foreach (i; Iota!(v.length))
            {{
                auto s = v[i] - ',';
                auto m = v[i] | ubyte(0x20);
                auto b = __builtin_ia32_pshufb256(whiteSpaceMask, v[i]);
                auto a = __builtin_ia32_pshufb256(operatorMask, s);
                result[1][i] = equal(v[i], b);
                result[0][i] = equal(m, a);
            }}
            *pairedMask++ = cast(ulong[2]) result;
        }
        while(--n);
    }

    version (LDC) @target("arch=skylake-avx512")
    private void stage2_impl_skylake_avx512(
        size_t n,
        scope const(ubyte[64])* vector,
        scope ulong[2]* pairedMask,
        )
    {
        pragma(inline, false);
        __vector(ubyte[64]) whiteSpaceMask = [
            0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, '\t', '\n', 0x80, 0x80, '\r', 0x80, 0x80,
            0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,
            ' ', 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,
            0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,
        ];
        // , 2C : 3A [ 5B ] 5D { 7B } 7D
        __vector(ubyte[64]) operatorMask = [
            0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,
            0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, '[', 0x80, ']', 0x80, 0x80,
            0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, ',', 0x80, 0x80, 0x80,
            0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, ':', '{', 0x80, '}', 0x80, 0x80,
        ];

        alias equal = equalMaskB!(__vector(ubyte[64]));

        do
        {
            auto v = *cast(__vector(ubyte[64])*)(vector++);
            auto a = __builtin_ia32_pshufb512(operatorMask, v);
            auto b = __builtin_ia32_pshufb512(whiteSpaceMask, v);
            pairedMask[0][0] = equal(v, a);
            pairedMask[0][1] = equal(v, b);
            pairedMask++;
        }
        while(--n);
    }
}

private void stage2_impl_generic(
    size_t n,
    scope const(ubyte[64])* vector,
    scope ulong[2]* pairedMask,
    )
{
    pragma(inline, false);
    do
    {
        ulong[2] maskPair;
        foreach_reverse (b; *vector++)
        {
            maskPair[0] <<= 1;
            maskPair[1] <<= 1;
            switch (b)
            {
                case '\n':
                case '\r':
                case '\t':
                case ' ':
                    maskPair[1] |= 1;
                    break;
                case ',':
                case ':':
                case '[':
                case ']':
                case '{':
                case '}':
                    maskPair[0] |= 1;
                    break;
                default:
                    break;
            }
        }
        *pairedMask++ = maskPair;
    }
    while(--n);
}

version (LDC) version (AArch64)
private void stage2_impl_neon(
    size_t n,
    scope const(ubyte[64])* vector,
    scope ulong[2]* pairedMask,
    )
{
    pragma(inline, false);
    __vector(ubyte[16]) whiteSpaceMask0 = [
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x00, 0x00, 0x0B, 0x0C, 0x00, 0x0E, 0x0F, 0x10,
    ];
    __vector(ubyte[16]) whiteSpaceMask1 = [
        0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x00,
    ];
    // , 2C : 3A [ 5B ] 5D { 7B } 7D
    __vector(ubyte[16]) operatorMask = [
        ',', '}', 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, ':', '{',
    ];

    alias equal = equalMaskB!(__vector(ubyte[16]));

    do
    {
        import mir.internal.utility;
        auto v =  cast(__vector(ubyte[16])[4])*vector++;
        align(16) ushort[4][2] result;
        import mir.stdio;
        import mir.ndslice.topology: bitwise, as;
        static foreach (i; Iota!(v.length))
        {{
            __vector(ubyte[16]) vim1 = v[i] - 1;
            __vector(ubyte[16]) mar1 = neon_tbx2_v16i8(v[i], whiteSpaceMask0, whiteSpaceMask1, vim1);
            ushort meq1 = equal(mar1, v[i]);
            result[1][i] = cast(ushort) ~cast(uint) meq1;

            auto a = neon_tbl1_v16i8(operatorMask, (v[i] - ',') & 0x8F);
            result[0][i] = equal(v[i] | ubyte(0x20), a);
        }}
        *pairedMask++ = cast(ulong[2]) result;
    }
    while(--n);
}

version(mir_ion_test) unittest
{
    align(64) ubyte[64][4] dataA;

    auto data = dataA.ptr.ptr[0 .. dataA.length * 64];

    foreach (i; 0 .. 256)
        data[i] = cast(ubyte)i;
    
    ulong[2][dataA.length] pairedMasks;

    stage2(pairedMasks.length, cast(const) dataA.ptr, pairedMasks.ptr);

    import mir.ndslice;
    auto maskData = pairedMasks.sliced;
    auto obits = maskData.map!"a[0]".bitwise;
    auto wbits = maskData.map!"a[1]".bitwise;
    assert(obits.length == 256);
    assert(wbits.length == 256);

    foreach (i; 0 .. 256)
    {
        assert (obits[i] == (i == ',' || i == ':' || i == '[' || i == ']' || i == '{' || i == '}'));
        assert (wbits[i] == (i == ' ' || i == '\t' || i == '\r' || i == '\n'));
    }
}
