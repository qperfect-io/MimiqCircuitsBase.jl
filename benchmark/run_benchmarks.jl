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

# MimiqCircuitsBase Benchmark Runner
# ==================================
#
# Usage:
#     julia --project=benchmark benchmark/run_benchmarks.jl [COMMAND] [OPTIONS]
#
# Commands:
#     run       Execute benchmarks
#     list      List available benchmarks
#     show      Display saved results
#     compare   Compare results
#     tune      Tune parameters
#     profile   Profile benchmarks
#
# Run 'julia benchmark/run_benchmarks.jl [COMMAND] --help' for details.

using Pkg
Pkg.activate(joinpath(@__DIR__))

# Ensure dependencies
try
    using BenchmarkTools
catch
    Pkg.instantiate()
    using BenchmarkTools
end

using Dates
using Printf
using ArgParse
using Profile

# Lazy load the benchmark suite to minimize startup time for non-benchmark commands.

# ============================================================================ #
# Utilities
# ============================================================================ #

function log(msg; level=:info, verbose=false)
    if verbose || level == :always
        timestamp = Dates.format(now(), "HH:MM:SS")
        prefix = level == :info ? "ℹ" : level == :warn ? "⚠" : "✓"
        println(stderr, "[$timestamp] $prefix $msg")
    end
end

function load_suite()
    log("Loading benchmark suite...", level=:always)
    include(joinpath(@__DIR__, "benchmarks.jl"))
    return Base.invokelatest(() -> SUITE)
end

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

function filter_suite(suite::BenchmarkGroup, include::Union{Nothing,Regex}, exclude::Union{Nothing,Regex}, prefix::String="")
    filtered = BenchmarkGroup()
    for (k, v) in suite
        # Construct full name for filtering
        name = isempty(prefix) ? string(k) : "$prefix/$k"

        # Check exclusion on the full name
        if exclude !== nothing && occursin(exclude, name)
            continue
        end

        if v isa BenchmarkGroup
            sub = filter_suite(v, include, exclude, name)
            if !isempty(sub)
                filtered[k] = sub
            end
        else
            if include === nothing || occursin(include, name)
                filtered[k] = v
            end
        end
    end
    return filtered
end

function format_time(t_ns)
    if t_ns < 1_000
        @sprintf("%.1f ns", t_ns)
    elseif t_ns < 1_000_000
        @sprintf("%.2f μs", t_ns / 1_000)
    elseif t_ns < 1_000_000_000
        @sprintf("%.2f ms", t_ns / 1_000_000)
    else
        @sprintf("%.2f s", t_ns / 1_000_000_000)
    end
end

function format_memory(bytes)
    if bytes < 1024
        @sprintf("%d B", bytes)
    elseif bytes < 1024^2
        @sprintf("%.2f KiB", bytes / 1024)
    elseif bytes < 1024^3
        @sprintf("%.2f MiB", bytes / 1024^2)
    else
        @sprintf("%.2f GiB", bytes / 1024^3)
    end
end

function truncate_name(name, max_len=40)
    if length(name) > max_len
        return name[1:max_len-3] * "..."
    end
    return rpad(name, max_len)
end

# ============================================================================ #
# Output Formatters
# ============================================================================ #

function print_results_tree(group::BenchmarkGroup, indent::Int=0, io::IO=stdout)
    prefix = "  "^indent

    for (k, v) in sort(collect(group), by=x -> string(x[1]))
        if v isa BenchmarkGroup
            println(io, truncate_name("$(prefix)📁 $k"))
            print_results_tree(v, indent + 1, io)
        else
            med = median(v)
            time_str = format_time(med.time)
            mem_str = format_memory(med.memory)
            allocs = med.allocs

            name_str = prefix * string(k)
            fmt_name = truncate_name(name_str, 40)

            # Format: Name (40) | Time (12) | Allocs (15) | Memory (10)
            println(io, @sprintf("%s %12s  %8d allocs  %10s",
                fmt_name, time_str, allocs, mem_str))
        end
    end
end

