#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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

module AsciiDraw

using ..MimiqCircuitsBase

struct AsciiCanvas
    width::Int
    data::Vector{Vector{Char}}
end

function AsciiCanvas(width::Int)
    AsciiCanvas(width, Vector{Vector{Char}}())
end

function AsciiCanvas()
    _, w = displaysize(stdout)
    AsciiCanvas(w)
end

getrows(canvas::AsciiCanvas) = length(canvas.data)

getcols(canvas::AsciiCanvas) = canvas.width

pushline!(canvas::AsciiCanvas) = push!(canvas.data, fill(' ', canvas.width))

function Base.setindex!(canvas::AsciiCanvas, value, row, col)
    while row > getrows(canvas)
        pushline!(canvas)
    end
    canvas.data[row][col] = value
end

function Base.getindex(canvas::AsciiCanvas, row, col)
    # NOTE: trick I don't really like. Maybe we should grow the canvas instead?
    if length(canvas.data) < row
        return ' '
    end
    canvas.data[row][col]
end

function Base.show(io::IO, canvas::AsciiCanvas)
    for row in canvas.data
        println(io, String(row))
    end

    return nothing
end

function _startmidstop(current, start, stop, startchar, midchar, stopchar)
    if current == start
        return startchar
    end

    if current == stop
        return stopchar
    end

    return midchar
end

function drawhline!(canvas::AsciiCanvas, row, col, width)
    startcol, stopcol = minmax(col, col + width - 1)
    for i in startcol:stopcol
        if canvas[row, i] == '│'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '├', '┼', '┤')
        elseif canvas[row, i] == '┤'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '┼', '┼', '┤')
        elseif canvas[row, i] == '├'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '├', '┼', '┼')
        elseif canvas[row, i] == '╵'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '└', '┴', '┘')
        elseif canvas[row, i] == '└'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '└', '┴', '┴')
        elseif canvas[row, i] == '┘'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '┴', '┴', '┘')
        elseif canvas[row, i] == '╷'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '┌', '┬', '┐')
        elseif canvas[row, i] == '║'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╟', '╫', '╢')
        elseif canvas[row, i] == '╟'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╟', '╫', '╫')
        elseif canvas[row, i] == '╢'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╫', '╫', '╢')
        elseif canvas[row, i] == '╶'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╶', '─', '─')
        elseif canvas[row, i] == '╴'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '─', '─', '╴')
        else
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╶', '─', '╴')
        end
    end
    return canvas
end

function drawvline!(canvas::AsciiCanvas, row, col, height)
    startcorow, stoprow = minmax(row, row + height - 1)
    for i in startcorow:stoprow
        if canvas[i, col] == '─'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '┬', '┼', '┴')
        elseif canvas[i, col] == '┴'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '┼', '┼', '┴')
        elseif canvas[i, col] == '┬'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '┬', '┼', '┼')
        elseif canvas[i, col] == '╴'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '┐', '┤', '┘')
        elseif canvas[i, col] == '┐'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '┐', '┤', '┤')
        elseif canvas[i, col] == '┘'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '┤', '┤', '┘')
        elseif canvas[i, col] == '╶'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '┌', '├', '└')
        elseif canvas[i, col] == '┌'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '┌', '├', '├')
        elseif canvas[i, col] == '└'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '├', '├', '└')
        elseif canvas[i, col] == '╵'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '│', '│', '╵')
        elseif canvas[i, col] == '╷'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╷', '│', '│')
        elseif canvas[i, col] == '═'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╤', '╪', '╧')
        elseif canvas[i, col] == '╤'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╤', '╪', '╪')
        elseif canvas[i, col] == '╧'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╪', '╪', '╧')
        else
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╷', '│', '╵')
        end
    end
    return canvas
end

