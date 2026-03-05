#!/usr/bin/env julia
using ArgParse
using CSV
using DataFrames
using Statistics
using Printf

# Basic scaling fit: log10(error) = a * depth + b
function linear_fit_slope(x, y)
    if length(x) < 2
        return 0.0
    end
    x_mean = mean(x)
    y_mean = mean(y)
    num = sum((x .- x_mean) .* (y .- y_mean))
    den = sum((x .- x_mean) .^ 2)
    if den == 0
        return 0.0
    end
    return num / den
end

function fmt_sci_val(x)
    if x == 0
        return "0"
    end
    if abs(x) < 1e-4 || abs(x) > 1e4
        ex = floor(Int, log10(abs(x)))
        mant = x / 10.0^ex
        return @sprintf("%.2f \\times 10^{%d}", mant, ex)
    else
        return @sprintf("%.4f", x)
    end
end

function get_cell_latex(mean_val, var_val, metric_type)
    # metric_type: :error, :time, :gates
    # Time: %.4f
    # Gates: %.1f
    # Error: Sci

    if metric_type == :error
        v = fmt_sci_val(mean_val)
        # For error variance, usually small, stick to sci
        v_var = fmt_sci_val(var_val)
        return "\\shortstack{ \$$v\$ \\\\ \\scriptsize{(\$$v_var\$)} }"
    elseif metric_type == :time
        v = @sprintf("%.4f", mean_val)
        v_var = @sprintf("%.1e", var_val)
        return "\\shortstack{ $v \\\\ \\scriptsize{($v_var)} }"
    elseif metric_type == :gates
        v = @sprintf("%.1f", mean_val)
        v_var = @sprintf("%.1f", var_val)
        return "\\shortstack{ $v \\\\ \\scriptsize{($v_var)} }"
    end
end

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--csv", "-c"
        help = "Input CSV filename"
        default = "sk_basis_comparison.csv"
        "--output-dir", "-o"
        help = "Directory containing the CSV"
        default = "."
    end
    return parse_args(s)
end