function print_results_markdown(group::BenchmarkGroup, level::Int=1, io::IO=stdout)
    for (k, v) in sort(collect(group), by=x -> string(x[1]))
        if v isa BenchmarkGroup
            println(io, "#"^(level + 1) * " $k\n")
            if level == 1
                println(io, "| Benchmark | Time | Allocations | Memory |")
                println(io, "|-----------|------|-------------|--------|")
            end
            print_results_markdown(v, level + 1, io)
            println(io)
        else
            med = median(v)
            time_str = format_time(med.time)
            mem_str = format_memory(med.memory)
            println(io, "| $k | $time_str | $(med.allocs) | $mem_str |")
        end
    end
end

function print_comparison(judgment::BenchmarkGroup, current::BenchmarkGroup, indent::Int=0)
    prefix = "  "^indent

    improved = 0
    regressed = 0
    unchanged = 0

    keys_list = sort(collect(keys(judgment)), by=string)

    for k in keys_list
        v = judgment[k]

        if !haskey(current, k)
            continue
        end
        curr_v = current[k]

        name_str = prefix * string(k)

        if v isa BenchmarkGroup && curr_v isa BenchmarkGroup
            println(truncate_name("$(prefix)📁 $k"))
            counts = print_comparison(v, curr_v, indent + 1)
            improved += counts[1]
            regressed += counts[2]
            unchanged += counts[3]
        elseif v isa BenchmarkTools.TrialJudgement
            time_str = format_time(curr_v.time)

            ratio = v.ratio
            time_ratio = ratio.time
            mem_ratio = ratio.memory

            if time_ratio < 0.90
                status = "🟢 FASTER "
                improved += 1
            elseif time_ratio > 1.10
                status = "🔴 SLOWER "
                regressed += 1
            else
                status = "⚪ same   "
                unchanged += 1
            end

            fmt_name = truncate_name(name_str, 40)

            println(@sprintf("%s %12s %s %.2fx time  %.2fx mem",
                fmt_name, time_str, status, time_ratio, mem_ratio))
        end
    end

    return (improved, regressed, unchanged)
end

# ============================================================================ #
# IO Logic
# ============================================================================ #

function save_results(results::BenchmarkGroup, filename::String;
    use_common_dir::Bool=false,
    force_json::Bool=false,
    force_markdown::Bool=false,
    verbose::Bool=false)

    # Determine directory
    if use_common_dir
        dir = joinpath(@__DIR__, "results")
        mkpath(dir)
    else
        dir = dirname(abspath(filename))
        if isempty(dir)
            dir = pwd()
        end
        if !isdir(dir)
            mkpath(dir)
        end
    end

    # Determine base filename and extension
    base_name = basename(filename)
    if isempty(base_name)
        # Should not happen if filename not empty
        base_name = "benchmark_results"
    end

    ext = lowercase(splitext(base_name)[2])


    # Infer format from extension unless explicitly forced
    # .md/.markdown -> Markdown
    # .json (default) -> JSON
    is_markdown = force_markdown
    is_json = force_json

    if !is_markdown && !is_json
        if ext == ".md" || ext == ".markdown"
            is_markdown = true
        else
            is_json = true
        end
    end

    final_path = joinpath(dir, base_name)

    log("Saving results to: $final_path", level=:always, verbose=verbose)

    open(final_path, "w") do io
        if is_markdown
            println(io, "# MimiqCircuitsBase.jl Benchmark Results\n")
            println(io, "Generated: $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"))\n")
            print_results_markdown(results, 1, io)
        else
            BenchmarkTools.save(io, results)
        end
    end
end

# ============================================================================ #
# Command Handlers
# ============================================================================ #

