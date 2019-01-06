/**
* Copyright: Copyright Auburn Sounds 2016-2019.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.emmintrin;

public import inteli.types;
public import inteli.xmmintrin; // SSE2 includes SSE1

import inteli.internals;
import core.math: sqrt, rint;

nothrow @nogc:

// SSE2 instructions
// https://software.intel.com/sites/landingpage/IntrinsicsGuide/#techs=SSE2

__m128i _mm_add_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(short8)a + cast(short8)b);
}

__m128i _mm_add_epi32 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(int4)a + cast(int4)b);
}

__m128i _mm_add_epi64 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(long2)a + cast(long2)b);
}

__m128i _mm_add_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(byte16)a + cast(byte16)b);
}

__m128d _mm_add_sd(__m128d a, __m128d b) pure @safe
{
    a[0] += b[0];
    return a;
}
unittest
{
    __m128d a = [1.5, -2.0];
    a = _mm_add_sd(a, a);
    assert(a.array == [3.0, -2.0]);
}


__m128d _mm_add_pd (__m128d a, __m128d b) pure @safe
{
    return a + b;
}
unittest
{
    __m128d a = [1.5, -2.0];
    a = _mm_add_pd(a, a);
    assert(a.array == [3.0, -4.0]);
}

// MMXREG: _mm_add_si64

version(LDC)
{
    alias _mm_adds_epi16 = __builtin_ia32_paddsw128;
}
else
{
    __m128i _mm_adds_epi16(__m128i a, __m128i b) pure @trusted
    {
        short[8] res;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        foreach(i; 0..8)
            res[i] = saturateSignedIntToSignedShort(sa.array[i] + sb.array[i]);
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    short8 res = cast(short8) _mm_adds_epi16(_mm_set_epi16(7, 6, 5, 4, 3, 2, 1, 0),
                                             _mm_set_epi16(7, 6, 5, 4, 3, 2, 1, 0));
    static immutable short[8] correctResult = [0, 2, 4, 6, 8, 10, 12, 14];
    assert(res.array == correctResult);
}

version(LDC)
{
    alias _mm_adds_epi8 = __builtin_ia32_paddsb128;
}
else
{
    __m128i _mm_adds_epi8(__m128i a, __m128i b) pure @trusted
    {
        byte[16] res;
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        foreach(i; 0..16)
            res[i] = saturateSignedWordToSignedByte(sa.array[i] + sb.array[i]);
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    byte16 res = cast(byte16) _mm_adds_epi8(_mm_set_epi8(15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
                                            _mm_set_epi8(15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0));
    static immutable byte[16] correctResult = [0, 2, 4, 6, 8, 10, 12, 14,
                                               16, 18, 20, 22, 24, 26, 28, 30];
    assert(res.array == correctResult);
}

version(LDC)
{
    alias _mm_adds_epu8 = __builtin_ia32_paddusb128;
}
else
{
    __m128i _mm_adds_epu8(__m128i a, __m128i b) pure @trusted
    {
        ubyte[16] res;
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        foreach(i; 0..16)
            res[i] = saturateSignedWordToUnsignedByte(cast(ubyte)(sa.array[i]) + cast(ubyte)(sb.array[i]));
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}

version(LDC)
{
    alias _mm_adds_epu16 = __builtin_ia32_paddusw128;
}
else
{
    __m128i _mm_adds_epu16(__m128i a, __m128i b) pure @trusted
    {
        ushort[8] res;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        foreach(i; 0..8)
            res[i] = saturateSignedIntToUnsignedShort(cast(ushort)(sa.array[i]) + cast(ushort)(sb.array[i]));
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}

__m128d _mm_and_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d)( cast(__m128i)a & cast(__m128i)b );
}

__m128i _mm_and_si128 (__m128i a, __m128i b) pure @safe
{
    return a & b;
}

__m128d _mm_andnot_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d)( (~cast(__m128i)a) & cast(__m128i)b );
}

__m128i _mm_andnot_si128 (__m128i a, __m128i b) pure @safe
{
    return (~a) & b;
}

version(LDC)
{
    __m128i _mm_avg_epu16 (__m128i a, __m128i b) pure @safe
    {
        // Generates pavgw even in LDC 1.0, even in -O0
        enum ir = `
            %ia = zext <8 x i16> %0 to <8 x i32>
            %ib = zext <8 x i16> %1 to <8 x i32>
            %isum = add <8 x i32> %ia, %ib
            %isum1 = add <8 x i32> %isum, < i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1>
            %isums = lshr <8 x i32> %isum1, < i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1>
            %r = trunc <8 x i32> %isums to <8 x i16>
            ret <8 x i16> %r`;
        return cast(__m128i) LDCInlineIR!(ir, short8, short8, short8)(cast(short8)a, cast(short8)b);        
    }
}
else
{
    __m128i _mm_avg_epu16 (__m128i a, __m128i b) pure @safe
    {
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 sr = void;
        foreach(i; 0..8)
        {
            sr[i] = cast(ushort)( (cast(ushort)(sa[i]) + cast(ushort)(sb[i]) + 1) >> 1 );
        }
        return cast(int4)sr;
    }
}
unittest
{
    __m128i A = _mm_set1_epi16(31);
    __m128i B = _mm_set1_epi16(64);
    short8 avg = cast(short8)(_mm_avg_epu16(A, B));
    foreach(i; 0..8)
        assert(avg[i] == 48);
}

version(LDC)
{
    __m128i _mm_avg_epu8 (__m128i a, __m128i b) pure @safe
    {
        // Generates pavgb even in LDC 1.0, even in -O0
        enum ir = `
            %ia = zext <16 x i8> %0 to <16 x i16>
            %ib = zext <16 x i8> %1 to <16 x i16>
            %isum = add <16 x i16> %ia, %ib
            %isum1 = add <16 x i16> %isum, < i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1>
            %isums = lshr <16 x i16> %isum1, < i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1>
            %r = trunc <16 x i16> %isums to <16 x i8>
            ret <16 x i8> %r`;
        return cast(__m128i) LDCInlineIR!(ir, byte16, byte16, byte16)(cast(byte16)a, cast(byte16)b);        
    }
}
else
{
    __m128i _mm_avg_epu8 (__m128i a, __m128i b)
    {
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        byte16 sr = void;
        foreach(i; 0..16)
        {
            sr[i] = cast(ubyte)( (cast(ubyte)(sa[i]) + cast(ubyte)(sb[i]) + 1) >> 1 );
        }
        return cast(int4)sr;
    }
}
unittest
{
    __m128i A = _mm_set1_epi8(31);
    __m128i B = _mm_set1_epi8(64);
    byte16 avg = cast(byte16)(_mm_avg_epu8(A, B));
    foreach(i; 0..16)
        assert(avg[i] == 48);
}

// Note: unlike Intel API, shift amount is a compile-time parameter.
__m128i _mm_bslli_si128(int bits)(__m128i a) pure @safe
{
    // Generates pslldq starting with LDC 1.1 -O2
    __m128i zero = _mm_setzero_si128();
    return cast(__m128i) 
        shufflevector!(byte16, 16 - bits, 17 - bits, 18 - bits, 19 - bits,
                               20 - bits, 21 - bits, 22 - bits, 23 - bits,
                               24 - bits, 25 - bits, 26 - bits, 27 - bits,
                               28 - bits, 29 - bits, 30 - bits, 31 - bits)
        (cast(byte16)zero, cast(byte16)a);
}
unittest
{
    __m128i toShift = _mm_setr_epi8(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
    byte[16] exact =              [0, 0, 0, 0, 0, 0, 1, 2, 3, 4,  5,  6,  7,  8,  9, 10];
    __m128i result = _mm_bslli_si128!5(toShift);
    assert(  (cast(byte16)result).array == exact);
}

// Note: unlike Intel API, shift amount is a compile-time parameter.
__m128i _mm_bsrli_si128(int bits)(__m128i a) pure @safe
{
    // Generates psrldq starting with LDC 1.1 -O2
    __m128i zero = _mm_setzero_si128();
    return  cast(__m128i) 
        shufflevector!(byte16, 0 + bits, 1 + bits, 2 + bits, 3 + bits,
                               4 + bits, 5 + bits, 6 + bits, 7 + bits,
                               8 + bits, 9 + bits, 10 + bits, 11 + bits,
                               12 + bits, 13 + bits, 14 + bits, 15 + bits)
        (cast(byte16)a, cast(byte16)zero);
}
unittest
{
    __m128i toShift = _mm_setr_epi8(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
    byte[16] exact =               [5, 6, 7, 8, 9,10,11,12,13,14, 15,  0,  0,  0,  0,  0];
    __m128i result = _mm_bsrli_si128!5(toShift);
    assert( (cast(byte16)result).array == exact);
}

__m128 _mm_castpd_ps (__m128d a) pure @safe
{
    return cast(__m128)a;
}

__m128i _mm_castpd_si128 (__m128d a) pure @safe
{
    return cast(__m128i)a;
}

__m128d _mm_castps_pd (__m128 a) pure @safe
{
    return cast(__m128d)a;
}

__m128i _mm_castps_si128 (__m128 a) pure @safe
{
    return cast(__m128i)a;
}

__m128d _mm_castsi128_pd (__m128i a) pure @safe
{
    return cast(__m128d)a;
}

__m128 _mm_castsi128_ps (__m128i a) pure @safe
{
    return cast(__m128)a;
}

version(LDC)
{
    alias _mm_clflush = __builtin_ia32_clflush;
}
else
{
    void _mm_clflush (const(void)* p) pure @safe
    {
        version(D_InlineAsm_X86)
        {
            asm pure nothrow @nogc @safe
            {
                mov EAX, p;
                clflush [EAX];
            }
        }
        else version(D_InlineAsm_X86_64)
        {
            asm pure nothrow @nogc @safe
            {
                mov RAX, p;
                clflush [RAX];
            }
        }
        else
            static assert(false, "Should implement clflush for this compiler");
    }
}
unittest
{
    ubyte[64] cacheline;
    _mm_clflush(cacheline.ptr);
}


__m128i _mm_cmpeq_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) equalMask!short8(cast(short8)a, cast(short8)b);
}
unittest
{
    short8   A = [-3, -2, -1,  0,  0,  1,  2,  3];
    short8   B = [ 4,  3,  2,  1,  0, -1, -2, -3];
    short[8] E = [ 0,  0,  0,  0, -1,  0,  0,  0];
    short8   R = cast(short8)(_mm_cmpeq_epi16(cast(__m128i)A, cast(__m128i)B));
    assert(R.array == E);
}

__m128i _mm_cmpeq_epi32 (__m128i a, __m128i b) pure @safe
{
    return equalMask!__m128i(a, b);
}
unittest
{
    int4   A = [-3, -2, -1,  0];
    int4   B = [ 4, -2,  2,  0];
    int[4] E = [ 0, -1,  0, -1];
    int4   R = cast(int4)(_mm_cmpeq_epi16(A, B));
    assert(R.array == E);
}

__m128i _mm_cmpeq_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) equalMask!byte16(cast(byte16)a, cast(byte16)b);
}
unittest
{
    __m128i A = _mm_setr_epi8(1, 2, 3, 1, 2, 1, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1);
    __m128i B = _mm_setr_epi8(2, 2, 1, 2, 3, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1, 1);
    byte16 C = cast(byte16) _mm_cmpeq_epi8(A, B);
    byte[16] correct =       [0,-1, 0, 0, 0,-1, 0, 0, 0, 0, 0,-1, 0, 0, 0, -1];
    __m128i D = _mm_cmpeq_epi8(A, B);
    assert(C.array == correct);
}



__m128d _mm_cmpeq_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.oeq)(a, b);
}

__m128d _mm_cmpeq_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.oeq)(a, b);
}

__m128d _mm_cmpge_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.oge)(a, b);
}

__m128d _mm_cmpge_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.oge)(a, b);
}

__m128i _mm_cmpgt_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( greaterMask!short8(cast(short8)a, cast(short8)b));
}
unittest
{
    short8   A = [-3, -2, -1,  0,  0,  1,  2,  3];
    short8   B = [ 4,  3,  2,  1,  0, -1, -2, -3];
    short[8] E = [ 0,  0,  0,  0,  0, -1, -1, -1];
    short8   R = cast(short8)(_mm_cmpgt_epi16(cast(__m128i)A, cast(__m128i)B));
    assert(R.array == E);
}

__m128i _mm_cmpgt_epi32 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( greaterMask!int4(a, b));
}
unittest
{
    int4   A = [-3,  2, -1,  0];
    int4   B = [ 4, -2,  2,  0];
    int[4] E = [ 0, -1,  0,  0];
    int4   R = cast(int4)(_mm_cmpgt_epi32(A, B));
    assert(R.array == E);
}

__m128i _mm_cmpgt_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( greaterMask!byte16(cast(byte16)a, cast(byte16)b));
}
unittest
{
    __m128i A = _mm_setr_epi8(1, 2, 3, 1, 2, 1, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1);
    __m128i B = _mm_setr_epi8(2, 2, 1, 2, 3, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1, 1);
    byte16 C = cast(byte16) _mm_cmpgt_epi8(A, B);
    byte[16] correct =       [0, 0,-1, 0, 0, 0, 0, 0,-1,-1,-1, 0, 0, 0,-1, 0];
    __m128i D = _mm_cmpeq_epi8(A, B);
    assert(C.array == correct);
}

__m128d _mm_cmpgt_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.ogt)(a, b);
}

__m128d _mm_cmpgt_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.ogt)(a, b);
}

__m128d _mm_cmple_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.ole)(a, b);
}

__m128d _mm_cmple_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.ole)(a, b);
}

__m128i _mm_cmplt_epi16 (__m128i a, __m128i b) pure @safe
{
    return _mm_cmpgt_epi16(b, a);
}

__m128i _mm_cmplt_epi32 (__m128i a, __m128i b) pure @safe
{
    return _mm_cmpgt_epi32(b, a);
}

__m128i _mm_cmplt_epi8 (__m128i a, __m128i b) pure @safe
{
    return _mm_cmpgt_epi8(b, a);
}

__m128d _mm_cmplt_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.olt)(a, b);
}

__m128d _mm_cmplt_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.olt)(a, b);
}

__m128d _mm_cmpneq_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.une)(a, b);
}

__m128d _mm_cmpneq_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.une)(a, b);
}

__m128d _mm_cmpnge_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.ult)(a, b);
}

__m128d _mm_cmpnge_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.ult)(a, b);
}

__m128d _mm_cmpngt_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.ule)(a, b);
}

__m128d _mm_cmpngt_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.ule)(a, b);
}

__m128d _mm_cmpnle_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.ugt)(a, b);
}

__m128d _mm_cmpnle_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.ugt)(a, b);
}

__m128d _mm_cmpnlt_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.uge)(a, b);
}

__m128d _mm_cmpnlt_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.uge)(a, b);
}

__m128d _mm_cmpord_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.ord)(a, b);
}

__m128d _mm_cmpord_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.ord)(a, b);
}

__m128d _mm_cmpunord_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmppd!(FPComparison.uno)(a, b);
}

__m128d _mm_cmpunord_sd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d) cmpsd!(FPComparison.uno)(a, b);
}


// Note: we've reverted clang and GCC behaviour with regards to EFLAGS
// Some such comparisons yields true for NaNs, other don't.

int _mm_comieq_sd (__m128d a, __m128d b) pure @safe
{
    return comsd!(FPComparison.ueq)(a, b); // yields true for NaN, same as GCC
}

int _mm_comige_sd (__m128d a, __m128d b) pure @safe
{
    return comsd!(FPComparison.oge)(a, b);
}

int _mm_comigt_sd (__m128d a, __m128d b) pure @safe
{
    return comsd!(FPComparison.ogt)(a, b);
}

int _mm_comile_sd (__m128d a, __m128d b) pure @safe
{
    return comsd!(FPComparison.ule)(a, b); // yields true for NaN, same as GCC
}

int _mm_comilt_sd (__m128d a, __m128d b) pure @safe
{
    return comsd!(FPComparison.ult)(a, b); // yields true for NaN, same as GCC
}

int _mm_comineq_sd (__m128d a, __m128d b) pure @safe
{
    return comsd!(FPComparison.one)(a, b);
}

version(LDC)
{
     __m128d _mm_cvtepi32_pd (__m128i a) pure  @safe
    {
        // Generates cvtdq2pd since LDC 1.0, even without optimizations
        enum ir = `
            %v = shufflevector <4 x i32> %0,<4 x i32> %0, <2 x i32> <i32 0, i32 1>
            %r = sitofp <2 x i32> %v to <2 x double>
            ret <2 x double> %r`;
        return cast(__m128d) LDCInlineIR!(ir, __m128d, __m128i)(a);
    }
}
else
{
    __m128d _mm_cvtepi32_pd (__m128i a) pure  @safe
    {
        double2 r = void;
        r[0] = a[0];
        r[1] = a[1];
        return r;
    }
}
unittest
{
    __m128d A = _mm_cvtepi32_pd(_mm_set1_epi32(54));
    assert(A[0] == 54.0);
    assert(A[1] == 54.0);
}

// PERF: verify the instruction generated
__m128 _mm_cvtepi32_ps(__m128i a) pure @safe
{
    __m128 res;
    res.array[0] = cast(float)a.array[0];
    res.array[1] = cast(float)a.array[1];
    res.array[2] = cast(float)a.array[2];
    res.array[3] = cast(float)a.array[3];
    return res;
}
unittest
{
    __m128 a = _mm_cvtepi32_ps(_mm_setr_epi32(-1, 0, 1, 1000));
    assert(a.array == [-1.0f, 0.0f, 1.0f, 1000.0f]);
}


version(LDC) 
{
    // Like in clang, implemented with a magic intrinsic right now
    alias _mm_cvtpd_epi32 = __builtin_ia32_cvtpd2dq;

/* Unfortunately this generates a cvttpd2dq instruction
    __m128i _mm_cvtpd_epi32 (__m128d a) pure  @safe
    {
        enum ir = `
            %i = fptosi <2 x double> %0 to <2 x i32>
            %r = shufflevector <2 x i32> %i,<2 x i32> zeroinitializer, <4 x i32> <i32 0, i32 1, i32 2, i32 3>        
            ret <4 x i32> %r`;

        return cast(__m128i) inlineIR!(ir, __m128i, __m128d)(a);
    } */
}
else
{
    // Note: the LDC version depends on MXCSR rounding-mode, while
    //       this one depends on possibly another.
    __m128i _mm_cvtpd_epi32 (__m128d a) pure @safe
    {
        __m128i r = _mm_setzero_si128();
        r[0] = cast(int)(rint(a[0]));
        r[1] = cast(int)(rint(a[1]));
        return r; 
    }
}
unittest
{
    int4 A = _mm_cvtpd_epi32(_mm_set_pd(61.0, 55.0));
    assert(A[0] == 55 && A[1] == 61 && A[2] == 0 && A[3] == 0);
}

