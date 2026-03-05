#!/usr/bin/env julia
using ArgParse
using CSV
using DataFrames

# Include the analysis module
include(joinpath(@__DIR__, "..", "src", "SolovayKitaevAnalysis.jl"))
using .SolovayKitaevAnalysis

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--csv", "-c"
        help = "Input CSV filename"
        default = "sk_convergence_results.csv"
        "--output-dir", "-o"
        help = "Directory for output files"
        default = "."
    end

    return parse_args(s)
end

function run_plotting(args)
    output_dir = args["output-dir"]
    csv_name = args["csv"]
    csv_path = joinpath(output_dir, csv_name)

    if !isfile(csv_path)
        # Check standard location if not found in output-dir
        if isfile(csv_name)
            csv_path = csv_name
        else
            error("CSV file not found: $csv_path or $csv_name")
        end
    end

    println("Loading data from $csv_path...")
    df = CSV.read(csv_path, DataFrame)

    println("Regenerating plots in $output_dir...")
    generate_plots(df, output_dir; filename_prefix="sk_convergence")
    println("Done. Check plots in $output_dir")
end

if abspath(PROGRAM_FILE) == @__FILE__
    args = parse_commandline()
    run_plotting(args)
end