function cmd_run(args)
    s = ArgParseSettings(description="Run benchmarks")
    @add_arg_table! s begin
        "filter"
        help = "Regex filter for benchmark names"
        arg_type = String
        required = false
        "--quick"
        help = "Reduced samples for quick feedback"
        action = :store_true
        "--thorough"
        help = "More samples for accurate results"
        action = :store_true
        "--save"
        help = "Save results to name (defaults to timestamp)"
        nargs = '?'
        constant = ""
        "--common"
        help = "Save to common results folder (benchmark/results)"
        action = :store_true
        "--exclude"
        help = "Exclude benchmarks matching regex"
        arg_type = String
        "--json"
        help = "Output as JSON (stdout by default, or ensures saved format is JSON)"
        action = :store_true
        "--markdown"
        help = "Output as Markdown (stdout by default, or ensures saved format is Markdown)"
        action = :store_true
        "--verbose", "-v"
        help = "Verbose output"
        action = :store_true
    end
    parsed_args = parse_args(args, s)
    verbose = parsed_args["verbose"]

    suite = load_suite()

    filter_rex = nothing
    if parsed_args["filter"] !== nothing
        filter_rex = Regex(parsed_args["filter"], "i")
    end

    exclude_rex = nothing
    if parsed_args["exclude"] !== nothing
        exclude_rex = Regex(parsed_args["exclude"], "i")
    end

    suite = filter_suite(suite, filter_rex, exclude_rex)

    n_benchmarks = length(collect_names(suite))
    if n_benchmarks == 0
        println(stderr, "No benchmarks match the given filters!")
        exit(1)
    end

    log("Selected $n_benchmarks benchmarks", level=:always, verbose=verbose)

    # Configure parameters
    if parsed_args["quick"]
        log("Quick mode enabled", level=:always, verbose=verbose)
        BenchmarkTools.DEFAULT_PARAMETERS.samples = 10
        BenchmarkTools.DEFAULT_PARAMETERS.evals = 1
        BenchmarkTools.DEFAULT_PARAMETERS.seconds = 0.5
    elseif parsed_args["thorough"]
        log("Thorough mode enabled", level=:always, verbose=verbose)
        BenchmarkTools.DEFAULT_PARAMETERS.samples = 200
        BenchmarkTools.DEFAULT_PARAMETERS.seconds = 10.0
    else
        BenchmarkTools.DEFAULT_PARAMETERS.samples = 50
        BenchmarkTools.DEFAULT_PARAMETERS.seconds = 3.0
    end

    log("Running benchmarks...", level=:always, verbose=verbose)
    start = now()
    results = run(suite; verbose=verbose)
    elapsed = now() - start
    log("Completed in $elapsed", level=:always, verbose=verbose)


    if parsed_args["json"]
        io = IOBuffer()
        BenchmarkTools.save(io, results)
        println(String(take!(io)))
    elseif parsed_args["markdown"]
        print_results_markdown(results)
    else
        println("\n" * "="^85)
        println("BENCHMARK RESULTS")
        println("="^85 * "\n")
        println(@sprintf("%-40s %12s  %15s  %10s", "Benchmark", "Time", "Allocations", "Memory"))
        println("-"^85)
        print_results_tree(results)
    end

    # Save
    if parsed_args["save"] !== nothing
        name = isempty(parsed_args["save"]) ?
               "benchmark_$(Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")).json" :
               parsed_args["save"]

        save_results(results, name;
            use_common_dir=parsed_args["common"],
            force_json=parsed_args["json"],
            force_markdown=parsed_args["markdown"],
            verbose=verbose
        )
    end
end

function cmd_list(args)
    s = ArgParseSettings(description="List benchmarks")
    @add_arg_table! s begin
        "filter"
        help = "Regex filter for benchmark names"
        arg_type = String
        required = false
        "--exclude"
        help = "Exclude benchmarks matching regex"
        arg_type = String
        "--verbose", "-v"
        help = "Verbose output"
        action = :store_true
    end
    parsed_args = parse_args(args, s)

    suite = load_suite()

    filter_rex = nothing
    if parsed_args["filter"] !== nothing
        filter_rex = Regex(parsed_args["filter"], "i")
    end

    exclude_rex = nothing
    if parsed_args["exclude"] !== nothing
        exclude_rex = Regex(parsed_args["exclude"], "i")
    end

    suite = filter_suite(suite, filter_rex, exclude_rex)
    names = collect_names(suite)

    println("\nAvailable benchmarks:")
    println("="^70)
    for name in names
        println("  $name")
    end
    println("\nTotal: $(length(names)) benchmarks")