// MMXREG: _mm_cvtpd_pi32
version(LDC)
{
    alias _mm_cvtpd_ps = __builtin_ia32_cvtpd2ps; // TODO
// MMXREG: _mm_cvtpi32_pd
    alias _mm_cvtps_epi32 = __builtin_ia32_cvtps2dq; // TODO
}

version(LDC)
{
    __m128d _mm_cvtps_pd (__m128 a) pure  @safe
    {
        // Generates cvtps2pd since LDC 1.0, no opt
        enum ir = `
            %v = shufflevector <4 x float> %0,<4 x float> %0, <2 x i32> <i32 0, i32 1>
            %r = fpext <2 x float> %v to <2 x double>
            ret <2 x double> %r`;
        return cast(__m128d) LDCInlineIR!(ir, __m128d, __m128)(a);
    }
}
else
{
     __m128d _mm_cvtps_pd (__m128 a) pure  @safe
    {
        double2 r = void;
        r[0] = a[0];
        r[1] = a[1];
        return r;
    }
}
unittest
{
    __m128d A = _mm_cvtps_pd(_mm_set1_ps(54.0f));
    assert(A[0] == 54.0);
    assert(A[1] == 54.0);
}

double _mm_cvtsd_f64 (__m128d a) pure @safe
{
    return extractelement!(double2, 0)(a);
}

