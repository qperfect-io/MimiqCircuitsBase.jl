using Test
using MimiqCircuitsBase
using Symbolics

@testset "DSL Macros" begin
    @testset "@circuit DSL" begin
        c = @circuit begin
            @on GateX() q=1
            @on GateCX() q=(1, 2)
            @on Measure() q=1 c=123
        end
        
        @test numqubits(c) == 2
        @test numbits(c) == 123
        @test length(c) == 3
        @test getoperation(c[1]) isa GateX
        @test getqubits(c[1]) == (1,)
        @test getoperation(c[2]) isa GateCX
        @test getqubits(c[2]) == (1, 2)
        @test getoperation(c[3]) isa Measure
        @test getbits(c[3]) == (123,)
        
        # Test splatting simulation via push! range usage
        # Test splatting simulation via push! range usage
        c2 = @circuit begin
             @on GateX() q=1:2
        end
        @test length(c2) == 2
        
        # Test tuple splatting
        # Test tuple splatting
        c3 = @circuit begin
            @on GateCX() q=(1, 2)
        end
        @test length(c3) == 1
        @test getqubits(c3[1]) == (1, 2)
        
        # Test multiple q args
        c4 = @circuit begin
             @on GateCCX() q=1 q=2 q=3
        end
        @test length(c4) == 1
        @test getqubits(c4[1]) == (1, 2, 3)
    end

    @testset "@block DSL" begin
        blk = @block begin
            @on GateH() q=1
            @on GateZ() q=1
        end
        
        @test blk isa Block
        @test numqubits(blk) == 1
        @test length(blk) == 2
    end
    
    @testset "@gatedecl DSL" begin
        @gatedecl MyGate(theta) begin
            @on GateRX(theta) q=1
        end
        
        @test MyGate isa GateDecl
        @test length(MyGate._instructions) == 1
        @test getoperation(MyGate._instructions[1]) isa GateRX
        
        # Test usage
        g = MyGate(0.5)
        @test g isa GateCall
        @test g._decl == MyGate
        @test g._args == (0.5,)
    end
end
