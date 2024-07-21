#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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

import ..MimiqCircuitsBase: getunwrappedvalue

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
        if j == col && canvas[i, j] == '─'
            canvas[i, j] = '╴'
        elseif j == col + width - 1 && canvas[i, j] == '─'
            canvas[i, j] = '╶'
        elseif i == row && canvas[i, j] == '│'
            canvas[i, j] = '╵'
        elseif i == row + height - 1 && canvas[i, j] == '│'
            canvas[i, j] = '╷'
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

    # column ready to be drawn to
    currentcol::Int
end

function AsciiCircuit(width::Int)
    return AsciiCircuit(AsciiCanvas(width), Dict(), nothing, 1)
end

function AsciiCircuit()
    _, w = displaysize(stdout)
    AsciiCircuit(w)
end

setcurrentcol!(circuit::AsciiCircuit, col) = circuit.currentcol = max(circuit.currentcol, col)
getcurrentcol(circuit::AsciiCircuit) = circuit.currentcol

getqubitrow(circuit::AsciiCircuit, qubit) = circuit.qubitrow[qubit]
getbitrow(circuit::AsciiCircuit) = circuit.bitrow

function reset!(circuit::AsciiCircuit)
    reset!(circuit.canvas)
    circuit.qubitrow = Dict()
    circuit.bitrow = nothing
    circuit.currentcol = 1
    return circuit
end

function drawwires!(circuit::AsciiCircuit, qubits, bits)
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

    setcurrentcol!(circuit, ccol + 1)

    return circuit
end

function _gatenamepadding(qubits, bits)
    nq = length(qubits)
    qubitspadding = nq == 1 ? 0 : floor(Int, log10(length(qubits))) + 2
    if isempty(bits)
        return qubitspadding
    end

    bitspadding = length(string(bits)) + 1

    return max(qubitspadding, bitspadding)
end

function draw!(circuit::AsciiCircuit, g::Operation{N,M}, qubits, bits) where {N,M}
    namepadding = _gatenamepadding(qubits, bits)

    ccol = getcurrentcol(circuit)

    qubitrow = [getqubitrow(circuit, q) for q in qubits]
    bitrow = getbitrow(circuit)

    startrow = (isempty(bits) ? minimum(qubitrow) : min(minimum(qubitrow), bitrow)) - 1
    stoprow = (isempty(bits) ? maximum(qubitrow) : max(maximum(qubitrow), bitrow)) + 1

    gateheight = stoprow - startrow + 1

    midrow = startrow + gateheight ÷ 2

    gw = asciiwidth(g, qubits, bits)

    drawbox!(circuit.canvas, startrow, ccol, gw, gateheight; clean=true)

    drawtext!(circuit.canvas, string(g), midrow, ccol + namepadding + 1)

    if length(qubits) > 1
        for (i, qr) in enumerate(qubitrow)
            drawtext!(circuit.canvas, string(i), qr, ccol + 1)
        end
    end

    if length(bits) > 1
        bitsstr = string(bits)
        drawtext!(circuit.canvas, bitsstr, bitrow, ccol + 2)
    end

    setcurrentcol!(circuit, ccol + gw)

    return circuit
end

function asciiwidth(g::Operation{N,M}, qubits, bits) where {N,M}
    # num + space
    namepadding = _gatenamepadding(qubits, bits)

    # | + (num + space) + name + |
    return 1 + namepadding + length(string(g)) + 1
end


# draw a symbol-controlled gate
function draw!(circuit::AsciiCircuit, g::Control{N,1}, qubits, _) where {N}
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

    draw!(circuit, getoperation(g), qubits[end:end], [])

    setcurrentcol!(circuit, ccol + 1)

    return circuit
end

function draw!(circuit::AsciiCircuit, ::Measure, qubits, bits)
    qubit = qubits[1]
    bit = bits[1]

    qrow = getqubitrow(circuit, qubit)
    brow = getbitrow(circuit)
    midcol = getcurrentcol(circuit) + 1

    drawbox!(circuit.canvas, qrow - 1, midcol - 1, 3, 3; clean=true)
    drawtext!(circuit.canvas, "M", qrow, midcol)
    setcurrentcol!(circuit, midcol + 2)

    drawdoublevline!(circuit.canvas, qrow + 1, midcol, brow - qrow)

    bitstr = "$bit"
    drawtext!(circuit.canvas, bitstr, brow + 1, midcol)
    setcurrentcol!(circuit, midcol + length(bitstr))

    return circuit
