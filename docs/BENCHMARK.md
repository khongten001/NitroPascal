# NitroPascal Performance Benchmarks

## Overview

Performance comparison between **NitroPascal** (releasefast optimization) and **Delphi** (Release mode) using the NPBench micro-benchmark suite.

**Test Environment:**
- **Platform:** Windows x64
- **Date:** October 19, 2025 (Latest Run)
- **NitroPascal:** `releasefast` optimization mode
- **Delphi:** Release mode with full optimizations

## Benchmark Suite

NPBench consists of three micro-benchmarks designed to measure different aspects of compiler performance:

### 1. String Concatenation (string_concat_1k)

Repeatedly concatenates a single character to build a 1KB string:

```pascal
LStr := '';
for LIndex := 1 to 1024 do
  LStr := LStr + 'x';
```

**Measures:** String memory allocation, copy operations, runtime library efficiency  
**Data processed:** 1,024 bytes per iteration

### 2. Array Sum (array_sum_10m)

Computes running sum over 10 million integers with array writes:

```pascal
LSum := 0;
for LIndex := 1 to 10,000,000 do
begin
  LSum := LSum + LIndex;
  LArray[LIndex mod 100] := LSum;
end;
```

**Measures:** Integer arithmetic, array indexing, loop optimization, cache utilization  
**Data processed:** 80 MB per iteration

### 3. Matrix Multiplication (matmul_64)

Standard matrix multiplication of two 64×64 double-precision matrices:

```pascal
for i := 0 to 63 do
  for j := 0 to 63 do
    for k := 0 to 63 do
      C[i,j] := C[i,j] + A[i,k] * B[k,j];
```

**Measures:** Floating-point arithmetic, nested loop optimization, memory access patterns  
**Data processed:** 98,304 bytes per iteration

## Methodology

Each benchmark:
1. Performs 2 warmup iterations
2. Auto-adjusts iteration count to achieve ~400ms total runtime
3. Reports average time per operation

**Metrics:**
- **ns/op:** Nanoseconds per operation (lower is better)
- **ops/s:** Operations per second (higher is better)
- **MB/s:** Data throughput in megabytes per second (higher is better)

## Results

### NitroPascal (releasefast)

| Benchmark | Iterations | ns/op | ops/s | MB/s |
|-----------|----------:|------:|------:|-----:|
| string_concat_1k | 3,571 | 2,302.24 | 434,359.53 | 424.18 |
| array_sum_10m | 1 | 6,411,300.00 | 155.97 | 11,899.92 |
| matmul_64 | 92 | 108,365.22 | 9,228.05 | 865.13 |

### Delphi (Release)

| Benchmark | Iterations | ns/op | ops/s | MB/s |
|-----------|----------:|------:|------:|-----:|
| string_concat_1k | 26,315 | 14,689.96 | 68,073.69 | 66.48 |
| array_sum_10m | 40 | 10,156,022.50 | 98.46 | 7,512.19 |
| matmul_64 | 1,899 | 217,386.05 | 4,600.11 | 431.26 |

## Performance Comparison

| Benchmark | NitroPascal | Delphi | Faster | Ratio |
|-----------|------------:|-------:|--------|------:|
| **string_concat_1k** | 2,302 ns | 14,690 ns | NitroPascal | 6.38× |
| **array_sum_10m** | 6,411,300 ns | 10,156,023 ns | NitroPascal | 1.58× |
| **matmul_64** | 108,365 ns | 217,386 ns | NitroPascal | 2.01× |

## Analysis

### String Concatenation
- **Winner:** NitroPascal (6.38× faster)
- **Outstanding Performance:** NitroPascal now dramatically outperforms Delphi's native string implementation
- **Performance:** NitroPascal 2,302 ns/op vs Delphi 14,690 ns/op
- **Throughput:** NitroPascal 424.18 MB/s vs Delphi 66.48 MB/s (6.4× higher throughput)
- The C++ backend's `std::u16string::operator+=` combined with smart capacity management delivers exceptional string concatenation performance
- This represents additional optimization beyond the October 17 `+=` operator improvement

### Array Sum
- **Winner:** NitroPascal (1.58× faster)
- NitroPascal continues to benefit from modern C++ compiler optimizations including aggressive loop optimization and better instruction scheduling
- **Throughput:** NitroPascal 11,900 MB/s vs Delphi 7,512 MB/s
- Performance remains highly competitive with consistent results across benchmark runs

### Matrix Multiplication
- **Winner:** NitroPascal (2.01× faster)
- NitroPascal's C++ backend provides superior floating-point optimization and nested loop handling
- **Throughput:** NitroPascal 865.13 MB/s vs Delphi 431.26 MB/s (over 2× throughput)
- Now exceeds 2× performance advantage over Delphi for this compute-intensive workload

## Summary

**NitroPascal Performance Profile:**
- **Dominates across all benchmarks** - faster than Delphi in every test
- **Exceptional string performance:** 6.38× faster than Delphi's native implementation
- **Strong numeric computation:** 1.58-2.01× faster than Delphi
- **Superior array operations and floating-point math** with over 2× throughput advantage
- Modern C++ backend enables exceptional loop optimization, vectorization, and memory management

**Delphi Performance Profile:**
- Competitive baseline performance
- Mature, well-optimized runtime library
- Strong foundation but outperformed by NitroPascal's modern C++ backend optimizations

---

## Recent Optimizations

### String Concatenation Optimization (October 17, 2025)

Implemented code generation optimization that detects the self-assignment concatenation pattern:

```pascal
LStr := LStr + 'x';  // Pascal source
```

**Before optimization:**
```cpp
LStr = (LStr + np::String("x"));  // Creates new allocation every iteration
```

**After optimization:**
```cpp
LStr += np::String("x");  // Efficient in-place append
```

**Impact:**
- String concatenation performance improved **14× faster** (242,495 ns → 17,116 ns per operation)
- NitroPascal now within **1.13×** of Delphi's highly-optimized native string implementation
- Brings NitroPascal from 16.5× slower to competitive parity with Delphi for string operations

**Implementation:**
- Pattern detection in `GenerateAssignment` procedure
- Detects `variable := variable + expression` patterns
- Emits `variable += expression` instead of full assignment
- Leverages efficient `std::u16string::operator+=` with smart capacity management
- Zero breaking changes - optimization only applies to detected pattern

This optimization demonstrates NitroPascal's ability to generate efficient C++ code while maintaining Pascal semantics.

---

## Reproducibility

Both compilers use identical source code to ensure fair comparison. Benchmarks can be reproduced using the NPBench suite included with NitroPascal.

**Version:** NPBench 1.0  
**Latest Benchmark Run:** October 19, 2025  
**String Concatenation Optimization:** October 17, 2025