version(LDC)
{
    alias _mm_cvtsd_si32 = __builtin_ia32_cvtsd2si; // TODO
    alias _mm_cvtsd_si64 = __builtin_ia32_cvtsd2si64; // TODO
    alias _mm_cvtsd_si64x = _mm_cvtsd_si64; // TODO
}

version(LDC)
{
    alias _mm_cvtsd_ss = __builtin_ia32_cvtsd2ss; // TODO
}

int _mm_cvtsi128_si32 (__m128i a) pure @safe
{
    return a[0];
}

long _mm_cvtsi128_si64 (__m128i a) pure @safe
{
    long2 la = cast(long2)a;
    return la[0];
}
alias _mm_cvtsi128_si64x = _mm_cvtsi128_si64;

__m128d _mm_cvtsi32_sd(__m128d v, int x) pure @safe
{
    v[0] = cast(double)x;
    return v;
}
unittest
{
    __m128d a = _mm_cvtsi32_sd(_mm_set1_pd(0.0f), 42);
    assert(a.array == [42.0, 0]);
}

__m128i _mm_cvtsi32_si128 (int a) pure @safe
{
    int4 r = [0, 0, 0, 0];
    r[0] = a;
    return r;
}
unittest
{
    __m128i a = _mm_cvtsi32_si128(65);
    assert(a.array == [65, 0, 0, 0]);
}


// Note: on macOS, using "llvm.x86.sse2.cvtsi642sd" was buggy
__m128d _mm_cvtsi64_sd(__m128d v, long x) pure @safe
{
    v[0] = cast(double)x;
    return v;
}
unittest
{
    __m128d a = _mm_cvtsi64_sd(_mm_set1_pd(0.0f), 42);
    assert(a.array == [42.0, 0]);
}

__m128i _mm_cvtsi64_si128 (long a) pure @safe
{
    long2 r = [0, 0];
    r[0] = a;
    return cast(__m128i)(r);
}

alias _mm_cvtsi64x_sd = _mm_cvtsi64_sd;
alias _mm_cvtsi64x_si128 = _mm_cvtsi64_si128;

double2 _mm_cvtss_sd(double2 v, float4 x) pure @safe
{
    v[0] = x[0];
    return v;
}
unittest
{
    __m128d a = _mm_cvtss_sd(_mm_set1_pd(0.0f), _mm_set1_ps(42.0f));
    assert(a.array == [42.0, 0]);
}

