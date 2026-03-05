#!/usr/bin/env julia

#
# Copyright © 2025-2026 QPerfect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#=
Benchmark History Tracker
=========================

Run benchmarks across multiple git commits to track performance over time.

Usage:
    julia --project=benchmark benchmark/track_history.jl [OPTIONS] [COMMITS...]

Options:
    --last N        Benchmark last N commits (default: 10)
    --quick         Quick mode
    --filter PAT    Filter benchmarks
    --output FILE   Output CSV file (default: history.csv)

Examples:
    # Last 10 commits
    julia --project=benchmark benchmark/track_history.jl

    # Specific commits
    julia --project=benchmark benchmark/track_history.jl abc123 def456 main

    # Last 20 commits, quick mode
    julia --project=benchmark benchmark/track_history.jl --last 20 --quick
=#

using Pkg
Pkg.activate(joinpath(@__DIR__))

using Dates
using Printf
using BenchmarkTools

# Parse arguments
const ARGS_CONFIG = Dict{String,Any}(
    "last" => 10,
    "quick" => false,
    "filter" => nothing,
    "output" => "history.csv",
    "commits" => String[],
)

function parse_args()
    i = 1
    while i <= length(ARGS)
        arg = ARGS[i]
        if arg == "--last"
            i += 1
            ARGS_CONFIG["last"] = parse(Int, ARGS[i])
        elseif arg == "--quick"
            ARGS_CONFIG["quick"] = true
        elseif arg == "--filter"
            i += 1
            ARGS_CONFIG["filter"] = Regex(ARGS[i], "i")
        elseif arg == "--output"
            i += 1
            ARGS_CONFIG["output"] = ARGS[i]
        elseif !startswith(arg, "-")
            push!(ARGS_CONFIG["commits"], arg)
        end
        i += 1
    end
end

parse_args()

# ============================================================================ #
# Git Utilities
# ============================================================================ #

function git_commits(n::Int)
    output = read(`git log --format="%H %s" -n $n`, String)
    commits = []
    for line in split(strip(output), "\n")
        parts = split(line, " ", limit=2)
        push!(commits, (hash=parts[1], message=length(parts) > 1 ? parts[2] : ""))
    end
    return commits
end

function git_checkout(ref::String)
    run(`git checkout -q $ref`)
end

function git_current_branch()
    strip(read(`git rev-parse --abbrev-ref HEAD`, String))
end

function git_stash()
    run(`git stash -q`)
end

function git_stash_pop()
    try
        run(`git stash pop -q`)
    catch
        # No stash to pop
    end
end

# ============================================================================ #
# Benchmark Utilities
# ============================================================================ #

function collect_names(suite::BenchmarkGroup, prefix::String="")
    names = String[]
    for (k, v) in suite
        name = isempty(prefix) ? string(k) : "$prefix/$k"
        if v isa BenchmarkGroup
            append!(names, collect_names(v, name))
        else
            push!(names, name)
        end
    end
    return sort(names)
end

function get_result(results::BenchmarkGroup, path::String)
    parts = split(path, "/")
    current = results
    for part in parts
        if haskey(current, part)
            current = current[part]
        else
            return nothing
        end
    end
    return current
end

function run_benchmarks_for_commit(commit_hash::String)
    # Configure
    if ARGS_CONFIG["quick"]
        BenchmarkTools.DEFAULT_PARAMETERS.samples = 5
        BenchmarkTools.DEFAULT_PARAMETERS.seconds = 0.5
    else
        BenchmarkTools.DEFAULT_PARAMETERS.samples = 30
        BenchmarkTools.DEFAULT_PARAMETERS.seconds = 2.0
    end

    # Load and run
    try
        include(joinpath(@__DIR__, "benchmarks.jl"))

        suite = if ARGS_CONFIG["filter"] !== nothing
            filter(kv -> occursin(ARGS_CONFIG["filter"], string(kv[1])), SUITE)
        else
            SUITE
        end

        results = run(suite; verbose=false)
        return results
    catch e
        @warn "Failed to run benchmarks for $commit_hash: $e"
        return nothing
    end
end

# ============================================================================ #
# Main
# ============================================================================ #

function main()
    original_branch = git_current_branch()

    # Determine commits to benchmark
    commits = if !isempty(ARGS_CONFIG["commits"])
        [(hash=c, message="") for c in ARGS_CONFIG["commits"]]
    else
        git_commits(ARGS_CONFIG["last"])
    end

    println("Tracking benchmarks across $(length(commits)) commits")
    println("="^60)

    # Stash any changes
    git_stash()

    all_results = []

    try
        for (i, commit) in enumerate(commits)
            short_hash = commit.hash[1:8]
            println("\n[$i/$(length(commits))] $short_hash: $(commit.message[1:min(50, length(commit.message))])")

            # Checkout commit
            try
                git_checkout(commit.hash)
            catch
                @warn "Could not checkout $short_hash, skipping"
                continue
            end

            # Run benchmarks
            results = run_benchmarks_for_commit(commit.hash)

            if results !== nothing
                push!(all_results, (
                    hash=commit.hash,
                    message=commit.message,
                    results=results,
                    timestamp=now()
                ))
                println("  ✓ Completed")
            else
                println("  ✗ Failed")
            end
        end
    finally
        # Return to original branch
        git_checkout(original_branch)
        git_stash_pop()
    end

    # Generate CSV output
    if !isempty(all_results)
        output_file = joinpath(@__DIR__, "results", ARGS_CONFIG["output"])
        mkpath(dirname(output_file))

        # Get all benchmark names from first result
        benchmark_names = collect_names(all_results[1].results)

        open(output_file, "w") do io
            # Header
            println(io, "commit,timestamp,", join(benchmark_names, ","))

            # Data rows
            for r in all_results
                values = String[]
                push!(values, r.hash[1:8])
                push!(values, string(r.timestamp))

                for name in benchmark_names
                    result = get_result(r.results, name)
                    if result !== nothing
                        med = median(result)
                        push!(values, @sprintf("%.2f", med.time / 1e6))  # ms
                    else
                        push!(values, "")
                    end
                end

                println(io, join(values, ","))
            end
        end

        println("\n" * "="^60)
        println("Results saved to: $output_file")
        println("\nSummary:")
        println("  Commits benchmarked: $(length(all_results))")
        println("  Benchmarks tracked:  $(length(benchmark_names))")
    else
        println("\nNo results to save.")
    end
end

main()
