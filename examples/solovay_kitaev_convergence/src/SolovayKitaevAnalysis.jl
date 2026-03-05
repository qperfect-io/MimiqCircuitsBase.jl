
module SolovayKitaevAnalysis

using Dates
using DataFrames
using CSV
using CairoMakie
using Statistics
using MimiqCircuitsBase
using LinearAlgebra

export init_data, append_result!, generate_plots, best_phase_distance, matrix_from_circuit, get_basis_by_name

# --- Basis Definitions ---

"""
    get_basis_by_name(name::String) -> Vector{AbstractGate}

Return the set of basis gates corresponding to the given name.
Supported:
- "clifford+t"
- "clifford+sqrtt" (adds RZ(π/8))
- "rx(1.0)+rz(1.0)"
- "clifford+t+rx(π/8)"
"""
function get_basis_by_name(name::String)
    n = lowercase(replace(name, " " => ""))

    if n == "clifford+t"
        return collect(MimiqCircuitsBase.SK_BASIC_GATES)
    elseif n == "clifford+sqrtt" || n == "clifford+sqrtt(π/8)"
        base = collect(MimiqCircuitsBase.SK_BASIC_GATES)
        return vcat(base, [GateRZ(π / 8), GateRZ(-π / 8)])
    elseif n == "rx(1.0)+rz(1.0)" || n == "rx_rz"
        return [GateRX(1.0), GateRX(-1.0), GateRZ(1.0), GateRZ(-1.0)]
    elseif n == "clifford+t+rx(π/8)" || n == "clifford+rx"
        base = collect(MimiqCircuitsBase.SK_BASIC_GATES)
        return vcat(base, [GateRX(π / 8), GateRX(-π / 8)])
    else
        error("Unknown basis set: $name")
    end
end

# --- Utilities ---

function matrix_from_circuit(circuit, num_qubits)
    isempty(circuit) && return Matrix{ComplexF64}(I, 2^num_qubits, 2^num_qubits)
    # Assuming single qubit for SK
    m = Matrix{ComplexF64}(I, 2, 2)
    for gate in circuit
        m = matrix(gate) * m
    end
    return m
end