version(LDC)
{
    alias _mm_cvttpd_epi32 = __builtin_ia32_cvttpd2dq; // TODO
    //MMXREG: _mm_cvttpd_pi32
    alias _mm_cvttps_epi32 = __builtin_ia32_cvttps2dq; // TODO
    alias _mm_cvttsd_si32 = __builtin_ia32_cvttsd2si; // TODO
    alias _mm_cvttsd_si64 = __builtin_ia32_cvttsd2si64; // TODO
    alias _mm_cvttsd_si64x = _mm_cvttsd_si64; // TODO
}

__m128d _mm_div_ps(__m128d a, __m128d b)
{
    return a / b;
}

__m128d _mm_div_sd(__m128d a, __m128d b) pure @safe
{
    a[0] /= b[0];
    return a;
}
unittest
{
    __m128d a = [2.0, 4.5];
    a = _mm_div_sd(a, a);
    assert(a.array == [1.0, 4.5]);
}

int _mm_extract_epi16(int imm8)(__m128i a) pure @safe
{
    return extractelement!(short8, imm8)(a);
}

__m128i _mm_insert_epi16(int imm8)(__m128i a, int i) pure @safe
{
    return insertelement!(short8, imm8)(a, i);
}

version(LDC)
{
    alias _mm_lfence = __builtin_ia32_lfence;
}
else
{
    void _mm_lfence() pure @safe
    {
        asm nothrow @nogc pure @safe
        {
            lfence;
        }
    }
}
unittest
{
    _mm_lfence();
}


__m128d _mm_load_pd (const(double) * mem_addr) pure
{
    __m128d* aligned = cast(__m128d*)mem_addr;
    return *aligned;
}

__m128d _mm_load_pd1 (const(double)* mem_addr) pure
{
    double[2] arr = [*mem_addr, *mem_addr];
    return loadUnaligned!(double2)(&arr[0]);
}

__m128d _mm_load_sd (const(double)* mem_addr) pure @safe
{
    double2 r = [0, 0];
    r[0] = *mem_addr;
    return r;
}
unittest
{
    double x = -42;
    __m128d a = _mm_load_sd(&x);
    assert(a.array == [-42.0, 0.0]);
}

__m128i _mm_load_si128 (const(__m128i)* mem_addr) pure @trusted
{
    return *mem_addr;
}

alias _mm_load1_pd = _mm_load_pd1;

__m128d _mm_loadh_pd (__m128d a, const(double)* mem_addr) pure @safe
{
    a[1] = *mem_addr;
    return a;
}

// Note: strange signature since the memory doesn't have to aligned
__m128i _mm_loadl_epi64 (const(__m128i)* mem_addr) pure @safe
{
    auto pLong = cast(const(long)*)mem_addr;
    long2 r = [0, 0];
    r[0] = *pLong;
    return cast(__m128i)(r);
}

__m128d _mm_loadl_pd (__m128d a, const(double)* mem_addr) pure @safe
{
    a[0] = *mem_addr;
    return a;
}

__m128d _mm_loadr_pd (const(double)* mem_addr) pure @trusted
{
    __m128d a = _mm_load_pd(mem_addr);
    return shufflevector!(__m128d, 1, 0)(a, a);
}

__m128d _mm_loadu_pd (const(double)* mem_addr) pure @safe
{
    return loadUnaligned!(double2)(mem_addr);
}

__m128i _mm_loadu_si128 (const(__m128i)* mem_addr) pure @trusted
{
    return loadUnaligned!(__m128i)(cast(int*)mem_addr);
}

__m128i _mm_loadu_si32 (const(void)* mem_addr) pure @trusted
{
    int r = *cast(int*)(mem_addr);
    int4 result = [0, 0, 0, 0];
    result[0] = r;
    return result;
}
unittest
{
    int r = 42;
    __m128i A = _mm_loadu_si32(&r);
    int[4] correct = [42, 0, 0, 0];
    assert(A.array == correct);
}

version(LDC)
{
    alias _mm_madd_epi16 = __builtin_ia32_pmaddwd128;

    alias _mm_maskmoveu_si128 = __builtin_ia32_maskmovdqu;

    pragma(LDC_intrinsic, "llvm.x86.sse2.pmaxs.w")
        short8 __builtin_ia32_pmaxsw128(short8, short8) pure @safe;
    alias _mm_max_epi16 = __builtin_ia32_pmaxsw128;

    pragma(LDC_intrinsic, "llvm.x86.sse2.pmaxu.b")
        byte16 __builtin_ia32_pmaxub128(byte16, byte16) pure @safe;
    alias _mm_max_epu8 = __builtin_ia32_pmaxub128;
}

__m128d _mm_max_pd (__m128d a, __m128d b) pure @safe
{
    // Generates maxpd starting with LDC 1.9
    a[0] = (a[0] > b[0]) ? a[0] : b[0];
    a[1] = (a[1] > b[1]) ? a[1] : b[1];
    return a;
}
unittest
{
    __m128d A = _mm_setr_pd(4.0, 1.0);
    __m128d B = _mm_setr_pd(1.0, 8.0);
    __m128d M = _mm_max_pd(A, B);
    assert(M[0] == 4.0);
    assert(M[1] == 8.0);
}

__m128d _mm_max_sd (__m128d a, __m128d b) pure @safe
{
     __m128d r = a;
    // Generates maxsd starting with LDC 1.3
    r[0] = (a[0] > b[0]) ? a[0] : b[0];
    return r;
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 1.0);
    __m128d B = _mm_setr_pd(4.0, 2.0);
    __m128d M = _mm_max_sd(A, B);
    assert(M[0] == 4.0);
    assert(M[1] == 1.0);
}

version(LDC)
{
    alias _mm_mfence = __builtin_ia32_mfence;
}
else
{
    void _mm_mfence() pure @safe
    {
        asm nothrow @nogc pure @safe
        {
            mfence;
        }
    }
}
unittest
{
    _mm_mfence();
}


version(LDC)
{
    pragma(LDC_intrinsic, "llvm.x86.sse2.pmins.w")
        short8 __builtin_ia32_pminsw128(short8, short8) pure @safe; // TODO
    alias _mm_min_epi16 = __builtin_ia32_pminsw128; // TODO

    pragma(LDC_intrinsic, "llvm.x86.sse2.pminu.b")
        byte16 __builtin_ia32_pminub128(byte16, byte16) pure @safe; // TODO
    alias _mm_min_epu8 = __builtin_ia32_pminub128; // TODO
}

__m128d _mm_min_pd (__m128d a, __m128d b) pure @safe
{
    // Generates minpd starting with LDC 1.9
    a[0] = (a[0] < b[0]) ? a[0] : b[0];
    a[1] = (a[1] < b[1]) ? a[1] : b[1];
    return a;
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 2.0);
    __m128d B = _mm_setr_pd(4.0, 1.0);
    __m128d M = _mm_min_pd(A, B);
    assert(M[0] == 1.0);
    assert(M[1] == 1.0);
}

__m128d _mm_min_sd (__m128d a, __m128d b) pure @safe
{
    // Generates minsd starting with LDC 1.3
    __m128d r = a;
    r[0] = (a[0] < b[0]) ? a[0] : b[0];
    return r;
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 3.0);
    __m128d B = _mm_setr_pd(4.0, 2.0);
    __m128d M = _mm_min_sd(A, B);
    assert(M[0] == 1.0);
    assert(M[1] == 3.0);
}

__m128i _mm_move_epi64 (__m128i a) pure @safe
{
    long2 result = [ 0, 0 ];
    long2 la = cast(long2) a;
    result[0] = la[0];
    return cast(__m128i)(result);
}
unittest
{
    long2 A = [13, 47];
    long2 B = cast(long2) _mm_move_epi64( cast(__m128i)A );
    long[2] correct = [13, 0];
    assert(B.array == correct);
}