end

function cmd_show(args)
    s = ArgParseSettings(description="Show saved benchmark results")
    @add_arg_table! s begin
        "file"
        help = "Path to results JSON file"
        required = true
        "--json"
        help = "Output raw JSON"
        action = :store_true
        "--markdown"
        help = "Output as Markdown"
        action = :store_true
        "--save"
        help = "Save/Convert results to name"
        nargs = '?'
        constant = ""
        "--common"
        help = "Save to common results folder"
        action = :store_true
    end
    parsed_args = parse_args(args, s)

    file = parsed_args["file"]
    if !isfile(file)
        # Try looking in results dir
        rel_file = joinpath(@__DIR__, "results", file)
        if isfile(rel_file)
            file = rel_file
        elseif isfile(rel_file * ".json")
            file = rel_file * ".json"
        elseif isfile(file * ".json")
            file = file * ".json"
        else
            println(stderr, "File not found: $file")
            exit(1)
        end
    end

    results = BenchmarkTools.load(file)[1]

    if parsed_args["json"]
        io = IOBuffer()
        BenchmarkTools.save(io, results)
        println(String(take!(io)))
    elseif parsed_args["markdown"]
        print_results_markdown(results)
    else
        println("\n" * "="^85)
        println("RESULTS: $(basename(file))")
        println("="^85 * "\n")
        println(@sprintf("%-40s %12s  %15s  %10s", "Benchmark", "Time", "Allocations", "Memory"))
        println("-"^85)
        print_results_tree(results)
    end

    if parsed_args["save"] !== nothing
        name = isempty(parsed_args["save"]) ?
               "benchmark_converted_$(Dates.format(now(), "yyyy-mm-dd_HH-MM-SS"))" :
               parsed_args["save"]

        save_results(results, name;
            use_common_dir=parsed_args["common"],
            force_json=parsed_args["json"],
            force_markdown=parsed_args["markdown"],
            verbose=false
        )
    end
end

function cmd_compare(args)
    s = ArgParseSettings(description="Compare benchmark results")
    @add_arg_table! s begin
        "target"
        help = "Newer results file (or 'baseline' to compare current checkout vs baseline if integrated? No, assumes file)"
        required = true
        "baseline"
        help = "Baseline results file"
        required = false
    end
    parsed_args = parse_args(args, s)

    # Helper to resolve file paths
    function resolve_path(p)
        if isfile(p)
            return p
        end
        if isfile(p * ".json")
            return p * ".json"
        end

        results_dir = joinpath(@__DIR__, "results")
        p2 = joinpath(results_dir, p)
        if isfile(p2)
            return p2
        end
        if isfile(p2 * ".json")
            return p2 * ".json"
        end

        return nothing
    end

    target_file = resolve_path(parsed_args["target"])
    if target_file === nothing
        println(stderr, "Target file not found: $(parsed_args["target"])")
        exit(1)
    end

    baseline_path_arg = parsed_args["baseline"]
    if baseline_path_arg === nothing
        # Default to checking if 'baseline.json' exists in results
        default_baseline = joinpath(@__DIR__, "results", "baseline.json")
        if isfile(default_baseline)
            baseline_path_arg = default_baseline
        else
            println(stderr, "No baseline file specified and 'benchmark/results/baseline.json' not found.")
            exit(1)
        end
    end

    baseline_file = resolve_path(baseline_path_arg)
    if baseline_file === nothing
        println(stderr, "Baseline file not found: $(parsed_args["baseline"])")
        exit(1)
    end

    log("Comparing $(basename(target_file)) vs $(basename(baseline_file))", level=:always)

    target_res = BenchmarkTools.load(target_file)[1]
    baseline_res = BenchmarkTools.load(baseline_file)[1]

    target_med = median(target_res)
    baseline_med = median(baseline_res)

    judgment = judge(target_med, baseline_med)

    println("\n" * "="^85)
    println("COMPARISON")
    println("Target:   $(basename(target_file))")
    println("Baseline: $(basename(baseline_file))")
    println("="^85 * "\n")
    println(@sprintf("%-40s %12s %-10s %s", "Benchmark", "Time (New)", "Status", "Comparison"))
    println("-"^85)

    counts = print_comparison(judgment, target_med)

    println("\n" * "-"^70)
    println("Summary:")
    println("  🟢 Improved:  $(counts[1])")
    println("  🔴 Regressed: $(counts[2])")
    println("  ⚪ Unchanged: $(counts[3])")