function drawdoublehline!(canvas::AsciiCanvas, row, col, width)
    startcol, stopcol = minmax(col, col + width - 1)
    for i in startcol:stopcol
        if canvas[row, i] == '│'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╞', '╪', '╡')
        elseif canvas[row, i] == '╞'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╞', '╪', '╪')
        elseif canvas[row, i] == '╡'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╪', '╪', '╡')
        elseif canvas[row, i] == '╵'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╘', '╧', '╛')
        elseif canvas[row, i] == '╘'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╘', '╧', '╧')
        elseif canvas[row, i] == '╛'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╧', '╧', '╛')
        elseif canvas[row, i] == '╷'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╒', '╤', '╕')
        elseif canvas[row, i] == '╒'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╒', '╤', '╤')
        elseif canvas[row, i] == '╕'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╤', '╤', '╕')
        elseif canvas[row, i] == '║'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╠', '╬', '╣')
        elseif canvas[row, i] == '╠'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╠', '╬', '╣')
        elseif canvas[row, i] == '╣'
            canvas[row, i] = _startmidstop(i, startcol, stopcol, '╠', '╬', '╣')
        else
            canvas[row, i] = '═'
        end
    end
    return canvas
end

function drawdoublevline!(canvas::AsciiCanvas, row, col, height)
    startcorow, stoprow = minmax(row, row + height - 1)
    for i in startcorow:stoprow
        if canvas[i, col] == '─'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╥', '╫', '╨')
        elseif canvas[i, col] == '╥'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╥', '╫', '╫')
        elseif canvas[i, col] == '╨'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╫', '╫', '╨')
        elseif canvas[i, col] == '╶'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╓', '╟', '╙')
        elseif canvas[i, col] == '╓'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╓', '╟', '╟')
        elseif canvas[i, col] == '╙'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╟', '╟', '╙')
        elseif canvas[i, col] == '╴'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╖', '╢', '╜')
        elseif canvas[i, col] == '╖'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╖', '╢', '╢')
        elseif canvas[i, col] == '╜'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╢', '╢', '╜')
        elseif canvas[i, col] == '═'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╦', '╬', '╩')
        elseif canvas[i, col] == '╩'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╬', '╬', '╩')
        elseif canvas[i, col] == '╦'
            canvas[i, col] = _startmidstop(i, startcorow, stoprow, '╦', '╬', '╬')
        else
            canvas[i, col] = '║'
        end
    end
    return canvas
end

function drawfill!(canvas::AsciiCanvas, char, row, col, width, height)
    for i in row:row+height-1, j in col:col+width-1
        canvas[i, j] = char
    end
    return canvas
end

function drawempty!(canvas::AsciiCanvas, row, col, width, height)
    for i in row:row+height-1, j in col:col+width-1
        if j == col && canvas[i, j] == '╫'
            canvas[i, j] = '╢'
        elseif j == col + width - 1 && canvas[i, j] == '╫'
            canvas[i, j] = '╟'
        elseif j == col && canvas[i, j] == '╪'
            canvas[i, j] = '╡'
        elseif j == col + width - 1 && canvas[i, j] == '╪'
            canvas[i, j] = '╞'
        elseif j == col && canvas[i, j] == '─'
            canvas[i, j] = '╴'
        elseif j == col + width - 1 && canvas[i, j] == '─'
            canvas[i, j] = '╶'
        elseif i == row && canvas[i, j] == '│'
            canvas[i, j] = '╵'
        elseif i == row + height - 1 && canvas[i, j] == '│'
            canvas[i, j] = '╷'
        elseif i == row && canvas[i, j] == '╫'
            canvas[i, j] = '╨'
        elseif i == row + height - 1 && canvas[i, j] == '╫'
            canvas[i, j] = '╤'
        elseif i == row && (canvas[i, j] == '┘' || canvas[i, j] == '└' || canvas[i, j] == '┴')
            continue
        elseif i == row + height - 1 && (canvas[i, j] == '┌' || canvas[i, j] == '┐' || canvas[i, j] == '┬')
            continue
        else
            canvas[i, j] = ' '
        end
    end
end

function drawbox!(canvas::AsciiCanvas, row, col, width, height; clean=false)
    if width < 2 || height < 2
        error("Cannot draw box. Insufficient dimensions.")
    end

    if clean
        drawempty!(canvas, row, col, width, height)
    end

    drawhline!(canvas, row, col, width)
    drawhline!(canvas, row + height - 1, col, width)
    drawvline!(canvas, row, col, height)
    drawvline!(canvas, row, col + width - 1, height)

    return canvas
end

function drawtext!(canvas::AsciiCanvas, text::String, row, col)
    for (i, c) in enumerate(collect(text))
        canvas[row, col+i-1] = c
    end
    return canvas
end

