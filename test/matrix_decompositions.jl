using Test
using LinearAlgebra
using Random
using MimiqCircuitsBase
using MimiqCircuitsBase: _csd_decomposition, _qsd_decomposition, _zyz_decomposition

# Helper helper to compute matrix of a circuit
function circuit_matrix(c::Circuit, n)
    U = Matrix{ComplexF64}(I, 2^n, 2^n)

    for inst in c
        op = getoperation(inst)
        idx = getqubits(inst) # 1-based indices of targets

        if op isa GateCustom
            mat = MimiqCircuitsBase.matrix(op)
        elseif hasmethod(MimiqCircuitsBase.matrix, (typeof(op),))
            mat = MimiqCircuitsBase.matrix(op)
        else
            error("Cannot get matrix for $op")
        end

        mat = ComplexF64.(mat)
        op_full = _expand_op(mat, idx, n)
        U = op_full * U
    end
    return U
end

function _expand_op(mat, targets, n)
    dim = 2^n
    P = zeros(ComplexF64, dim, dim)

    k = length(targets)
    others = [i for i in 1:n if i ∉ targets]
    perm = [collect(targets); others]

    for i in 0:dim-1
        bits = [(i >> (n - j)) & 1 for j in 1:n]
        new_bits = [bits[perm[j]] for j in 1:n]
        j_val = sum(new_bits[x] << (n - x) for x in 1:n)
        P[j_val+1, i+1] = 1.0
    end

    mat_full = kron(mat, Matrix{ComplexF64}(I, 2^(n - k), 2^(n - k)))
    return P' * mat_full * P
end