__m128d _mm_move_sd (__m128d a, __m128d b) pure @safe
{
    b[1] = a[1];
    return b;
}
unittest
{
    double2 A = [13.0, 47.0];
    double2 B = [34.0, 58.0];
    double2 C = _mm_move_sd(A, B);
    double[2] correct = [34.0, 47.0];
    assert(C.array == correct);
}

version(LDC)
{
    alias _mm_movemask_epi8 = __builtin_ia32_pmovmskb128;
    alias _mm_movemask_pd = __builtin_ia32_movmskpd;
}

// MMXREG: _mm_movepi64_pi64
// MMXREG: __m128i _mm_movpi64_epi64 (__m64 a)

// PERF: unfortunately, __builtin_ia32_pmuludq128 disappeared from LDC
// but seems there in clang
__m128i _mm_mul_epu32(__m128i a, __m128i b) pure @safe
{
    __m128i zero = _mm_setzero_si128();
    long2 la = cast(long2) shufflevector!(int4, 0, 4, 2, 6)(a, zero);
    long2 lb = cast(long2) shufflevector!(int4, 0, 4, 2, 6)(b, zero);
    static if (__VERSION__ >= 2076)
    {
        return cast(__m128i)(la * lb);
    }
    else
    {
        // long2 mul not supported before LDC 1.5
        la[0] *= lb[0];
        la[1] *= lb[1];
        return cast(__m128i)(la);
    }
}
unittest
{
    __m128i A = _mm_set_epi32(0, 0xDEADBEEF, 0, 0xffffffff);
    __m128i B = _mm_set_epi32(0, 0xCAFEBABE, 0, 0xffffffff);
    __m128i C = _mm_mul_epu32(A, B);
    long2 LC = cast(long2)C;
    assert(LC.array[0] == 18446744065119617025uL);
    assert(LC.array[1] == 12723420444339690338uL);
}


__m128d _mm_mul_pd(__m128d a, __m128d b) pure @safe
{
    return a * b;
}
unittest
{
    __m128d a = [-2.0, 1.5];
    a = _mm_mul_pd(a, a);
    assert(a.array == [4.0, 2.25]);
}

__m128d _mm_mul_sd(__m128d a, __m128d b) pure @safe
{
    a[0] *= b[0];
    return a;
}
unittest
{
    __m128d a = [-2.0, 1.5];
    a = _mm_mul_sd(a, a);
    assert(a.array == [4.0, 1.5]);
}


// MMXREG: _mm_mul_su32

version(LDC)
{
    alias _mm_mulhi_epi16 = __builtin_ia32_pmulhw128; // TODO
    alias _mm_mulhi_epu16 = __builtin_ia32_pmulhuw128; // TODO
}

__m128i _mm_mullo_epi16 (__m128i a, __m128i b)
{
    return cast(__m128i)(cast(short8)a * cast(short8)b);
}

__m128d _mm_or_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d)( cast(__m128i)a | cast(__m128i)b );
}

__m128i _mm_or_si128 (__m128i a, __m128i b) pure @safe
{
    return a | b;
}

version(LDC)
{
    alias _mm_packs_epi32 = __builtin_ia32_packssdw128; // TODO
    alias _mm_packs_epi16 = __builtin_ia32_packsswb128; // TODO
}

version(LDC)
{
    alias _mm_packus_epi16 = __builtin_ia32_packuswb128;
}
else
{
    __m128i _mm_packus_epi16 (__m128i a, __m128i b) pure
    {
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        ubyte[16] result = void;
        for (int i = 0; i < 8; ++i)
        {
            short s = sa[i];
            if (s < 0) s = 0;
            if (s > 255) s = 255;
            result[i] = cast(ubyte)s;

            s = sb[i];
            if (s < 0) s = 0;
            if (s > 255) s = 255;
            result[i+8] = cast(ubyte)s;
        }
        return cast(__m128i) loadUnaligned!(byte16)(cast(byte*)result.ptr);
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-10, 400, 0, 256, 255, 2, 1, 0);
    byte16 AA = cast(byte16) _mm_packus_epi16(A, A);
    static immutable ubyte[16] correctResult = [0, 255, 0, 255, 255, 2, 1, 0,
                                                0, 255, 0, 255, 255, 2, 1, 0];
    foreach(i; 0..16)
        assert(AA[i] == cast(byte)(correctResult[i]));
}

version(LDC)
{
    alias _mm_pause = __builtin_ia32_pause;
}
else
{
    void _mm_pause() pure @safe
    {
        asm nothrow @nogc pure @safe
        {
            rep; nop; // F3 90 =  pause
        }
    }
}
unittest
{
    _mm_pause();
}


version(LDC)
{
    alias _mm_sad_epu8 = __builtin_ia32_psadbw128; // TODO
}

__m128i _mm_set_epi16 (short e7, short e6, short e5, short e4, short e3, short e2, short e1, short e0) pure @trusted
{
    short[8] result = [e0, e1, e2, e3, e4, e5, e6, e7];
    return cast(__m128i) loadUnaligned!(short8)(result.ptr);
}
unittest
{
    __m128i A = _mm_set_epi16(7, 6, 5, 4, 3, 2, 1, 0);
    short8 B = cast(short8) A;
    foreach(i; 0..8)
        assert(B.array[i] == i);
}

__m128i _mm_set_epi32 (int e3, int e2, int e1, int e0) pure @trusted
{
    int[4] result = [e0, e1, e2, e3];
    return loadUnaligned!(int4)(result.ptr);
}
unittest
{
    __m128i A = _mm_set_epi32(3, 2, 1, 0);
    foreach(i; 0..4)
        assert(A.array[i] == i);
}

__m128i _mm_set_epi64x (long e1, long e0) pure @trusted
{
    long[2] result = [e0, e1];
    return cast(__m128i)( loadUnaligned!(long2)(result.ptr) );
}
unittest
{
    __m128i A = _mm_set_epi64x(1234, 5678);
    long2 B = cast(long2) A;
    assert(B.array[0] == 5678);
    assert(B.array[1] == 1234);
}

__m128i _mm_set_epi8 (byte e15, byte e14, byte e13, byte e12,
                      byte e11, byte e10, byte e9, byte e8,
                      byte e7, byte e6, byte e5, byte e4,
                      byte e3, byte e2, byte e1, byte e0) pure @trusted
{
    byte[16] result = [e0, e1,  e2,  e3,  e4,  e5,  e6, e7,
                     e8, e9, e10, e11, e12, e13, e14, e15];
    return cast(__m128i)( loadUnaligned!(byte16)(result.ptr) );
}

__m128d _mm_set_pd (double e1, double e0) pure @trusted
{
    double[2] result = [e0, e1];
    return loadUnaligned!(double2)(result.ptr);
}

__m128d _mm_set_pd1 (double a) pure @trusted
{
    double[2] result = [a, a];
    return loadUnaligned!(double2)(result.ptr);
}

__m128d _mm_set_sd (double a) pure @trusted
{
    double[2] result = [a, 0];
    return loadUnaligned!(double2)(result.ptr);
}

__m128i _mm_set1_epi16 (short a) pure @trusted
{
    short[8] result = [a, a, a, a, a, a, a, a];
    return cast(__m128i)( loadUnaligned!(short8)(result.ptr) );
}

__m128i _mm_set1_epi32 (int a) pure @trusted
{
    int[4] result = [a, a, a, a];
    return loadUnaligned!(int4)(result.ptr);
}
unittest
{
    __m128 a = _mm_set1_ps(-1.0f);
    __m128 b = cast(__m128) _mm_set1_epi32(0x7fffffff);
    assert(_mm_and_ps(a, b).array == [1.0f, 1, 1, 1]);
}