function drawvtext!(canvas::AsciiCanvas, text::String, row, col)
    for (i, c) in enumerate(collect(text))
        canvas[row+i, col] = c
    end
    return canvas
end

function reset!(canvas::AsciiCanvas)
    empty!(canvas.data)
    return canvas
end

mutable struct AsciiCircuit
    # canvas used for drawin
    canvas::AsciiCanvas

    # vertical position for the bits
    qubitrow::Dict{Int,Int}

    # vertical position of the row for bits
    bitrow::Union{Int,Nothing}

    # vertical position of the row for zvariables
    zvarrow::Union{Int,Nothing}

    nonerow::Union{Int,Nothing}

    currentcol::Int
end

function AsciiCircuit(width::Int)
    return AsciiCircuit(AsciiCanvas(width), Dict(), nothing, nothing, nothing, 1)
end

function AsciiCircuit()
    _, w = displaysize(stdout)
    AsciiCircuit(w)
end

setcurrentcol!(circuit::AsciiCircuit, col) = circuit.currentcol = max(circuit.currentcol, col)
getcurrentcol(circuit::AsciiCircuit) = circuit.currentcol

getqubitrow(circuit::AsciiCircuit, qubit) = circuit.qubitrow[qubit]
getbitrow(circuit::AsciiCircuit) = circuit.bitrow
getzvarrow(circuit::AsciiCircuit) = circuit.zvarrow

function reset!(circuit::AsciiCircuit)
    reset!(circuit.canvas)
    circuit.qubitrow = Dict()
    circuit.bitrow = nothing
    circuit.zvarrow = nothing
    circuit.nonerow = nothing
    circuit.currentcol = 1
    return circuit
end

function drawwires!(circuit::AsciiCircuit, qubits, bits, zvars)
    for (i, q) in enumerate(qubits)
        row = (i - 1) * 2 + 2

        qubitstr = "q[$q]: "
        drawtext!(circuit.canvas, qubitstr, row, 1)

        circuit.qubitrow[q] = row

        setcurrentcol!(circuit, length(qubitstr) + 1)
    end

    if length(bits) > 0
        row = length(qubits) * 2 + 3

        bitstr = "c: "
        drawtext!(circuit.canvas, bitstr, row, 1)

        circuit.bitrow = row

        setcurrentcol!(circuit, length(bitstr) + 1)
    end

    if length(zvars) > 0
        if length(bits) < 1
            row = (length(qubits)) * 2 + 3
        else
            row = (length(qubits) + 1) * 2 + 3
        end

        zstr = "z: "
        drawtext!(circuit.canvas, zstr, row, 1)

        circuit.zvarrow = row

        setcurrentcol!(circuit, length(zstr) + 1)
    end

    ccol = getcurrentcol(circuit)

    for i in 1:length(qubits)
        row = (i - 1) * 2 + 1
        drawfill!(circuit.canvas, ' ', row, ccol, getcols(circuit.canvas) - ccol, 1)
        drawhline!(circuit.canvas, row + 1, ccol, getcols(circuit.canvas) - ccol)
    end

    drawfill!(circuit.canvas, ' ', (length(qubits) - 1) * 2 + 3, ccol, getcols(circuit.canvas) - ccol, 1)

    if length(bits) > 0
        row = length(qubits) * 2 + 2
        drawfill!(circuit.canvas, ' ', row, ccol, getcols(circuit.canvas) - ccol, 1)
        drawdoublehline!(circuit.canvas, row + 1, ccol, getcols(circuit.canvas) - ccol)
    end

    if length(zvars) > 0
        if length(bits) < 1
            row = (length(qubits)) * 2 + 2
        else
            row = (length(qubits) + 1) * 2 + 2
        end

        drawfill!(circuit.canvas, ' ', row, ccol, getcols(circuit.canvas) - ccol, 1)
        drawdoublehline!(circuit.canvas, row + 1, ccol, getcols(circuit.canvas) - ccol)
    end

    setcurrentcol!(circuit, ccol + 1)

    return circuit
end

function _gatenamepadding(qubits, bits, zvars)
    nq = length(qubits)

    qubitspadding = nq <= 1 ? 0 : floor(Int, log10(length(qubits))) + 2
    bitspadding = isempty(bits) ? 0 : length(join(string.(bits), ","))
    zvarspadding = isempty(zvars) ? 0 : length(join(string.(zvars), ","))

    return max(qubitspadding, bitspadding, zvarspadding)
