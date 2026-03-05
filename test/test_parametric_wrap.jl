using MimiqCircuitsBase
using Test
using Symbolics
using LinearAlgebra
using SymbolicUtils

@testset "Parametric GateDecl Decomposition" begin
    # Define a custom parametric gate and its decomposition
    struct MyParamGate{T} <: AbstractGate{1}
        theta::T
    end
    MimiqCircuitsBase.numparams(::MyParamGate) = 1
    MimiqCircuitsBase.parnames(::MyParamGate) = (:theta,)
    MimiqCircuitsBase.opname(::Type{<:MyParamGate}) = "MyParamGate"
    
    # Decompose into RX(theta)
    function MimiqCircuitsBase.decompose!(circ, ::CanonicalBasis, g::MyParamGate, qubits, _, _)
        push!(circ, GateRX(g.theta), qubits[1])
        return circ
    end

    c = Circuit()
    push!(c, MyParamGate(0.1), 1)
    push!(c, MyParamGate(0.2), 2)
    
    # Decompose with wrap=true
    decomposed_c = decompose(c; wrap=true)
    
    @test length(decomposed_c) == 2
    inst1 = decomposed_c[1]
    inst2 = decomposed_c[2]
    
    op1 = getoperation(inst1)
    op2 = getoperation(inst2)
    
    @test op1 isa GateCall
    @test op2 isa GateCall
    
    # They should share the same GateDecl
    @test op1._decl === op2._decl
    
    decl = op1._decl
    @test length(decl._arguments) == 1
    @test SymbolicUtils.issym(decl._arguments[1])
    
    # Check arguments
    @test op1._args == (0.1,)
    @test op2._args == (0.2,)
    
    # Check inner circuit of declaration
    # It should have GateRX(theta) where theta is symbolic
    # Note: GateRX decomposition itself might be wrapped if we are not careful?
    # GateRX is primitive in CanonicalBasis? 
    # Actually CanonicalBasis decomposes everything to U, CX. 
    # GateRX decomposes to U?
    # Let's check CanonicalBasis defaults. 
    # If GateRX decomposes, then inner_inst might be a GateCall or GateU.
    # But for this test, we just want to see if the param is passed through.
    
    inner_inst = decl._instructions[1]
    inner_op = getoperation(inner_inst)
    # inner_op should be GateRX(theta) (if not decomposed further) OR GateCall (if decomposed)
    
    println("Inner op type: ", typeof(inner_op))
    
    # Verify substitution works by checking matrix equality
    # matrix(op1) should be approx matrix(GateRX(0.1))
    
    # We need to ensure MyParamGate works with matrix if we want to compare.
    # But matrix(op1) calculates matrix from decomposition.
    
    m1 = matrix(op1)
    m2 = matrix(GateRX(0.1))
    
    # matrix(GateCall) returns Matrix{Complex{Num}}. We need to convert to numbers.
    m1_val = map(x -> Symbolics.value(x), m1)
    
    @test m1_val ≈ m2
end

@testset "GateCall Wrapping" begin
    # Create a GateDecl
    # @gatedecl not available here easily unless we include dsl. 
    # Let's construct manually.
    
    # GateDecl: custom_rot(theta) = RX(theta)
    theta = Symbolics.variable(:theta)
    inner_c = Circuit()
    push!(inner_c, GateRX(theta), 1)
    decl = GateDecl(:custom_rot, (Symbolics.value(theta),), inner_c._instructions)
    
    # Create circuit with two calls
    c = Circuit()
    push!(c, GateCall(decl, 0.1), 1)
    push!(c, GateCall(decl, 0.2), 1)
    
    # Decompose
    dc = decompose(c; wrap=true)
    
    @test length(dc) == 2
    inst1 = dc[1]
    inst2 = dc[2]
    
    op1 = getoperation(inst1)
    op2 = getoperation(inst2)
    
    @test op1 isa GateCall
    @test op2 isa GateCall
    
    # Check if they share the same decl
    @test op1._decl === op2._decl
    
    wrapper_decl = op1._decl
    @test wrapper_decl.name == Symbol("MIMIQ_custom_rot")
    @test length(wrapper_decl._arguments) == 1
    
    # Check if arguments are correct
    @test op1._args == (0.1,)
    @test op2._args == (0.2,)
    
    # Check inner structure of wrapper_decl
    # It should contain a GateCall to MIMIQ_GateRX (or similar, depending on GateRX decomp)
    # The crucial part is that it should be parametric on the wrapper's argument
    
    wrapper_arg = wrapper_decl._arguments[1]
    
    inner_inst = wrapper_decl._instructions[1]
    inner_op = getoperation(inner_inst)
    
    println("Wrapper inner op: ", typeof(inner_op))
    println("Wrapper inner op decl name: ", inner_op._decl.name)
    
    # The inner operation should use wrapper_arg
    # GateRX(theta) decomposes to ... well, GateRX is standard.
    # If standard gates are wrapped too:
    # GateRX(theta) -> GateCall(MIMIQ_RX, (theta,))
    
    # Check if inner_op is a GateCall and its arg matches wrapper_arg
    @test inner_op isa GateCall
    @test inner_op._args[1] === Symbolics.value(wrapper_arg) || isequal(inner_op._args[1], Symbolics.value(wrapper_arg))