@testset "Matrix Decompositions" begin

    @testset "ZYZ Decomposition" begin
        # Test random single-qubit unitaries
        for _ in 1:5
            A = randn(ComplexF64, 2, 2)
            U = Matrix(qr(A).Q)

            theta, phi, lambda, gamma = _zyz_decomposition(U)

            # Reconstruct U = e^{i gam} Rz(phi) Ry(theta) Rz(lambda)
            g = GateU(theta, phi, lambda, gamma)
            U_rec = MimiqCircuitsBase.matrix(g)

            @test U ≈ U_rec atol = 1e-8
        end

        # Test edge cases
        # Identity
        U = Matrix{ComplexF64}(I, 2, 2)
        t, p, l, g = _zyz_decomposition(U)
        @test isapprox(t, 0, atol=1e-8)

        # Pauli X (theta = pi)
        U = [0 1; 1 0] .|> ComplexF64
        t, p, l, g = _zyz_decomposition(U)
        @test isapprox(t, pi, atol=1e-8)

        # Pauli Z (theta = 0)
        U = [1 0; 0 -1] .|> ComplexF64
        t, p, l, g = _zyz_decomposition(U)
        @test isapprox(t, 0, atol=1e-8)

        # A diagonal matrix has theta exactly 0. Deriving it from
        # `acos(|u00|)` returned ~1.5e-8 whenever `|u00|` rounded just below 1,
        # which then sent the rewrite down the general branch and read phases
        # off entries that are zero.
        U = diagm(ComplexF64[cis(0.3), cis(1.1)])
        t, p, l, g = _zyz_decomposition(U)
        @test t == 0
        @test MimiqCircuitsBase.matrix(GateU(t, p, l, g)) ≈ U atol = 1e-14

        # Anti-diagonal: `u01` and `u10` carry independent phases
        U = ComplexF64[0 cis(0.7); cis(-1.3) 0]
        t, p, l, g = _zyz_decomposition(U)
        @test MimiqCircuitsBase.matrix(GateU(t, p, l, g)) ≈ U atol = 1e-14

        # Phases that keep the matrix near-diagonal must stay exact
        for k in 0:31
            U = diagm(ComplexF64[cis(2π * k / 32), cis(2π * k / 32 + 0.7)])
            t, p, l, g = _zyz_decomposition(U)
            @test MimiqCircuitsBase.matrix(GateU(t, p, l, g)) ≈ U atol = 1e-14
        end
    end

    @testset "CSD Decomposition Matrix" begin

        # Test 2x2 Matrix (Scalar decomposition)
        # N=1 CSD implies breaking 2x2 into scalars? No, CSD is for 2n x 2n.
        # If N=1, CSD partitions into 1x1 blocks.
        A = randn(ComplexF64, 2, 2)
        U = Matrix(qr(A).Q)
        L0, L1, R0, R1, theta = _csd_decomposition(U)

        @test size(L0) == (1, 1)
        C = diagm(cos.(theta))
        S = diagm(sin.(theta))
        M = [C -S; S C]
        Left = [L0 zeros(1, 1); zeros(1, 1) L1]
        Right = [R0 zeros(1, 1); zeros(1, 1) R1]
        U_rec = Left * M * Right
        @test U ≈ U_rec atol = 1e-8

        # Test 4x4 Matrix
        Random.seed!(42)
        A = randn(ComplexF64, 4, 4)
        U = Matrix(qr(A).Q)

        L0, L1, R0, R1, theta = _csd_decomposition(U)

        C = diagm(cos.(theta))
        S = diagm(sin.(theta))
        M = [C -S; S C]

        Left = [L0 zeros(2, 2); zeros(2, 2) L1]
        Right = [R0 zeros(2, 2); zeros(2, 2) R1]
        U_rec = Left * M * Right
        @test U ≈ U_rec atol = 1e-8

        # Test 8x8 Matrix
        Random.seed!(43)
        A = randn(ComplexF64, 8, 8)
        U = Matrix(qr(A).Q)

        L0, L1, R0, R1, theta = _csd_decomposition(U)

        C = diagm(cos.(theta))
        S = diagm(sin.(theta))
        M = [C -S; S C]

        Left = [L0 zeros(4, 4); zeros(4, 4) L1]
        Right = [R0 zeros(4, 4); zeros(4, 4) R1]
        U_rec = Left * M * Right
        @test U ≈ U_rec atol = 1e-8

        # Edge Case: Diagonal Matrix (4x4)
        # Checks stability when sin(theta) is near 0
        U = diagm(cis.(ComplexF64[0.3, 1.1, -0.4, 2.2]))
        L0, L1, R0, R1, theta = _csd_decomposition(U)
        # The off-diagonal blocks are exactly zero, so the sines are too — they
        # used to come out at ~1.5e-8, the accuracy floor of `acos` near 1.
        @test all(iszero, theta)

        C = diagm(cos.(theta))
        S = diagm(sin.(theta))
        M = [C -S; S C]
        Left = [L0 zeros(2, 2); zeros(2, 2) L1]
        Right = [R0 zeros(2, 2); zeros(2, 2) R1]
        U_rec = Left * M * Right
        @test U ≈ U_rec atol = 1e-8

        # Edge Case: Swap Matrix
        # [0 I; I 0]. cos=0, sin=1. Theta=pi/2.
        U = [zeros(2, 2) Matrix(I, 2, 2); Matrix(I, 2, 2) zeros(2, 2)] .|> ComplexF64
        L0, L1, R0, R1, theta = _csd_decomposition(U)
        @test all(x -> isapprox(x, pi / 2, atol=1e-8), theta)

        C = diagm(cos.(theta))
        S = diagm(sin.(theta))
        M = [C -S; S C]
        Left = [L0 zeros(2, 2); zeros(2, 2) L1]
        Right = [R0 zeros(2, 2); zeros(2, 2) R1]
        U_rec = Left * M * Right
        @test U ≈ U_rec atol = 1e-8
    end

    @testset "QSD Circuit Construction" begin

        # Test N=1 (2x2)
        A = randn(ComplexF64, 2, 2)
        U = Matrix(qr(A).Q)
        c, phase = _qsd_decomposition(U)
        U_rec = circuit_matrix(c, 1)
        U_target = U * exp(-im * phase)
        @test abs(tr(U_target' * U_rec)) / 2 ≈ 1.0 atol = 1e-8

        # Test N=2 (4x4)
        Random.seed!(44)
        A = randn(ComplexF64, 4, 4)
        U = Matrix(qr(A).Q)
        c, phase = _qsd_decomposition(U)
        U_rec = circuit_matrix(c, 2)
        U_target = U * exp(-im * phase)
        @test abs(tr(U_target' * U_rec)) / 4 ≈ 1.0 atol = 1e-8

        # Test N=3 (8x8)
        Random.seed!(45)
        A = randn(ComplexF64, 8, 8)
        U = Matrix(qr(A).Q)
        c, phase = _qsd_decomposition(U)
        U_rec = circuit_matrix(c, 3)
        U_target = U * exp(-im * phase)
        @test abs(tr(U_target' * U_rec)) / 8 ≈ 1.0 atol = 1e-8

        # Edge Case: Diagonal Phase Gate
        U = diagm(exp.(im .* rand(4)))
        c, phase = _qsd_decomposition(U)
        U_rec = circuit_matrix(c, 2)
        U_target = U * exp(-im * phase)
        @test abs(tr(U_target' * U_rec)) / 4 ≈ 1.0 atol = 1e-8
    end

    @testset "GateCustom rewrite is exact" begin
        # The rewrite has to reproduce the matrix itself, not just something
        # proportional to it: the QSD phase used to be dropped on the way out,
        # and a degenerate (diagonal) input could come back with an O(1) phase
        # on a single amplitude.
        rewrite(U, n) = circuit_matrix(decompose(push!(Circuit(), GateCustom(U), (1:n)...)), n)

        fixed = [
            ComplexF64[0 1; 1 0],
            ComplexF64[1 0; 0 -1],
            ComplexF64[1 1; 1 -1] ./ sqrt(2),
            diagm(ComplexF64[1, 1, 1, -1]),
            ComplexF64[1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0],
            ComplexF64[1 0 0 0; 0 0 1 0; 0 1 0 0; 0 0 0 1],
            kron(ComplexF64[0 1; 1 0], ComplexF64[0 1; 1 0]),
        ]
        for U in fixed
            n = Int(log2(size(U, 1)))
            @test rewrite(U, n) ≈ U atol = 1e-12
        end

        # Diagonal matrices: every singular value is degenerate, and which
        # branch of the 1-qubit rewrite runs depends on how `|u00|` rounds, so
        # sweep the phase rather than trusting one draw.
        for k in 0:31
            d = cis.(2π * k / 32 .+ ComplexF64[0.0, 0.3, 1.1, 2.7])
            @test rewrite(diagm(d), 2) ≈ diagm(d) atol = 1e-12
        end

        rng = MersenneTwister(20260819)
        for n in 1:3
            U = Matrix(qr(randn(rng, ComplexF64, 2^n, 2^n)).Q)
            @test rewrite(U, n) ≈ U atol = 1e-12
        end
    end
end

@testset "GateCustom Integration" begin
    # Verify that GateCustom uses QSD correctly via decompose_step!

    # 2-Qubit Custom
    A = randn(ComplexF64, 4, 4)
    U = Matrix(qr(A).Q)
    g = GateCustom(U)
    inst = Instruction(g, 1, 2)

    c_decomp = decompose_step(inst)
    U_rec = circuit_matrix(c_decomp, 2)
    fid = abs(tr(U' * U_rec)) / 4
    @test fid ≈ 1.0 atol = 1e-8

    # 3-Qubit Custom
    A = randn(ComplexF64, 8, 8)
    U = Matrix(qr(A).Q)
    g = GateCustom(U)
    inst = Instruction(g, 1, 2, 3)

    c_decomp = decompose_step(inst)
    U_rec = circuit_matrix(c_decomp, 3)
    fid = abs(tr(U' * U_rec)) / 8
    @test fid ≈ 1.0 atol = 1e-8

    # Check Qubit Mapping (1, 3)
    # Use a 2-qubit gate applied to qubits 1 and 3
    A = randn(ComplexF64, 4, 4)
    U = Matrix(qr(A).Q)
    g2 = GateCustom(U)

    inst = Instruction(g2, 1, 3)
    c_decomp = decompose_step(inst)
    U_rec = circuit_matrix(c_decomp, 3) # 3 qubits total space
    U_exp = _expand_op(U, (1, 3), 3)
    fid = abs(tr(U_exp' * U_rec)) / 8
    @test fid ≈ 1.0 atol = 1e-8
end