end

function draw!(circuit::AsciiCircuit, g::Operation{0,N,M}, qubits, bits, zvars) where {N,M}
    namepadding = _gatenamepadding((), bits, zvars)

    ccol = getcurrentcol(circuit)

    bitrow = getbitrow(circuit)
    zvarrow = getzvarrow(circuit)

    startrow = min(isempty(bits) ? typemax(Int) : bitrow, isempty(zvars) ? typemax(Int) : zvarrow) - 1
    stoprow = max(isempty(bits) ? 0 : bitrow, isempty(zvars) ? 0 : zvarrow) + 1

    gateheight = stoprow - startrow + 1

    midrow = startrow + gateheight ÷ 2

    gw = asciiwidth(g, qubits, bits, zvars)

    drawbox!(circuit.canvas, startrow, ccol, gw, gateheight; clean=true)

    drawtext!(circuit.canvas, repr("text/plain", g; context=:compact => true), midrow, ccol + namepadding + 2)

    if !isempty(bits)
        bitsstr = join(string.(bits), ",")
        drawtext!(circuit.canvas, bitsstr, bitrow, ccol + 1)
    end

    if !isempty(zvars)
        zvarsstr = join(string.(zvars), ",")
        drawtext!(circuit.canvas, zvarsstr, zvarrow, ccol + 1)
    end

    setcurrentcol!(circuit, ccol + gw)

    return circuit
end

function asciiwidth(g::Operation{0,N,M}, qubits, bits, zvars=()) where {N,M}
    # num + space
    namepadding = _gatenamepadding((), bits, zvars)

    # | + (num + space) + name + |
    return 1 + namepadding + 1 + length(repr("text/plain", g; context=:compact => true)) + 1
end

function draw!(circuit::AsciiCircuit, g::Operation{N,M,L}, qubits, bits, zvars) where {N,M,L}
    namepadding = _gatenamepadding(qubits, (), ())

    ccol = getcurrentcol(circuit)

    qubitrow = [getqubitrow(circuit, q) for q in qubits]
    bitrow = getbitrow(circuit)
    zvarrow = getzvarrow(circuit)

    startrow = minimum(qubitrow) - 1
    stoprow = maximum(qubitrow) + 1

    gateheight = stoprow - startrow + 1

    midrow = startrow + gateheight ÷ 2

    gw = asciiwidth(g, qubits, bits, zvars)
    midcol = ccol + gw ÷ 2

    drawbox!(circuit.canvas, startrow, ccol, gw, gateheight; clean=true)

    drawtext!(circuit.canvas, repr("text/plain", g; context=:compact => true), midrow, ccol + namepadding + 1)

    if length(qubits) > 1
        for (i, qr) in enumerate(qubitrow)
            drawtext!(circuit.canvas, string(i), qr, ccol + 1)
        end
    end

    endcol = ccol + gw
    setcurrentcol!(circuit, endcol)

    if !isempty(bits)
        bitstr = join(string.(bits), ",")
        drawdoublevline!(circuit.canvas, stoprow, midcol, bitrow - stoprow + 1)
        drawtext!(circuit.canvas, bitstr, bitrow + 1, midcol)
        setcurrentcol!(circuit, max(endcol, midcol + length(bitstr)))
    end

    if !isempty(zvars)
        zvarstr = join(string.(zvars), ",")
        drawdoublevline!(circuit.canvas, stoprow, midcol, zvarrow - stoprow + 1)
        drawtext!(circuit.canvas, zvarstr, zvarrow + 1, midcol)
        setcurrentcol!(circuit, max(endcol, midcol + length(zvarstr)))
    end

    return circuit
end

function asciiwidth(g::Operation{N,M,L}, qubits, bits, zvars=()) where {N,M,L}
    namepadding = _gatenamepadding(qubits, (), ())
    return 1 + namepadding + length(repr("text/plain", g; context=:compact => true)) + 1
end