__m128i _mm_set1_epi64x (long a) pure @trusted
{
    long[2] result = [a, a];
    return cast(__m128i)( loadUnaligned!(long2)(result.ptr) );
}

__m128i _mm_set1_epi8 (char a) pure @trusted
{
    byte[16] result = [a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a];
    return cast(__m128i)( loadUnaligned!(byte16)(result.ptr) );
}

alias _mm_set1_pd = _mm_set_pd1;

__m128i _mm_setr_epi16 (short e7, short e6, short e5, short e4, short e3, short e2, short e1, short e0) pure @trusted
{
    short[8] result = [e7, e6, e5, e4, e3, e2, e1, e0];
    return cast(__m128i)( loadUnaligned!(short8)(result.ptr) );
}

__m128i _mm_setr_epi32 (int e3, int e2, int e1, int e0) pure @trusted
{
    int[4] result = [e3, e2, e1, e0];
    return cast(__m128i)( loadUnaligned!(int4)(result.ptr) );
}

__m128i _mm_setr_epi64 (long e1, long e0) pure @trusted
{
    long[2] result = [e1, e0];
    return cast(__m128i)( loadUnaligned!(long2)(result.ptr) );
}

__m128i _mm_setr_epi8 (char e15, char e14, char e13, char e12,
                       char e11, char e10, char e9, char e8,
                       char e7, char e6, char e5, char e4,
                       char e3, char e2, char e1, char e0) pure @trusted
{
    byte[16] result = [e15, e14, e13, e12, e11, e10, e9, e8,
                      e7,  e6,  e5,  e4,  e3,  e2, e1, e0];
    return cast(__m128i)( loadUnaligned!(byte16)(result.ptr) );
}

__m128d _mm_setr_pd (double e1, double e0) pure @trusted
{
    double[2] result = [e1, e0];
    return loadUnaligned!(double2)(result.ptr);
}

__m128d _mm_setzero_pd () pure @trusted
{
    double[2] result = [0.0, 0.0];
    return loadUnaligned!(double2)(result.ptr);
}

__m128i _mm_setzero_si128() pure @trusted
{
    int[4] result = [0, 0, 0, 0];
    return cast(__m128i)( loadUnaligned!(int4)(result.ptr) );
}

__m128i _mm_shuffle_epi32(int imm8)(__m128i a) pure @safe
{
    return shufflevector!(int4, (imm8 >> 0) & 3,
                                (imm8 >> 2) & 3,
                                (imm8 >> 4) & 3,
                                (imm8 >> 6) & 3)(a, a);
}
unittest
{
    __m128i A = _mm_setr_epi32(0, 1, 2, 3);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    int4 B = cast(int4) _mm_shuffle_epi32!SHUFFLE(A);
    int[4] expectedB = [ 3, 2, 1, 0 ];
    assert(B.array == expectedB);
}

__m128d _mm_shuffle_pd (int imm8)(__m128d a) pure @safe
{
    return shufflevector!(double2, 0 + ( imm8 & 1 ),
                                   2 + ( (imm8 >> 1) & 1 ))(a, a);
}
unittest
{
    __m128d A = _mm_setr_pd(0.5f, 2.0f);
    enum int SHUFFLE = _MM_SHUFFLE2(1, 1);
    __m128d B = _mm_shuffle_pd!SHUFFLE(A);
    double[2] expectedB = [ 2.0f, 2.0f ];
    assert(B.array == expectedB);
}

__m128i _mm_shufflehi_epi16(int imm8)(__m128i a) pure @safe
{
    return cast(__m128i) shufflevector!(short8, 0, 1, 2, 3,
                                      4 + ( (imm8 >> 0) & 3 ),
                                      4 + ( (imm8 >> 2) & 3 ),
                                      4 + ( (imm8 >> 4) & 3 ),
                                      4 + ( (imm8 >> 6) & 3 ))(cast(short8)a, cast(short8)a);
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, 4, 5, 6, 7);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    short8 C = cast(short8) _mm_shufflehi_epi16!SHUFFLE(A);
    short[8] expectedC = [ 0, 1, 2, 3, 7, 6, 5, 4 ];
    assert(C.array == expectedC);
}

__m128i _mm_shufflelo_epi16(int imm8)(__m128i a) pure @safe
{
    return cast(__m128i) shufflevector!(short8, ( (imm8 >> 0) & 3 ),
                                                ( (imm8 >> 2) & 3 ),
                                                ( (imm8 >> 4) & 3 ),
                                                ( (imm8 >> 6) & 3 ), 4, 5, 6, 7)(cast(short8)a, cast(short8)a);
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, 4, 5, 6, 7);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    short8 B = cast(short8) _mm_shufflelo_epi16!SHUFFLE(A);
    short[8] expectedB = [ 3, 2, 1, 0, 4, 5, 6, 7 ];
    assert(B.array == expectedB);
}

version(LDC)
{
    alias _mm_sll_epi32 = __builtin_ia32_pslld128; // TODO
    alias _mm_sll_epi64 = __builtin_ia32_psllq128; // TODO
    alias _mm_sll_epi16 = __builtin_ia32_psllw128; // TODO
    alias _mm_slli_epi32 = __builtin_ia32_pslldi128; // TODO
    alias _mm_slli_epi64 = __builtin_ia32_psllqi128; // TODO
    alias _mm_slli_epi16 = __builtin_ia32_psllwi128; // TODO
}

__m128i _mm_slli_si128(ubyte imm8)(__m128i op) pure @safe
{
    static if (imm8 & 0xF0)
        return _mm_setzero_si128();
    else
        return shufflevector!(byte16,
        16 - imm8, 17 - imm8, 18 - imm8, 19 - imm8, 20 - imm8, 21 - imm8, 22 - imm8, 23 - imm8,
        24 - imm8, 25 - imm8, 26 - imm8, 27 - imm8, 28 - imm8, 29 - imm8, 30 - imm8, 31 - imm8)
        (_mm_setzero_si128(), op);
}

version(LDC)
{
    // Disappeared with LDC 1.11
    static if (__VERSION__ < 2081)
        alias _mm_sqrt_pd = __builtin_ia32_sqrtpd;
    else
    {
        __m128d _mm_sqrt_pd(__m128d vec) pure @safe
        {
            vec.array[0] = llvm_sqrt(vec.array[0]);
            vec.array[1] = llvm_sqrt(vec.array[1]);
            return vec;
        }
    }
}
else
{
    __m128d _mm_sqrt_pd(__m128d vec) pure @safe
    {
        vec.array[0] = sqrt(vec.array[0]);
        vec.array[1] = sqrt(vec.array[1]);
        return vec;
    }
}


version(LDC)
{
    // Disappeared with LDC 1.11
    static if (__VERSION__ < 2081)
        alias _mm_sqrt_sd = __builtin_ia32_sqrtsd;
    else
    {
        __m128d _mm_sqrt_sd(__m128d vec) pure @safe
        {
            vec.array[0] = llvm_sqrt(vec.array[0]);
            vec.array[1] = vec.array[1];
            return vec;
        }
    }
}
else
{
    __m128d _mm_sqrt_sd(__m128d vec) pure @safe
    {
        vec.array[0] = sqrt(vec.array[0]);
        vec.array[1] = vec.array[1];
        return vec;
    }
}


version(LDC)
{
    alias _mm_sra_epi16 = __builtin_ia32_psraw128;
}
else
{
    __m128i _mm_sra_epi16 (__m128i a, __m128i count) pure @safe
    {
        short8 sa = cast(short8)a;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc[0]);
        short8 r = void;
        foreach(i; 0..8)
            r[i] = cast(short)(sa[i] >> bits);
        return cast(int4)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7);
    short8 B = cast(short8)( _mm_sra_epi16(A, _mm_cvtsi32_si128(1)) );
    short[8] expectedB = [ 0, 0, 1, 1, -2, -3, 3, 3 ];
    assert(B.array == expectedB);
}