end

function cmd_tune(args)
    s = ArgParseSettings(description="Tune benchmarks (create parameters file)")
    @add_arg_table! s begin
        "filter"
        help = "Regex filter"
        required = false
        "--exclude"
        help = "Exclude regex"
        "--verbose", "-v"
        action = :store_true
    end
    parsed_args = parse_args(args, s)
    verbose = parsed_args["verbose"]

    suite = load_suite()

    if parsed_args["filter"] !== nothing
        suite = filter_suite(suite, Regex(parsed_args["filter"], "i"), nothing)
    end

    log("Tuning benchmarks...", level=:always, verbose=verbose)
    tune!(suite; verbose=verbose)

    # Where to save tuned parameters? Usually 'params.json'
    params_file = joinpath(@__DIR__, "params.json")
    BenchmarkTools.save(params_file, params(suite))
    log("Tuned parameters saved to $params_file", level=:always, verbose=verbose)
end

function cmd_profile(args)
    s = ArgParseSettings(description="Profile benchmarks")
    @add_arg_table! s begin
        "filter"
        help = "Regex filter (must match a single benchmark group or item preferably)"
        required = true # Force filter to avoid profiling everything
        "--verbose", "-v"
        action = :store_true
    end
    parsed_args = parse_args(args, s)

    suite = load_suite()
    filter_rex = Regex(parsed_args["filter"], "i")
    suite = filter_suite(suite, filter_rex, nothing)

    names = collect_names(suite)
    if isempty(names)
        println(stderr, "No benchmarks found matching: $(parsed_args["filter"])")
        exit(1)
    end

    log("Profiling $(length(names)) benchmarks...", level=:always)

    # We can't really "profile" a suite easily in one go with PPROF or standard Profile
    # unless we run them sequentially.
    # For now, let's just run `@profile` on the execution of the filtered suite.

    # Warmup
    run(suite, samples=1, evals=1, seconds=1)

    Profile.clear()
    @profile run(suite, samples=1, evals=1, seconds=5)

    # Dump profile to file? Or just print top?
    # Simple output
    Profile.print(format=:flat, sortedby=:count, mincount=10)

    println("\nTip: Use 'using PProf; PProf.pprof()' in REPL for detail.")
end

# ============================================================================ #
# Main Dispatch
# ============================================================================ #

function main()
    if isempty(ARGS)
        println(stderr, "Usage: julia benchmark/run_benchmarks.jl [COMMAND] [OPTIONS]")
        println(stderr, "\nCommands:")
        println(stderr, "  run      Execute benchmarks")
        println(stderr, "  list     List available benchmarks")
        println(stderr, "  show     Display saved results")
        println(stderr, "  compare  Compare results")
        println(stderr, "  tune     Tune parameters")
        println(stderr, "  profile  Profile benchmarks")
        exit(1)
    end

    command = ARGS[1]
    command_args = ARGS[2:end]

    if command == "run"
        cmd_run(command_args)
    elseif command == "list"
        cmd_list(command_args)
    elseif command == "show"
        cmd_show(command_args)
    elseif command == "compare"
        cmd_compare(command_args)
    elseif command == "tune"
        cmd_tune(command_args)
    elseif command == "profile"
        cmd_profile(command_args)
    elseif command == "--help" || command == "-h"
        println("Usage: julia benchmark/run_benchmarks.jl [COMMAND]")
        println("\nSee individual commands for their options.")
    else
        println(stderr, "Unknown command: $command")
        exit(1)
    end
end

main()