function main()
    args = parse_commandline()
    csv_input = args["csv"]
    dir = args["output-dir"]

    # Robust Path Resolution
    # 1. Check if input is a valid path directly
    if isfile(csv_input)
        csv_path = csv_input
    else
        # 2. Check if it's in the output directory
        p = joinpath(dir, csv_input)
        if isfile(p)
            csv_path = p
        else
            # 3. Check if basename exists in output directory (handles duplicated path segments)
            p_base = joinpath(dir, basename(csv_input))
            if isfile(p_base)
                csv_path = p_base
            else
                # 4. Check relative to script (fallback)
                p_script = joinpath(@__DIR__, "..", basename(csv_input))
                if isfile(p_script)
                    csv_path = p_script
                else
                    error("CSV file not found. Tried: $csv_input, $p, $p_base")
                end
            end
        end
    end

    println("Reading data from: $csv_path")
    df = CSV.read(csv_path, DataFrame)

    # Base output name
    base_out = replace(basename(csv_path), ".csv" => "")
    txt_path = joinpath(dir, base_out * "_table.txt")
    tex_path = joinpath(dir, base_out * "_table.tex")

    # Metadata Extraction
    has_meta = "net_depth" in names(df) && "net_points" in names(df)
    has_min_dist = "net_min_dist" in names(df)

    net_d = has_meta ? string(df[1, :net_depth]) : "?"
    net_p = has_meta ? string(df[1, :net_points]) : "?"
    net_md = has_min_dist ? string(df[1, :net_min_dist]) : "0.08 (default)"

    # Group by Basis
    group_col = "basis_name" in names(df) ? :basis_name : :generator

    gdf = groupby(df, [group_col, :depth])

    stats = combine(gdf,
        :error => mean => :avg_err,
        :error => var => :var_err,
        :time => mean => :avg_time,
        :time => var => :var_time,
        :gates => mean => :avg_gates,
        :gates => var => :var_gates
    )

    bases = sort(unique(stats[!, group_col]))
    depths = sort(unique(stats.depth))

    # Fits
    fits = Dict()
    for b in bases
        sub = filter(row -> row[group_col] == b, stats)
        x = Float64.(sub.depth)
        y = log10.(max.(sub.avg_err, 1e-100))
        slope = linear_fit_slope(x, y)
        fits[b] = slope
    end

    # --- Generate Content ---

    # 1. Text Table
    txt_io = IOBuffer()
    println(txt_io, "\n" * "="^80)
    println(txt_io, " Solovay-Kitaev Analysis Table")
    println(txt_io, " Metadata: Net Depth=$net_d, Net Points=$net_p, Min Dist=$net_md")
    println(txt_io, "="^80)

    col_width = 25
    print(txt_io, rpad("Depth", 6) * "|" * rpad(" Metric", 10) * "|")
    for b in bases
        print(txt_io, rpad(" " * b, col_width) * "|")
    end
    println(txt_io)
    println(txt_io, "-"^(17 + (col_width + 1) * length(bases)))

    for d in depths
        for (metric, label) in [(:err, "Error"), (:time, "Time(s)"), (:gates, "Gates")]
            if metric == :err
                print(txt_io, rpad(" $d", 6) * "|")
            else
                print(txt_io, rpad(" ", 6) * "|")
            end
            print(txt_io, rpad(" $label", 10) * "|")

            for b in bases
                row = filter(r -> r[group_col] == b && r.depth == d, stats)
                if !isempty(row)
                    if metric == :err
                        val = row[1, :avg_err]
                        v = row[1, :var_err]
                        str = @sprintf("%.1e", val)
                    elseif metric == :time
                        val = row[1, :avg_time]
                        v = row[1, :var_time]
                        str = @sprintf("%.3f", val)
                    else
                        val = row[1, :avg_gates]
                        v = row[1, :var_gates]
                        str = @sprintf("%.0f", val)
                    end
                    if isnan(v)
                        v = 0.0
                    end
                    full_str = "$str (v=$(@sprintf("%.1e",v)))"
                    print(txt_io, rpad(" " * full_str, col_width) * "|")
                else
                    print(txt_io, rpad(" -", col_width) * "|")
                end
            end
            println(txt_io)
        end
        println(txt_io, "-"^(17 + (col_width + 1) * length(bases)))
    end

    print(txt_io, rpad("Scale", 17) * "|")
    for b in bases
        s = fits[b]
        str = @sprintf("10^(%.2f d)", s)
        print(txt_io, rpad(" " * str, col_width) * "|")
    end
    println(txt_io, "\n" * "="^80)

    # Write Text
    open(txt_path, "w") do f
        print(f, String(take!(txt_io)))
    end
    println("Text table saved to $txt_path")

    # 2. LaTeX Table
    tex_io = IOBuffer()
    println(tex_io, "% LaTeX Table Code")
    println(tex_io, "\\begin{table}[h]")
    println(tex_io, "\\centering")
    println(tex_io, "\\small")
    caption_text = "Analysis of random unitary approximation (avg and variance) for different basis sets. " *
                   "Configuration: Net Depth $net_d, Net Points $net_p, Min Dist $net_md. " *
                   "Metrics shown: Error (top), Runtime [s] (middle), Gate Count (bottom). " *
                   "Final row: Fitted scaling \$\\log_{10}(\\epsilon) \\propto \\alpha d\$."
    println(tex_io, "\\caption{$caption_text}")

    col_spec = "cc|" * repeat("c", length(bases))
    println(tex_io, "\\begin{tabular}{" * col_spec * "}")
    println(tex_io, "\\hline")

    latex_bases = map(b -> "\\textbf{" * replace(uppercasefirst(b), "_" => "\\_") * "}", bases)
    println(tex_io, "Depth & Metric & " * join(latex_bases, " & ") * " \\\\")
    println(tex_io, "\\hline")

    for d in depths
        print(tex_io, "\\multirow{3}{*}{$d} & Error ")
        for b in bases
            row = filter(r -> r[group_col] == b && r.depth == d, stats)
            if !isempty(row)
                c = get_cell_latex(row[1, :avg_err], coalesce(row[1, :var_err], 0.0), :error)
                print(tex_io, "& $c ")
            else
                print(tex_io, "& - ")
            end
        end
        println(tex_io, "\\\\")

        print(tex_io, " & Time (s) ")
        for b in bases
            row = filter(r -> r[group_col] == b && r.depth == d, stats)
            if !isempty(row)
                c = get_cell_latex(row[1, :avg_time], coalesce(row[1, :var_time], 0.0), :time)
                print(tex_io, "& $c ")
            else
                print(tex_io, "& - ")
            end
        end
        println(tex_io, "\\\\")

        print(tex_io, " & Gates ")
        for b in bases
            row = filter(r -> r[group_col] == b && r.depth == d, stats)
            if !isempty(row)
                c = get_cell_latex(row[1, :avg_gates], coalesce(row[1, :var_gates], 0.0), :gates)
                print(tex_io, "& $c ")
            else
                print(tex_io, "& - ")
            end
        end
        println(tex_io, "\\\\")
        println(tex_io, "\\hline")
    end

    print(tex_io, "\\multicolumn{2}{c|}{\\textbf{Scaling (Fit)}}")
    for b in bases
        s = fits[b]
        print(tex_io, " & \$10^{$(@sprintf("%.2f", s)) d}\$")
    end
    println(tex_io, "\\\\")
    println(tex_io, "\\hline")
    println(tex_io, "\\end{tabular}")
    println(tex_io, "\\label{tab:sk_analysis}")
    println(tex_io, "\\end{table}")

    # Write LaTeX
    open(tex_path, "w") do f
        print(f, String(take!(tex_io)))
    end
    println("LaTeX table saved to $tex_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
