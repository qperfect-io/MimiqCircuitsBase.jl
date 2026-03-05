#!/usr/bin/env julia
using ArgParse
using ProgressMeter
using DataFrames
using Dates
using MimiqCircuitsBase
import MimiqCircuitsBase: unwrapvalue, matrix

include(joinpath(@__DIR__, "..", "src", "SolovayKitaevAnalysis.jl"))
using .SolovayKitaevAnalysis

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--name"
        help = "Base name for outputs (CSV, plots, metadata)"
        default = "sk_convergence"
        "--output-dir", "-o"
        help = "Directory for output files"
        default = "."
        "--max-depth", "-d"
        help = "Maximum recursion depth for the experiment"
        arg_type = Int
        default = 4
        "--samples", "-s"
        help = "Number of samples per depth per generator"
        arg_type = Int
        default = 20
        "--net-depth"
        help = "Solovay-Kitaev ε-net max depth (configures the algorithm)"
        arg_type = Int
        default = MimiqCircuitsBase.SK_NET_MAX_DEPTH
        "--net-points"
        help = "Solovay-Kitaev ε-net max points (configures the algorithm)"
        arg_type = Int
        default = MimiqCircuitsBase.SK_NET_MAX_POINTS
        "--net-min-dist"
        help = "Solovay-Kitaev ε-net minimum distance (density control)"
        arg_type = Float64
        default = MimiqCircuitsBase.SK_NET_MIN_DIST
        "--basis"
        help = "Basis set to use: clifford+t, clifford+sqrtt, 'rx(1.0)+rz(1.0)', 'clifford+t+rx(π/8)'"
        default = "clifford+t"
    end

    return parse_args(s)
end

using JSON

function run_experiment(args)
    base_name = args["name"]
    output_dir = args["output-dir"]
    max_depth = args["max-depth"]
    samples = args["samples"]

    # Paths
    csv_path = joinpath(output_dir, "$(base_name).csv")
    meta_path = joinpath(output_dir, "$(base_name)_meta.json")
    part_path = csv_path * ".part"

    if !isdir(output_dir)
        mkpath(output_dir)
    end

    # Save Metadata
    meta_dict = Dict(
        "experiment" => base_name,
        "timestamp" => string(now()),
        "args" => args
    )
    open(meta_path, "w") do io
        JSON.print(io, meta_dict, 4)
    end

    # Init Data
    df = init_data(csv_path)

    # Generators
    generators = [
        ("Random Unitary", () -> GateU(rand() * 2π, rand() * 2π, rand() * 2π)),
        ("Random RZ", () -> GateRZ(rand() * 2π)),
        ("Random RX", () -> GateRX(rand() * 2π)),
        ("Random RY", () -> GateRY(rand() * 2π))
    ]

    # Config
    net_max_depth = args["net-depth"]
    net_max_points = args["net-points"]
    net_min_dist = args["net-min-dist"]

    basis_name = args["basis"]
    basis_gates = get_basis_by_name(basis_name)
    println("Config: Basis=$basis_name, Depth=$net_max_depth, Points=$net_max_points, MinDist=$net_min_dist")

    total_ops = length(generators) * (max_depth + 1) * samples
    p_total = Progress(total_ops; desc=" [Overall] ", color=:green, showspeed=true)

    for (name, gen) in generators
        for d in 0:max_depth
            rule = SolovayKitaevRewrite(d; simplify=true, basis_gates=basis_gates, net_max_depth=net_max_depth, net_max_points=net_max_points, net_min_dist=net_min_dist)
            p_inner = Progress(samples; desc=" [Current: $name | D=$d] ", color=:cyan)

            for s in 1:samples
                gate = gen()
                original = unwrapvalue.(matrix(gate))

                t1 = @elapsed decompose_step(gate; rule=rule)
                t2 = @elapsed decompose_step(gate; rule=rule)
                t = min(t1, t2)

                decomposed = decompose_step(gate; rule=rule)
                mat = matrix_from_circuit(decomposed, 1)
                err = best_phase_distance(original, mat)
                gates = length(decomposed)

                append_result!(csv_path, df, name, basis_name, net_max_depth, net_max_points, net_min_dist, d, s, err, t, gates)
                next!(p_inner)
                next!(p_total)
            end
            generate_plots(df, output_dir; filename_prefix=base_name)
        end
    end

    mv(part_path, csv_path; force=true)
    generate_plots(df, output_dir; filename_prefix=base_name)
    println("Done: $csv_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    args = parse_commandline()
    run_experiment(args)
end