function draw!(circuit::AsciiCircuit, g::Operation{0,0,0}, _, _, _)
    # If nonerow is not initialized, create it
    if circuit.nonerow === nothing
        none_row_start = (length(circuit.qubitrow) + (circuit.bitrow !== nothing ? 1 : 0) + (circuit.zvarrow !== nothing ? 1 : 0)) * 2 + 3
        circuit.nonerow = none_row_start

        # Draw an empty line and the double horizontal line for "NoneRow"
        ccol = 1
        drawfill!(circuit.canvas, ' ', none_row_start, ccol, getcols(circuit.canvas) - ccol, 1)
        drawdoublehline!(circuit.canvas, none_row_start, ccol, getcols(circuit.canvas) - ccol)
    end

    # Now draw the operation on the None line
    none_row = circuit.nonerow
    ccol = getcurrentcol(circuit)
    op_name = repr("text/plain", g; context=:compact => true)
    gw = length(op_name) + 4

    drawbox!(circuit.canvas, none_row - 1, ccol, gw, 3, clean=true)
    drawtext!(circuit.canvas, op_name, none_row, ccol + 2)

    setcurrentcol!(circuit, ccol + gw)

    return circuit
end

# draw a symbol-controlled gate
function draw!(circuit::AsciiCircuit, g::Control{N,1}, qubits, _, _) where {N}
    qrow = getqubitrow(circuit, qubits[end])
    ctrlrows = [getqubitrow(circuit, q) for q in qubits[1:end-1]]

    maxr = max(maximum(ctrlrows), qrow)
    minr = min(minimum(ctrlrows), qrow)

    ccol = getcurrentcol(circuit)
    gatewidth = asciiwidth(getoperation(g), qubits[end:end], [])
    midcol = ccol + gatewidth ÷ 2

    drawvline!(circuit.canvas, minr, midcol, maxr - minr + 1)

    for r in ctrlrows
        circuit.canvas[r, midcol] = '●'
    end

    draw!(circuit, getoperation(g), qubits[end:end], [], [])

    setcurrentcol!(circuit, ccol + 1)

    return circuit
end

function draw!(circuit::AsciiCircuit, ::Barrier, qubits, _, _)
    for q in qubits
        qrow = getqubitrow(circuit, q)
        col = getcurrentcol(circuit)
        drawtext!(circuit.canvas, "░", qrow - 1, col)
        drawtext!(circuit.canvas, "░", qrow, col)
        drawtext!(circuit.canvas, "░", qrow + 1, col)
    end

    setcurrentcol!(circuit, getcurrentcol(circuit) + 1)

    return circuit
end

function asciiwidth(::Barrier, qubits, bits)
    return 1
end

function draw!(circuit::AsciiCircuit, g::IfStatement, qubits, bits, _)
    qubitrow = [getqubitrow(circuit, q) for q in qubits]
    bitrow = getbitrow(circuit)

    nb = numbits(g)
    val = getbitstring(g)

    ccol = getcurrentcol(circuit)

    bstr = MimiqCircuitsBase._string_with_square(MimiqCircuitsBase._findunitrange(bits), ",")
    btext = "c$bstr==" * to01(val)

    drawbox!(circuit.canvas, bitrow - 1, ccol, length(btext) + 2, 3; clean=true)
    drawtext!(circuit.canvas, btext, bitrow, ccol + 1)

    setcurrentcol!(circuit, ccol + length(btext) + 2)
    ifcol = getcurrentcol(circuit)

    qstartrow = minimum(qubitrow) - 1
    qstoprow = maximum(qubitrow) + 1
    qw = asciiwidth(getoperation(g), qubits, (), ())
    qh = qstoprow - qstartrow + 1
    qmh = qstartrow + qh ÷ 2
    namepadding = _gatenamepadding(qubits, (), ())

    drawbox!(circuit.canvas, qstartrow, ifcol, qw, qh; clean=true)

    for (i, qr) in enumerate(qubitrow)
        drawtext!(circuit.canvas, string(i), qr, ifcol + 1)
    end

    drawtext!(circuit.canvas, repr("text/plain", getoperation(g); context=:compact => true), qmh, ifcol + namepadding + 1)

    midcol = ifcol + qw ÷ 2

    drawdoublevline!(circuit.canvas, qstoprow, midcol, bitrow - qstoprow)
    drawdoublehline!(circuit.canvas, bitrow - 1, ifcol, midcol - ifcol)
    drawtext!(circuit.canvas, "╝", bitrow - 1, midcol)
    drawtext!(circuit.canvas, "○", bitrow - 1, ifcol)

    setcurrentcol!(circuit, ifcol + qw)