end

@testset "Wrapper Parametric Decomposition" begin
    # Test GateCU (Control{..., GateU})
    c = Circuit()
    # GateCU(theta, phi, lambda, gamma)
    push!(c, GateCU(0.1, 0.2, 0.3, 0.4), 1, 2)
    push!(c, GateCU(0.5, 0.6, 0.7, 0.8), 1, 2)
    
    dc = decompose(c; wrap=true)
    
    @test length(dc) == 2
    op1 = getoperation(dc[1])
    op2 = getoperation(dc[2])
    
    @test op1 isa GateCall
    @test op2 isa GateCall
    @test op1._decl === op2._decl
    
    decl = op1._decl
    # GateCU has 4 parameters
    @test length(decl._arguments) == 4
    
    # Test Inverse(GateRX)
    # Inverse is parametric if inner op is parametric
    c2 = Circuit()
    push!(c2, inverse(GateRX(0.1)), 1)
    push!(c2, inverse(GateRX(0.2)), 1)
    
    dc2 = decompose(c2; wrap=true)
    
    @test length(dc2) == 2
    op3 = getoperation(dc2[1])
    op4 = getoperation(dc2[2])
    
    @test op3 isa GateCall
    @test op4 isa GateCall
    @test op3._decl === op4._decl
    
    decl2 = op3._decl
    @test length(decl2._arguments) == 1
    
    # Check that inner circuit uses Inverse of symbolic op
    # GateRX(theta) -> decomp
    # Inverse(GateRX(theta)) -> decomp of inverse
    
    # The key is that the wrapper logic should succeed in creating the symbolic op
end

@testset "Nested Parametric Wraps" begin
    # Test if nested parametric gates work
    struct OuterGate{T} <: AbstractGate{1}
        phi::T
    end
    MimiqCircuitsBase.numparams(::OuterGate) = 1
    MimiqCircuitsBase.parnames(::OuterGate) = (:phi,)
    MimiqCircuitsBase.opname(::Type{<:OuterGate}) = "OuterGate"
    
    struct InnerGate{T} <: AbstractGate{1}
        lam::T
    end
    MimiqCircuitsBase.numparams(::InnerGate) = 1
    MimiqCircuitsBase.parnames(::InnerGate) = (:lam,)
    MimiqCircuitsBase.opname(::Type{<:InnerGate}) = "InnerGate"
    
    MimiqCircuitsBase.decompose!(circ, ::CanonicalBasis, g::InnerGate, qubits, _, _) = begin
        push!(circ, GateRZ(g.lam), qubits[1])
        return circ
    end
    
    MimiqCircuitsBase.decompose!(circ, basis::CanonicalBasis, g::OuterGate, qubits, _, _) = begin
        push!(circ, InnerGate(g.phi * 2), qubits[1])
        return circ
    end
    
    c = Circuit()
    push!(c, OuterGate(0.5), 1)
    
    dc = decompose(c; wrap=true)
    
    inst = dc[1]
    op = getoperation(inst)
    @test op isa GateCall
    
    decl = op._decl
    @test length(decl._arguments) == 1
    
    # Check inner instructions of OuterGate
    # Should contain InnerGate(phi * 2) -> Wrapped as GateCall to InnerGate
    
    inner_inst = decl._instructions[1]
    inner_op = getoperation(inner_inst)
    
    @test inner_op isa GateCall
    # inner_op should be a call to MIMIQ_InnerGate
    
    # The argument to inner_op should be symbolic expression (phi * 2)
    # But GateCall stores NTuple{M, Num}.
    # (phi * 2) is a Num.
    
    @test inner_op._decl.name == Symbol("MIMIQ_InnerGate")
    
    # Check that caching works for InnerGate too
    # If we add another OuterGate, InnerGate decl should be reused?
    # The InnerGate decl is created inside OuterGate decl creation.
    
    # We can check if InnerGate decl uses symbolic param
    inner_decl = inner_op._decl
    @test length(inner_decl._arguments) == 1
    @test SymbolicUtils.issym(inner_decl._arguments[1])
end
