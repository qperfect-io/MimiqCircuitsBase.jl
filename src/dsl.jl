#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
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

"""
    @circuit begin ... end

Create a new `Circuit` and populate it with the instructions in the block.
The block supports the `@on` syntax for defining instructions.

# Examples
```julia
c = @circuit begin
    @on GateH() q=1
    @on GateCX() q=(1, 2)
end
```
"""
macro circuit(block)
    if block.head != :do && block.head != :block
         # Allow `@circuit begin ... end` as well
         if block.head == :block
              # ok
         else
              error("Expected `do` block or `begin ... end` block for @circuit")
         end
    end
    
    # Handle `c = @circuit do ... end` syntax where the block is the first argument
    # (parsed as `nothing -> block`)
    
    # If `block` is a do-block (Expr(:->, tuple, block)), extract the body.
    body = if block.head == :->
        block.args[2]
    else
        block
    end

    c_sym = gensym("c")
    new_body = rewrite_dsl_block(c_sym, body)

    return esc(quote
        let
            $c_sym = $MimiqCircuitsBase.Circuit()
            $new_body
            $c_sym
        end
    end)
end

"""
    @block do ... end

Create a new `Block` and populate it with the instructions in the block.
"""
macro block(block)
    # Similar handling for do-block
    body = if block isa Expr && block.head == :->
        block.args[2]
    else
        block
    end
    
    c_sym = gensym("c")
    new_body = rewrite_dsl_block(c_sym, body)

    return esc(quote
        let
            $c_sym = $MimiqCircuitsBase.Circuit()
            $new_body
            $MimiqCircuitsBase.Block($c_sym)
        end
    end)
end


"""
    @gatedecl Name(args...) begin ... end

Define a new gate type `Name` with the given arguments and instructions.
"""
macro gatedecl(head, body)
    if head.head != :call
        error("Expected function call syntax: @gatedecl Name(args...) begin ... end")
    end
    
    struct_name = head.args[1]
    args = head.args[2:end]
    
    arg_names = []
    for arg in args
         if arg isa Expr && arg.head == :(::)
             push!(arg_names, arg.args[1])
         elseif arg isa Symbol
             push!(arg_names, arg)
         else
             error("Arguments must be symbols or typed symbols.")
         end
    end
    
    # DSL Rewriting
    c_sym = gensym("c")
    new_body = rewrite_dsl_block(c_sym, body)
    
    name_sym = struct_name
    name_str = string(name_sym)
    
    vars_creation =Expr(:block)
    sym_vars_syms = []
    
    for arg in arg_names
        s_var = gensym(string(arg))
        push!(sym_vars_syms, s_var)
        push!(vars_creation.args, :($s_var = $SymbolicUtils.Sym{$SymbolicUtils.SymReal}($(QuoteNode(arg)); type=Real)))
        push!(vars_creation.args, :($(arg) = $s_var))
    end
    
    return esc(quote
        $name_sym = let
            $vars_creation
            $c_sym = $MimiqCircuitsBase.Circuit()
            $new_body
            $MimiqCircuitsBase.GateDecl(Symbol($name_str), ($(sym_vars_syms...),), $c_sym)
        end
    end)
end


function _parse_on_call(expr)
    # Expected: @on Gate() q=... c=... z=...
    # structure: macrocall(@on, line, gate_expr, kwargs...)
    
    gate_expr = expr.args[3]
    args = expr.args[4:end]
    
    qs = []
    cs = []
    zs = []
    
    for arg in args
        if arg isa Expr && arg.head == :(=)
            kw = arg.args[1]
            val = arg.args[2]
            
            target_list = if kw == :q
                qs
            elseif kw == :c
                cs
            elseif kw == :z
                zs
            else
                error("Unknown target keyword: $kw. Use q, c, or z.")
            end
            
            # Handle different value types:
            # - Tuple literals `(1, 2)` are splatted.
            # - Generators/varargs `...` are preserved as splats.
            # - Single values are pushed as-is.
            if val isa Expr && val.head == :tuple
                append!(target_list, val.args)
            elseif val isa Expr && val.head == :...
                 push!(target_list, val)
            else
                push!(target_list, val)
            end
        else
            # Positional arguments are ignored/not expected here
        end
    end
    
    return gate_expr, qs, cs, zs
end

function rewrite_dsl_block(circuit_sym, block)
    if !isa(block, Expr) || block.head != :block
         # It might be a single expression
         block = Expr(:block, block)
    end

    new_args = []
    
    for stmt in block.args
        if stmt isa LineNumberNode
            push!(new_args, stmt)
            continue
        end

        if stmt isa Expr && stmt.head == :macrocall && stmt.args[1] == Symbol("@on")
             gate, qs, cs, zs = _parse_on_call(stmt)
             
             push_stmt = :(push!($circuit_sym, $gate))
             append!(push_stmt.args, qs)
             append!(push_stmt.args, cs)
             append!(push_stmt.args, zs)
             
             push!(new_args, push_stmt)
        else
            push!(new_args, stmt)
        end
    end
    
    return Expr(:block, new_args...)
end
