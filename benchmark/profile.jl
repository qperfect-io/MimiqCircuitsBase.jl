#!/usr/bin/env julia
#=
Performance Profiling Utility
=============================

Use this after benchmarking to understand WHY something is slow.

Usage:
    julia --project=benchmark benchmark/profile.jl [PATTERN]

Examples:
    julia --project=benchmark benchmark/profile.jl matrix
    julia --project=benchmark benchmark/profile.jl "decomposition.*ccx"
=#

using Pkg
Pkg.activate(joinpath(@__DIR__))
Pkg.instantiate()

using Profile
using BenchmarkTools
using Printf

# Load benchmarks
include(joinpath(@__DIR__, "benchmarks.jl"))

# ============================================================================ #
# Utilities
# ============================================================================ #

function collect_benchmarks(suite::BenchmarkGroup, prefix::String="")
    benchmarks = Pair{String,Any}[]
    for (k, v) in suite
        name = isempty(prefix) ? string(k) : "$prefix/$k"
        if v isa BenchmarkGroup
            append!(benchmarks, collect_benchmarks(v, name))
        else
            push!(benchmarks, name => v)
        end
    end
    return benchmarks
end

function find_benchmark(suite::BenchmarkGroup, pattern::Regex)
    all_benchmarks = collect_benchmarks(suite)
    matches = filter(p -> occursin(pattern, p.first), all_benchmarks)
    return matches
end

# ============================================================================ #
# Profiling
# ============================================================================ #

function profile_benchmark(name::String, benchmark)
    println("="^70)
    println("Profiling: $name")
    println("="^70)

    # First, run the benchmark normally
    println("\n📊 Benchmark results:")
    result = run(benchmark)
    display(result)

    # Extract the actual function to profile
    # BenchmarkTools wraps things, so we need to get at the core
    println("\n🔍 Profile (flat):")

    # Warm up
    for _ in 1:3
        benchmark.samplefunc(benchmark.params)
    end

    # Profile
    Profile.clear()
    @profile for _ in 1:100
        benchmark.samplefunc(benchmark.params)
    end

    Profile.print(noisefloor=2.0, mincount=3)

    println("\n📈 Profile (tree):")
    Profile.print(format=:tree, noisefloor=2.0, mincount=3)

    # Allocation profile
    println("\n💾 Allocation report:")
    @time for _ in 1:100
        benchmark.samplefunc(benchmark.params)
    end
end

# ============================================================================ #
# Main
# ============================================================================ #

function main()
    pattern = if length(ARGS) > 0
        Regex(ARGS[1], "i")
    else
        r".*"
    end

    matches = find_benchmark(SUITE, pattern)

    if isempty(matches)
        println("No benchmarks match pattern: $(ARGS[1])")
        println("\nAvailable benchmarks:")
        for (name, _) in collect_benchmarks(SUITE)
            println("  $name")
        end
        return
    end

    if length(matches) > 5
        println("Found $(length(matches)) matching benchmarks:")
        for (name, _) in matches[1:min(10, length(matches))]
            println("  $name")
        end
        if length(matches) > 10
            println("  ... and $(length(matches) - 10) more")
        end
        println("\nSpecify a more specific pattern to profile.")
        return
    end

    for (name, benchmark) in matches
        profile_benchmark(name, benchmark)
        println()
    end
end

main()