end

function asciiwidth(g::IfStatement, qubits, bits)
    nb = numbits(g)

    val = getbitstring(g)

    gw = asciiwidth(getoperation(g), qubits, [])
    bstr = MimiqCircuitsBase._string_with_square(MimiqCircuitsBase._findunitrange(bits), ",")
    iw = length("c$bstr==" * to01(val)) + 2
    return max(gw, iw)
end

function draw!(circuit::AsciiCircuit, ::Reset, qubits, _, _)
    qrow = getqubitrow(circuit, qubits[1])
    ccol = getcurrentcol(circuit)
    drawbox!(circuit.canvas, qrow - 1, ccol, 5, 3; clean=true)
    drawtext!(circuit.canvas, "|0⟩", qrow, ccol + 1)
    setcurrentcol!(circuit, ccol + 5)
    return circuit
end

function asciiwidth(::Reset, _, _)
    return 5
end

function draw!(canvas::AsciiCircuit, p::Parallel, qubits, _, _)
    op = getoperation(p)
    nq = numqubits(op)

    ccol = getcurrentcol(canvas)

    for i in 1:numrepeats(p)
        canvas.currentcol = ccol
        draw!(canvas, op, qubits[nq*(i-1).+(1:nq)], [], [])
    end

    return canvas
end

function draw!(circuit::AsciiCircuit, g::PauliString, qubits, bits)
    ccol = getcurrentcol(circuit)
    qubitrow = [getqubitrow(circuit, q) for q in qubits]

    startrow = minimum(qubitrow) - 1
    stoprow = maximum(qubitrow) + 1
    gateheight = stoprow - startrow + 1

    gw = asciiwidth(g, qubits, bits)

    drawbox!(circuit.canvas, startrow, ccol, gw, gateheight; clean=true)

    for (i, qr) in enumerate(qubitrow)
        pauli_char = g.pauli[i]
        label = (length(qubits) > 1) ? "$(i): $(pauli_char)" : "$(pauli_char)"
        drawtext!(circuit.canvas, label, qr, ccol + 1)
    end

    setcurrentcol!(circuit, ccol + gw)

    return circuit
end

function asciiwidth(g::PauliString, qubits, _, _)
    if length(qubits) == 1
        return length(string(g.pauli[1])) + 2 # Extra space for padding
    else
        max_label_length = maximum(length("$(i): $(g.pauli[i])") for i in 1:length(g.pauli))
        return max_label_length + 2 # Extra space for padding
    end
end

asciiwidth(instr::Instruction) = asciiwidth(getoperation(instr), getqubits(instr), getbits(instr), getztargets(instr))

draw!(canvas::AsciiCircuit, instr::Instruction) = draw!(canvas, getoperation(instr), getqubits(instr), getbits(instr), getztargets(instr))

function draw(c::Circuit)
    nq = numqubits(c)
    nb = numbits(c)
    nz = numzvars(c)

    canvas = AsciiCircuit()
    drawwires!(canvas, 1:nq, 1:nb, 1:nz)

    for instr in c
        if asciiwidth(instr) > getcols(canvas.canvas) - getcurrentcol(canvas)
            println(canvas.canvas)
            println("...")
            reset!(canvas)
            drawwires!(canvas, 1:nq, 1:nb, 1:nz)
        end

        if asciiwidth(instr) > getcols(canvas.canvas) - getcurrentcol(canvas)
            @info "" asciiwidth(instr) instr
            error("Cannot draw instruction. Insufficient space on screen.")
        end

        draw!(canvas, instr)
    end

    # clean the rest of the canvas
    drawempty!(canvas.canvas, 1, getcurrentcol(canvas), getcols(canvas.canvas) - getcurrentcol(canvas), getrows(canvas.canvas))

    println(canvas.canvas)

    return nothing
end

end # module AsciiDraw

"""
    draw(circuit)

Draw an ascii representation of a circuit.

_NOTE_ it automatically detects the screen width and will split the circuit if it is too wide.
"""
function draw end

draw(c::Circuit) = AsciiDraw.draw(c)