end

function asciiwidth(::Measure, _, bits)
    bit = bits[1]
    return max(3, 1 + length("$bit"))
end

function draw!(circuit::AsciiCircuit, ::Barrier, qubits, _)
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

function draw!(circuit::AsciiCircuit, g::IfStatement, qubits, bits)
    brow = getbitrow(circuit)
    val = getunwrappedvalue(g)
    bstr = MimiqCircuitsBase._string_with_square(MimiqCircuitsBase._findunitrange(bits), ",")
    btext = "c$bstr == 0x" * string(val; base=16)

    ccol = getcurrentcol(circuit)

    drawbox!(circuit.canvas, brow - 1, ccol, length(btext) + 2, 3; clean=true)
    drawtext!(circuit.canvas, btext, brow, ccol + 1)

    draw!(circuit, getoperation(g), qubits, [])

    qrow = maximum([getqubitrow(circuit, q) for q in qubits])

    drawdoublevline!(circuit.canvas, qrow + 1, ccol + 1, brow - qrow - 1)

    setcurrentcol!(circuit, ccol + length(btext) + 2)
end

function asciiwidth(g::IfStatement, qubits, bits)
    val = getunwrappedvalue(g)
    gw = asciiwidth(getoperation(g), qubits, [])
    bstr = MimiqCircuitsBase._string_with_square(MimiqCircuitsBase._findunitrange(bits), ",")
    iw = length("c$bstr == 0x" * string(val; base=16)) + 3
    return max(gw, iw)
end

function draw!(circuit::AsciiCircuit, ::Reset, qubits, _)
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

function draw!(canvas::AsciiCircuit, p::Parallel, qubits, _)
    op = getoperation(p)
    nq = numqubits(op)

    ccol = getcurrentcol(canvas)

    for i in 1:numrepeats(p)
        canvas.currentcol = ccol
        draw!(canvas, op, qubits[nq*(i-1).+(1:nq)], [])
    end

    return canvas
end

function draw!(circuit::AsciiCircuit, ::MeasureReset, qubits, bits)
    qubit = qubits[1]
    bit = bits[1]

    qrow = getqubitrow(circuit, qubit)
    brow = getbitrow(circuit)
    midcol = getcurrentcol(circuit) + 1

    drawbox!(circuit.canvas, qrow - 1, midcol - 1, 4, 3; clean=true)
    drawtext!(circuit.canvas, "MR", qrow, midcol)
    setcurrentcol!(circuit, midcol + 3)

    drawdoublevline!(circuit.canvas, qrow + 1, midcol, brow - qrow)

    bitstr = "$bit"
    drawtext!(circuit.canvas, bitstr, brow + 1, midcol)
    setcurrentcol!(circuit, midcol + length(bitstr))

    return circuit
end

function asciiwidth(::MeasureReset, _, bits)
    bit = bits[1]
    return max(3, 1 + length("$bit"))
end

asciiwidth(instr::Instruction) = asciiwidth(getoperation(instr), getqubits(instr), getbits(instr))

draw!(canvas::AsciiCircuit, instr::Instruction) = draw!(canvas, getoperation(instr), getqubits(instr), getbits(instr))

function draw(c::Circuit)
    nq = numqubits(c)
    nb = numbits(c)

    canvas = AsciiCircuit()
    drawwires!(canvas, 1:nq, 1:nb)

    for instr in c
        if asciiwidth(instr) > getcols(canvas.canvas) - getcurrentcol(canvas)
            println(canvas.canvas)
            println("...")
            reset!(canvas)
            drawwires!(canvas, 1:nq, 1:nb)
        end

        if asciiwidth(instr) > getcols(canvas.canvas) - getcurrentcol(canvas)
            error("Cannot draw instruction. Insufficient space on screen.")
        end

        draw!(canvas, instr)
    end

    println(canvas.canvas)

    return nothing
end

end

"""
    draw(circuit)

Draw an ascii representation of a circuit.

_NOTE_ it automatically detects the screen width and will split the circuit if it is too wide.
"""
function draw end

draw(c::Circuit) = AsciiDraw.draw(c)
