#!/usr/bin/env julia
using Dates

function run_cmd(cmd_str)
    println("\n> $cmd_str")
    run(`bash -c $cmd_str`)
end

function main()
    timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
    base_dir = "results/report_$timestamp"
    mkpath(base_dir)
    println("--- Solovay-Kitaev Full Report ---")
    println("Out: $base_dir")

    # Low-density Basis Comparison
    i = 0
    tot = 10

    let
        netpoints = 1000
        netdist = 0.1
        netdepth = 10
        maxorder = 6
        samples = 50

        testname = "Basis Comparison up to order $maxorder with Net: points $netpoints, min dist $netdist, depth $netdepth"
        testdir = joinpath(base_dir, "basis_comparison_maxorder$(maxorder)_samples$(samples)_maxpoints$(netpoints)_mindist$(netdist)_maxdepth$(netdepth)")
        resultsprefix = "sk_basis_std"

        i += 1

        println("\n[$i/$tot] $testname...")
        run_cmd("julia --project=. bin/run_basis_comparison.jl --max-depth $maxorder --samples $samples --output-dir $testdir --name $resultsprefix --net-points $netpoints --net-min-dist $netdist --net-depth $netdepth")
        run_cmd("julia --project=. bin/generate_table.jl --csv $(resultsprefix).csv --output-dir $testdir")
    end

    let
        netpoints = 1000
        netdist = 0.05
        netdepth = 10
        maxorder = 6
        samples = 50

        testname = "Basis Comparison up to order $maxorder with Net: points $netpoints, min dist $netdist, depth $netdepth"
        testdir = joinpath(base_dir, "basis_comparison_maxorder$(maxorder)_samples$(samples)_maxpoints$(netpoints)_mindist$(netdist)_maxdepth$(netdepth)")
        resultsprefix = "sk_basis_std"

        i += 1

        println("\n[$i/$tot] $testname...")
        run_cmd("julia --project=. bin/run_basis_comparison.jl --max-depth $maxorder --samples $samples --output-dir $testdir --name $resultsprefix --net-points $netpoints --net-min-dist $netdist --net-depth $netdepth")
        run_cmd("julia --project=. bin/generate_table.jl --csv $(resultsprefix).csv --output-dir $testdir")
    end

    let
        netpoints = 1000
        netdist = 0.01
        netdepth = 10
        maxorder = 6
        samples = 50

        testname = "Basis Comparison up to order $maxorder with Net: points $netpoints, min dist $netdist, depth $netdepth"
        testdir = joinpath(base_dir, "basis_comparison_maxorder$(maxorder)_samples$(samples)_maxpoints$(netpoints)_mindist$(netdist)_maxdepth$(netdepth)")
        resultsprefix = "sk_basis_std"

        i += 1

        println("\n[$i/$tot] $testname...")
        run_cmd("julia --project=. bin/run_basis_comparison.jl --max-depth $maxorder --samples $samples --output-dir $testdir --name $resultsprefix --net-points $netpoints --net-min-dist $netdist --net-depth $netdepth")
        run_cmd("julia --project=. bin/generate_table.jl --csv $(resultsprefix).csv --output-dir $testdir")
    end

    let
        netpoints = 1000
        netdist = 0.01
        netdepth = 5
        maxorder = 6
        samples = 50

        testname = "Basis Comparison up to order $maxorder with Net: points $netpoints, min dist $netdist, depth $netdepth"
        testdir = joinpath(base_dir, "basis_comparison_maxorder$(maxorder)_samples$(samples)_maxpoints$(netpoints)_mindist$(netdist)_maxdepth$(netdepth)")
        resultsprefix = "sk_basis_std"

        i += 1

        println("\n[$i/$tot] $testname...")
        run_cmd("julia --project=. bin/run_basis_comparison.jl --max-depth $maxorder --samples $samples --output-dir $testdir --name $resultsprefix --net-points $netpoints --net-min-dist $netdist --net-depth $netdepth")
        run_cmd("julia --project=. bin/generate_table.jl --csv $(resultsprefix).csv --output-dir $testdir")
    end

    let
        netpoints = 1000
        netdist = 0.01
        netdepth = 15
        maxorder = 6
        samples = 50

        testname = "Basis Comparison up to order $maxorder with Net: points $netpoints, min dist $netdist, depth $netdepth"
        testdir = joinpath(base_dir, "basis_comparison_maxorder$(maxorder)_samples$(samples)_maxpoints$(netpoints)_mindist$(netdist)_maxdepth$(netdepth)")
        resultsprefix = "sk_basis_std"

        i += 1

        println("\n[$i/$tot] $testname...")
        run_cmd("julia --project=. bin/run_basis_comparison.jl --max-depth $maxorder --samples $samples --output-dir $testdir --name $resultsprefix --net-points $netpoints --net-min-dist $netdist --net-depth $netdepth")
        run_cmd("julia --project=. bin/generate_table.jl --csv $(resultsprefix).csv --output-dir $testdir")
    end

    let
        netpoints = 10_000
        netdist = 0.01
        netdepth = 15
        maxorder = 6
        samples = 50

        testname = "Basis Comparison up to order $maxorder with Net: points $netpoints, min dist $netdist, depth $netdepth"
        testdir = joinpath(base_dir, "basis_comparison_maxorder$(maxorder)_samples$(samples)_maxpoints$(netpoints)_mindist$(netdist)_maxdepth$(netdepth)")
        resultsprefix = "sk_basis_std"

        i += 1

        println("\n[$i/$tot] $testname...")
        run_cmd("julia --project=. bin/run_basis_comparison.jl --max-depth $maxorder --samples $samples --output-dir $testdir --name $resultsprefix --net-points $netpoints --net-min-dist $netdist --net-depth $netdepth")
        run_cmd("julia --project=. bin/generate_table.jl --csv $(resultsprefix).csv --output-dir $testdir")
    end

    let
        netpoints = 100_000
        netdist = 0.01
        netdepth = 15
        maxorder = 6
        samples = 50

        testname = "Basis Comparison up to order $maxorder with Net: points $netpoints, min dist $netdist, depth $netdepth"
        testdir = joinpath(base_dir, "basis_comparison_maxorder$(maxorder)_samples$(samples)_maxpoints$(netpoints)_mindist$(netdist)_maxdepth$(netdepth)")
        resultsprefix = "sk_basis_std"

        i += 1

        println("\n[$i/$tot] $testname...")
        run_cmd("julia --project=. bin/run_basis_comparison.jl --max-depth $maxorder --samples $samples --output-dir $testdir --name $resultsprefix --net-points $netpoints --net-min-dist $netdist --net-depth $netdepth")
        run_cmd("julia --project=. bin/generate_table.jl --csv $(resultsprefix).csv --output-dir $testdir")
    end

    let
        netpoints = 100_000
        netdist = 0.02
        netdepth = 15
        maxorder = 6
        samples = 50

        testname = "Basis Comparison up to order $maxorder with Net: points $netpoints, min dist $netdist, depth $netdepth"
        testdir = joinpath(base_dir, "basis_comparison_maxorder$(maxorder)_samples$(samples)_maxpoints$(netpoints)_mindist$(netdist)_maxdepth$(netdepth)")
        resultsprefix = "sk_basis_std"

        i += 1

        println("\n[$i/$tot] $testname...")
        run_cmd("julia --project=. bin/run_basis_comparison.jl --max-depth $maxorder --samples $samples --output-dir $testdir --name $resultsprefix --net-points $netpoints --net-min-dist $netdist --net-depth $netdepth")
        run_cmd("julia --project=. bin/generate_table.jl --csv $(resultsprefix).csv --output-dir $testdir")
    end

    let
        netpoints = 100_000
        netdist = 0.05
        netdepth = 15
        maxorder = 6
        samples = 50

        testname = "Basis Comparison up to order $maxorder with Net: points $netpoints, min dist $netdist, depth $netdepth"
        testdir = joinpath(base_dir, "basis_comparison_maxorder$(maxorder)_samples$(samples)_maxpoints$(netpoints)_mindist$(netdist)_maxdepth$(netdepth)")
        resultsprefix = "sk_basis_std"

        i += 1

        println("\n[$i/$tot] $testname...")
        run_cmd("julia --project=. bin/run_basis_comparison.jl --max-depth $maxorder --samples $samples --output-dir $testdir --name $resultsprefix --net-points $netpoints --net-min-dist $netdist --net-depth $netdepth")
        run_cmd("julia --project=. bin/generate_table.jl --csv $(resultsprefix).csv --output-dir $testdir")
    end

    let
        netpoints = 100_000
        netdist = 0.01
        netdepth = 15
        maxorder = 6
        samples = 100

        testname = "Detailed Clifford+T convergence up to order $maxorder with Net: points $netpoints, min dist $netdist, depth $netdepth"
        testdir = joinpath(base_dir, "convergence_clifford_t_maxorder$(maxorder)_samples$(samples)_maxpoints$(netpoints)_mindist$(netdist)_maxdepth$(netdepth)")
        resultsprefix = "sk_conv_ct"

        i += 1

        println("\n[$i/$tot] $testname...")
        run_cmd("julia --project=. bin/run_convergence.jl --max-depth $maxorder --samples $samples --basis clifford+t --output-dir $testdir --name $resultsprefix --net-points $netpoints --net-min-dist $netdist --net-depth $netdepth")
    end

    println("\n--- Done ---")
    println("See: $base_dir")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