"""
    best_phase_distance(U, V) -> Float64

Compute distance between U and V modulo global phase using singular values.
"""
function best_phase_distance(U::AbstractMatrix, V::AbstractMatrix)
    # Operator norm distance minimizing global phase difference
    # ||U - e^{iφ}V||
    M = U' * V
    t = tr(U' * V)
    return sqrt(max(0.0, 2.0 - abs(t)))
end

# --- Data Management ---

function init_data(csv_path)
    # Manage .part file for robust logging
    part_path = csv_path * ".part"
    if isfile(part_path)
        @warn "Resuming from partial file: $part_path"
        return CSV.read(part_path, DataFrame)
    end

    if isfile(csv_path)
        return CSV.read(csv_path, DataFrame)
    end

    df = DataFrame(
        timestamp=DateTime[],
        generator=String[],     # Grouping Key (Basis or Generator Name)
        basis_name=String[],    # Basis Set Name
        net_depth=Int[],        # Config: Net Depth
        net_points=Int[],       # Config: Net Max Points
        net_min_dist=Float64[], # Config: Net Min Distance
        depth=Int[],            # Algorithm Depth
        sample=Int[],           # Sample Index
        error=Float64[],        # Approximation Error
        time=Float64[],         # Decomp Time (s)
        gates=Int[]             # Resulting Gate Count
    )

    CSV.write(part_path, df)
    return df
end

function append_result!(csv_path, df, name, basis, net_depth, net_points, net_min_dist, depth, sample, err, t, gates)
    row = (now(), name, basis, net_depth, net_points, net_min_dist, depth, sample, err, t, gates)
    push!(df, row)
    CSV.write(csv_path * ".part", DataFrame([row]), append=true)
end

# --- Plotting Helpers ---

function setup_axis(fig, row, ylabel, title; log=false)
    Axis(fig[row, 1],
        xlabel="Recursion Depth",
        ylabel=ylabel,
        title=title,
        yscale=log ? log10 : identity,
        xgridstyle=:dash,
        ygridstyle=:dash,
        xminorticksvisible=true
    )
end

"""
    generate_plots(df::DataFrame, output_dir::String; filename_prefix="sk_summary")

Generate summary and detailed plots from the experiment data.
"""
function generate_plots(df::DataFrame, output_dir::String; filename_prefix::String="sk_summary")
    if isempty(df)
        @warn "No data to plot."
        return
    end

    if !isdir(output_dir)
        mkpath(output_dir)
    end

    gdf = groupby(df, [:generator, :depth])

    # Aggregation
    stats_df = combine(gdf,
        :error => mean => :err_mean,
        :error => (x -> quantile(x, 0.05)) => :err_p5,
        :error => (x -> quantile(x, 0.95)) => :err_p95,
        :time => mean => :time_mean,
        :time => (x -> quantile(x, 0.05)) => :time_p5,
        :time => (x -> quantile(x, 0.95)) => :time_p95,
        :gates => mean => :gates_mean,
        :gates => (x -> quantile(x, 0.05)) => :gates_p5,
        :gates => (x -> quantile(x, 0.95)) => :gates_p95
    )

    generators = unique(stats_df.generator)
    colors = [:blue, :red, :green, :orange, :purple, :cyan]

    # --- 1. Summary Plot ---
    # Layout:
    # [      Error (span 2)      ]
    # [ Runtime ]  [ Gate Count  ]

    f_sum = Figure(size=(1920, 1080), fontsize=20)

    # Metadata Header
    meta_str = "Unknown Config"
    if !isempty(df)
        r = first(df)
        if hasproperty(r, :net_depth)
            meta_str = "Depth=$(r.net_depth), Points=$(r.net_points), MinDist=$(r.net_min_dist)"
        end
    end

    Label(f_sum[0, :], "Solovay-Kitaev Convergence Analysis\n$meta_str",
        fontsize=24, font=:bold, color=:black)

    # Grid Layout
    ax_err = Axis(f_sum[1, 1:2],
        xlabel="Recursion Depth", ylabel="Error (Op Norm)",
        title="Average Approximation Error", yscale=log10,
        xgridstyle=:dash, ygridstyle=:dash, xminorticksvisible=true)

    ax_time = Axis(f_sum[2, 1],
        xlabel="Recursion Depth", ylabel="Runtime (s)",
        title="Average Runtime",
        xgridstyle=:dash, ygridstyle=:dash, xminorticksvisible=true)

    ax_gate = Axis(f_sum[2, 2],
        xlabel="Recursion Depth", ylabel="Gate Count",
        title="Average Gate Count", yscale=log10,
        xgridstyle=:dash, ygridstyle=:dash, xminorticksvisible=true)

    # Calculate global min/max for error scaling
    min_err = minimum(stats_df.err_mean)
    max_err = maximum(stats_df.err_mean)

    for (i, gen) in enumerate(generators)
        sub = filter(row -> row.generator == gen, stats_df)
        sort!(sub, :depth)

        c = colors[mod1(i, length(colors))]

        lines!(ax_err, sub.depth, sub.err_mean, label=gen, color=c, linewidth=3)
        scatter!(ax_err, sub.depth, sub.err_mean, color=c, markersize=10)

        lines!(ax_time, sub.depth, sub.time_mean, label=gen, color=c, linewidth=3)
        scatter!(ax_time, sub.depth, sub.time_mean, color=c, markersize=10)

        lines!(ax_gate, sub.depth, sub.gates_mean, label=gen, color=c, linewidth=3)
        scatter!(ax_gate, sub.depth, sub.gates_mean, color=c, markersize=10)
    end

    # Smart Scaling
    ylims!(ax_err, min_err * 0.1, max_err * 2.0)
    axislegend(ax_err, position=:rt)
    save(joinpath(output_dir, "$(filename_prefix).pdf"), f_sum)

    # --- 2. Detail Plots ---
    for gen in generators
        sub = filter(row -> row.generator == gen, stats_df)
        sort!(sub, :depth)
        isempty(sub) && continue

        safe_name = replace(gen, r"[^a-zA-Z0-9_]" => "_")
        f_det = Figure(size=(1920, 1080), fontsize=20)

        Label(f_det[0, :], "Solovay-Kitaev Detail: $gen\n$meta_str",
            fontsize=24, font=:bold, color=:black)

        metrics = [(:err, "Error", true, :err_mean), (:time, "Time", false, :time_mean), (:gates, "Gates", true, :gates_mean)]

        for (i, (slug, ylab, islog, col)) in enumerate(metrics)
            col_idx = i
            ax = Axis(f_det[1, col_idx], xlabel="Depth", ylabel=ylab, title=ylab, yscale=islog ? log10 : identity)

            vals = sub[!, col]
            lines!(ax, sub.depth, vals, linewidth=3)
            scatter!(ax, sub.depth, vals)

            # Bands
            p5_col = Symbol("$(slug)_p5")
            p95_col = Symbol("$(slug)_p95")
            band!(ax, sub.depth, sub[!, p5_col], sub[!, p95_col], color=(:blue, 0.2))
        end

        save(joinpath(output_dir, "$(filename_prefix)_detail_$(safe_name).pdf"), f_det)
    end
end

end # module