version(LDC)
{
    alias _mm_sra_epi32  = __builtin_ia32_psrad128;
}
else
{
    __m128i _mm_sra_epi32 (__m128i a, __m128i count) pure @safe
    {
        int4 r = void;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc[0]);
        foreach(i; 0..4)
            r[i] = (a[i] >> bits);
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(0, 2, 3, -4);
    __m128i B = _mm_sra_epi32(A, _mm_cvtsi32_si128(1));
    int[4] expectedB = [ 0, 1, 1, -2];
    assert(B.array == expectedB);
}


version(LDC)
{
    alias _mm_srai_epi16 = __builtin_ia32_psrawi128;
}
else
{
    __m128i _mm_srai_epi16 (__m128i a, int imm8) pure @safe
    {
        short8 sa = cast(short8)a;
        short8 r = void;
        foreach(i; 0..8)
            r[i] = cast(short)(sa[i] >> imm8);
        return cast(int4)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7);
    short8 B = cast(short8)( _mm_srai_epi16(A, 1) );
    short[8] expectedB = [ 0, 0, 1, 1, -2, -3, 3, 3 ];
    assert(B.array == expectedB);
}

version(LDC)
{
    alias _mm_srai_epi32  = __builtin_ia32_psradi128;
}
else
{
    __m128i _mm_srai_epi32 (__m128i a, int imm8) pure @safe
    {
        int4 r = void;
        foreach(i; 0..4)
            r[i] = (a[i] >> imm8);
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(0, 2, 3, -4);
    __m128i B = _mm_srai_epi32(A, 1);
    int[4] expectedB = [ 0, 1, 1, -2];
    assert(B.array == expectedB);
}

version(LDC)
{
    alias _mm_srl_epi16 = __builtin_ia32_psrlw128;
}
else
{
    __m128i _mm_srl_epi16 (__m128i a, __m128i count) pure @safe
    {
        short8 sa = cast(short8)a;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc[0]);
        short8 r = void;
        foreach(i; 0..8)
            r[i] = cast(short)(cast(ushort)(sa[i]) >> bits);
        return cast(int4)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7);
    short8 B = cast(short8)( _mm_srl_epi16(A, _mm_cvtsi32_si128(1)) );
    short[8] expectedB = [ 0, 0, 1, 1, 0x7FFE, 0x7FFD, 3, 3 ];
    assert(B.array == expectedB);
}

version(LDC)
{
    alias _mm_srl_epi32  = __builtin_ia32_psrld128;
}
else
{
    __m128i _mm_srl_epi32 (__m128i a, __m128i count) pure @safe
    {
        int4 r = void;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc[0]);
        foreach(i; 0..4)
            r[i] = cast(uint)(a[i]) >> bits;
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(0, 2, 3, -4);
    __m128i B = _mm_srl_epi32(A, _mm_cvtsi32_si128(1));
    int[4] expectedB = [ 0, 1, 1, 0x7FFFFFFE];
    assert(B.array == expectedB);
}

version(LDC)
{
    alias _mm_srl_epi64  = __builtin_ia32_psrlq128;
}
else
{
    __m128i _mm_srl_epi64 (__m128i a, __m128i count) pure @safe
    {
        long2 r = void;
        long2 sa = cast(long2)a;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc[0]);
        foreach(i; 0..2)
            r[i] = cast(ulong)(sa[i]) >> bits;
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi64(8, -4);
    long2 B = cast(long2) _mm_srl_epi64(A, _mm_cvtsi32_si128(1));
    long[2] expectedB = [ 4, 0x7FFFFFFFFFFFFFFE];
    assert(B.array == expectedB);
}

version(LDC)
{
    alias _mm_srli_epi16 = __builtin_ia32_psrlwi128;
}
else
{
    __m128i _mm_srli_epi16 (__m128i a, int imm8) pure @safe
    {
        short8 sa = cast(short8)a;
        short8 r = void;
        foreach(i; 0..8)
            r[i] = cast(short)(cast(ushort)(sa[i]) >> imm8);
        return cast(int4)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7);
    short8 B = cast(short8)( _mm_srli_epi16(A, 1) );
    short[8] expectedB = [ 0, 0, 1, 1, 0x7FFE, 0x7FFD, 3, 3 ];
    assert(B.array == expectedB);
}

version(LDC)
{
    alias _mm_srli_epi32  = __builtin_ia32_psrldi128;
}
else
{
    __m128i _mm_srli_epi32 (__m128i a, int imm8) pure @safe
    {
        int4 r = void;
        foreach(i; 0..4)
            r[i] = cast(uint)(a[i]) >> imm8;
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(0, 2, 3, -4);
    __m128i B = _mm_srli_epi32(A, 1);
    int[4] expectedB = [ 0, 1, 1, 0x7FFFFFFE];
    assert(B.array == expectedB);
}

version(LDC)
{
    alias _mm_srli_epi64 = __builtin_ia32_psrlqi128; // TODO
}

version(LDC)
{
    alias _mm_srli_epi64  = __builtin_ia32_psrlqi128;
}
else
{
    __m128i _mm_srli_epi64 (__m128i a, int imm8) pure @safe
    {
        long2 r = void;
        long2 sa = cast(long2)a;
        foreach(i; 0..2)
            r[i] = cast(ulong)(sa[i]) >> imm8;
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi64(8, -4);
    long2 B = cast(long2) _mm_srli_epi64(A, 1);
    long[2] expectedB = [ 4, 0x7FFFFFFFFFFFFFFE];
    assert(B.array == expectedB);
}

__m128i _mm_srli_si128(ubyte imm8)(__m128i op) pure @safe
{
    static if (imm8 & 0xF0)
        return _mm_setzero_si128();
    else
        return cast(__m128i) shufflevector!(byte16,
                                            imm8+0, imm8+1, imm8+2, imm8+3, imm8+4, imm8+5, imm8+6, imm8+7,
                                            imm8+8, imm8+9, imm8+10, imm8+11, imm8+12, imm8+13, imm8+14, imm8+15)
                                           (cast(byte16) op, cast(byte16)_mm_setzero_si128());
}

// Note: this is a bonus intrinsic
__m128 _mm_srli_si128(ubyte imm8)(__m128 op) @safe
{
    return cast(__m128)_mm_srli_si128!imm8(cast(__m128i)op);
}
unittest
{
    // test that cast works at all
    __m128 A = cast(__m128) _mm_set1_epi32(0x3F800000);
    assert(A.array == [1.0f, 1.0f, 1.0f, 1.0f]);

    // test _mm_srli_si128 for __m128i
    assert(_mm_srli_si128!4(_mm_set_epi32(4, 3, 2, 1)).array == [2, 3, 4, 0]);
    assert(_mm_srli_si128!8(_mm_set_ps(4.0f, 3.0f, 2.0f, 1.0f)).array == [3.0f, 4.0f, 0, 0]);
}

__m128d _mm_srli_si128(ubyte imm8)(__m128d op) pure @safe
{
    return cast(__m128d) _mm_srli_si128!imm8(cast(__m128i)op);
}

void _mm_store_pd (double* mem_addr, __m128d a) pure
{
    __m128d* aligned = cast(__m128d*)mem_addr;
    *aligned = a;
}

void _mm_store_pd1 (double* mem_addr, __m128d a) pure
{
    __m128d* aligned = cast(__m128d*)mem_addr;
    *aligned = shufflevector!(double2, 0, 0)(a, a);
}

void _mm_store_sd (double* mem_addr, __m128d a) pure @safe
{
    *mem_addr = extractelement!(double2, 0)(a);
}

void _mm_store_si128 (__m128i* mem_addr, __m128i a) pure @safe
{
    *mem_addr = a;
}

alias _mm_store1_pd = _mm_store_pd1;

void _mm_storeh_pd (double* mem_addr, __m128d a) pure @safe
{
    *mem_addr = extractelement!(double2, 1)(a);
}

void _mm_storel_epi64 (__m128i* mem_addr, __m128i a) pure @safe
{
    long* dest = cast(long*)mem_addr;
    *dest = extractelement!(long2, 0)(cast(long2)a);
}

void _mm_storel_pd (double* mem_addr, __m128d a) pure @safe
{
    *mem_addr = extractelement!(double2, 0)(a);
}

void _mm_storer_pd (double* mem_addr, __m128d a) pure
{
    __m128d* aligned = cast(__m128d*)mem_addr;
    *aligned = shufflevector!(double2, 1, 0)(a, a);
}

void _mm_storeu_pd (double* mem_addr, __m128d a) pure @safe
{
    storeUnaligned!double2(a, mem_addr);
}

void _mm_storeu_si128 (__m128i* mem_addr, __m128i a) pure @safe
{
    storeUnaligned!__m128i(a, cast(int*)mem_addr);
}

/// Store 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements) 
/// from a into memory using a non-temporal memory hint. mem_addr must be aligned on a 16-byte 
/// boundary or a general-protection exception may be generated.
void _mm_stream_pd (double* mem_addr, __m128d a)
{
    // BUG see `_mm_stream_ps` for an explanation why we don't implement non-temporal moves
    __m128d* dest = cast(__m128d*)mem_addr;
    *dest = a;
}

/// Store 128-bits of integer data from a into memory using a non-temporal memory hint. 
/// mem_addr must be aligned on a 16-byte boundary or a general-protection exception 
/// may be generated.
void _mm_stream_si128 (__m128i* mem_addr, __m128i a)
{
    // BUG see `_mm_stream_ps` for an explanation why we don't implement non-temporal moves
    __m128i* dest = cast(__m128i*)mem_addr;
    *dest = a;
}

/// Store 32-bit integer a into memory using a non-temporal hint to minimize cache 
/// pollution. If the cache line containing address mem_addr is already in the cache, 
/// the cache will be updated.
void _mm_stream_si32 (int* mem_addr, int a)
{
    // BUG see `_mm_stream_ps` for an explanation why we don't implement non-temporal moves
    *mem_addr = a;
}

/// Store 64-bit integer a into memory using a non-temporal hint to minimize 
/// cache pollution. If the cache line containing address mem_addr is already 
/// in the cache, the cache will be updated.
void _mm_stream_si64 (long* mem_addr, long a)
{
    // BUG See `_mm_stream_ps` for an explanation why we don't implement non-temporal moves
    *mem_addr = a;
}

__m128i _mm_sub_epi16(__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(short8)a - cast(short8)b);
}

__m128i _mm_sub_epi32(__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(int4)a - cast(int4)b);
}

__m128i _mm_sub_epi64(__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(long2)a - cast(long2)b);
}

__m128i _mm_sub_epi8(__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(byte16)a - cast(byte16)b);
}

__m128d _mm_sub_pd(__m128d a, __m128d b) pure @safe
{
    return a - b;
}

__m128d _mm_sub_sd(__m128d a, __m128d b) pure @safe
{
    a[0] -= b[0];
    return a;
}
unittest
{
    __m128d a = [1.5, -2.0];
    a = _mm_sub_sd(a, a);
    assert(a.array == [0.0, -2.0]);
}


// MMXREG: _mm_sub_si64

version(LDC)
{
    alias _mm_subs_epi16 = __builtin_ia32_psubsw128;
    alias _mm_subs_epi8 = __builtin_ia32_psubsb128;
    alias _mm_subs_epu16 = __builtin_ia32_psubusw128;
    alias _mm_subs_epu8 = __builtin_ia32_psubusb128;
}

// Note: the only difference between these intrinsics is the signalling 
//       behaviour of quiet NaNs. This is incorrect but the case where
//       you would want to differentiate between qNaN and sNaN and then 
//       treat them differently on purpose seems extremely rare.
alias _mm_ucomieq_sd = _mm_comieq_sd;
alias _mm_ucomige_sd = _mm_comige_sd;
alias _mm_ucomigt_sd = _mm_comigt_sd;
alias _mm_ucomile_sd = _mm_comile_sd;
alias _mm_ucomilt_sd = _mm_comilt_sd;
alias _mm_ucomineq_sd = _mm_comineq_sd;

__m128d _mm_undefined_pd() pure @safe
{
    __m128d result = void;
    return result;
}
__m128i _mm_undefined_si128() pure @safe
{
    __m128i result = void;
    return result;
}

__m128i _mm_unpackhi_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) shufflevector!(short8, 4, 12, 5, 13, 6, 14, 7, 15)
                                       (cast(short8)a, cast(short8)b);
}

__m128i _mm_unpackhi_epi32 (__m128i a, __m128i b) pure @safe
{
    return shufflevector!(int4, 2, 6, 3, 7)(cast(int4)a, cast(int4)b);
}

__m128i _mm_unpackhi_epi64 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) shufflevector!(long2, 1, 3)(cast(long2)a, cast(long2)b);
}

__m128i _mm_unpackhi_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)shufflevector!(byte16, 8,  24,  9, 25, 10, 26, 11, 27,
                                               12, 28, 13, 29, 14, 30, 15, 31)
                                               (cast(byte16)a, cast(byte16)b);
}

__m128d _mm_unpackhi_pd (__m128d a, __m128d b) pure @safe
{
    return shufflevector!(__m128d, 1, 3)(a, b);
}

__m128i _mm_unpacklo_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) shufflevector!(short8, 0, 8, 1, 9, 2, 10, 3, 11)
                                       (cast(short8)a, cast(short8)b);
}

__m128i _mm_unpacklo_epi32 (__m128i a, __m128i b) pure @safe
{
    return shufflevector!(int4, 0, 4, 1, 6)
                         (cast(int4)a, cast(int4)b);
}

__m128i _mm_unpacklo_epi64 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) shufflevector!(long2, 0, 2)
                                       (cast(long2)a, cast(long2)b);
}

__m128i _mm_unpacklo_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) shufflevector!(byte16, 0, 16, 1, 17, 2, 18, 3, 19,
                                                4, 20, 5, 21, 6, 22, 7, 23)
                                       (cast(byte16)a, cast(byte16)b);
}

__m128d _mm_unpacklo_pd (__m128d a, __m128d b) pure @safe
{
    return shufflevector!(__m128d, 0, 2)(a, b);
}

__m128d _mm_xor_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d)(cast(__m128i)a ^ cast(__m128i)b);
}

__m128i _mm_xor_si128 (__m128i a, __m128i b) pure @safe
{
    return a ^ b;
}

unittest
{
    // distance between two points in 4D
    float distance(float[4] a, float[4] b) nothrow @nogc
    {
        __m128 va = _mm_loadu_ps(a.ptr);
        __m128 vb = _mm_loadu_ps(b.ptr);
        __m128 diffSquared = _mm_sub_ps(va, vb);
        diffSquared = _mm_mul_ps(diffSquared, diffSquared);
        __m128 sum = _mm_add_ps(diffSquared, _mm_srli_si128!8(diffSquared));
        sum = _mm_add_ps(sum, _mm_srli_si128!4(sum));
        return _mm_cvtss_f32(_mm_sqrt_ss(sum));
    }
    assert(distance([0, 2, 0, 0], [0, 0, 0, 0]) == 2);
}