using JLD2, JuMP

@load "raw/model_data.jld2"

sgn = m0 <= 0 ? 1 : -1   # success  <=>  sgn * m >= Int(m0 <= 0)

# Votes modification x = (A, J, K); returns final votes v', c', α, δ and x as a flat vector
function add_votes!(model)
    A = @variable(model, [1:nP], Int, lower_bound = 0)
    J = @variable(model, [1:nP], Int, lower_bound = 0)
    K = @variable(model, [p in 1:nP], Int, lower_bound = 0, upper_bound = v[p])
    Ae = [@variable(model, [1:length(R[e])], Int, lower_bound = 0) for e in 1:nE]
    Je = [@variable(model, [1:length(R[e])], Int, lower_bound = 0) for e in 1:nE]
    Ke = [@variable(model, [k in 1:length(R[e])], Int, lower_bound = 0, upper_bound = c[e][k]) for e in 1:nE]
    @constraint(model, sum(J) == sum(K))
    @constraint(model, [p in 1:nP], J[p] + K[p] <= sum(K))
    for e in 1:nE
        @constraint(model, sum(Je[e]) == sum(Ke[e]))
        @constraint(model, [k in eachindex(R[e])], Je[e][k] + Ke[e][k] <= sum(Ke[e]))
    end
    vp = v .+ A .+ J .- K
    cp = [c[e] .+ Ae[e] .+ Je[e] .- Ke[e] for e in 1:nE]
    α = sum(A) + sum(sum, Ae)
    δ = sum(K) + sum(sum, Ke)
    return vp, cp, α, δ, [A; J; K; reduce(vcat, Ae); reduce(vcat, Je); reduce(vcat, Ke)]
end

# Election rules. η === nothing: every tie resolution admissible (η ≡ 0).
# η = (π, σ): π[p] priority rank of party p, σ[e][k] priority rank of option k in electorate e (1 = highest).
function add_rules!(model, vp, cp, η)
    w = [@variable(model, [1:length(R[e])], Bin) for e in 1:nE]
    d = [AffExpr(0) for p in 1:nP]
    n = AffExpr(0)
    for e in 1:nE
        @constraint(model, sum(w[e]) == 1)
        for r in eachindex(R[e])
            R[e][r] == 0 ? add_to_expression!(n, w[e][r]) : add_to_expression!(d[R[e][r]], w[e][r])
            for s in eachindex(R[e])
                s == r && continue
                ηe = η === nothing ? 0 : Int(η[2][e][s] < η[2][e][r])
                @constraint(model, w[e][r] --> {cp[e][r] - cp[e][s] >= ηe})
            end
        end
    end

    V = sum(vp)
    h = @variable(model, [1:nP], Bin)
    u = @variable(model, [1:nP], Bin)
    g = @variable(model, [1:nP], Bin)
    @constraint(model, [p in 1:nP], h[p] --> {20vp[p] - V >= 0})
    @constraint(model, [p in 1:nP], !h[p] --> {20vp[p] - V <= -1})
    @constraint(model, u .<= d)
    @constraint(model, d .<= nE .* u)
    @constraint(model, g .>= h)
    @constraint(model, g .>= u)
    @constraint(model, g .<= h .+ u)

    # Sainte-Laguë via threshold θ; φ is the priority cut among quotients equal to θ
    z = @variable(model, [1:nP, 1:N], Bin)
    y = @variable(model, [1:nP, 1:N], Bin)
    θ = @variable(model, lower_bound = 0)
    @constraint(model, y .== g .- z)
    @constraint(model, [p in 1:nP, k in 1:N-1], z[p, k+1] <= z[p, k])
    @constraint(model, sum(z) == N - n)
    γ = η === nothing ? 0.0 : 1 / (2N)
    φ = η === nothing ? zeros(nP) : @variable(model, [1:nP], Bin)
    if η !== nothing
        order = sortperm(η[1])
        @constraint(model, [i in 1:nP-1], φ[order[i]] >= φ[order[i+1]])
    end
    @constraint(model, [p in 1:nP, k in 1:N], z[p, k] --> {vp[p] - (2k - 1) * θ + γ * φ[p] >= γ})
    @constraint(model, [p in 1:nP, k in 1:N], y[p, k] --> {vp[p] - (2k - 1) * θ + γ * φ[p] <= 0})
    s = [sum(z[p, :]) for p in 1:nP]

    # t = max(s, d)
    t = @variable(model, [1:nP], Int)
    b = @variable(model, [1:nP], Bin)
    @constraint(model, t .>= s)
    @constraint(model, t .>= d)
    @constraint(model, t .<= s .+ nE .* b)
    @constraint(model, t .<= d .+ N .* (1 .- b))
    m = 2sum(t[p] for p in U) - (n + sum(t))
    return (; m, w, s, g)
end

# Solve with FiberSCIP; returns a function mapping each JuMP variable to its solution value.
# Ref: fscip syntax from UG documentation; generic names C$i follow the JuMP variable index order.
function fscip!(model, name)
    write_to_file(model, "raw/$name.lp"; generic_names = true)
    rm("raw/$name.sol"; force = true)
    run(`fscip ug_default.prm raw/$name.lp -fsol raw/$name.sol -l raw/$name.log -q`)
    vals = Dict{Int, Float64}()
    for line in readlines("raw/$name.sol")
        mt = match(r"^C(\d+)\s+(\S+)", line)
        mt === nothing || (vals[parse(Int, mt[1])] = parse(Float64, mt[2]))
    end
    return var -> get(vals, index(var).value, 0.0)   # SCIP omits zero values
end

# Extreme supported points of the (α, δ) frontier by dichotomic weighted-sum search.
# Ref: Aneja & Nair (1979), Management Science 25(1), 73–78.
# solve(f, stop_at) minimizes f; it may return an unverified solution once the restricted optimum reaches stop_at.
function supported_frontier(solve, master, α, δ)
    lexmin = (f1, f2) -> begin
        xv = solve(f1, Inf)
        cap = @constraint(master, f1 <= round(Int, value(xv, f1)))
        xv = solve(f2, Inf)
        delete(master, cap)
        (round(Int, value(xv, α)), round(Int, value(xv, δ)))
    end
    a = lexmin(α, δ)
    b = lexmin(δ, α)
    points = [a, b]
    segments = a == b ? Tuple{Tuple{Int, Int}, Tuple{Int, Int}}[] : [(a, b)]
    while !isempty(segments)
        l, r = pop!(segments)
        wα, wδ = l[2] - r[2], r[1] - l[1]
        line = wα * l[1] + wδ * l[2]
        xv = solve(wα * α + wδ * δ, line)
        mid = (round(Int, value(xv, α)), round(Int, value(xv, δ)))
        wα * mid[1] + wδ * mid[2] < line || continue
        push!(points, mid)
        push!(segments, (l, mid), (mid, r))
    end
    sort!(unique!(points))
    hull = Tuple{Int, Int}[]   # keep strict vertices of the lower-left convex hull
    for q in points
        while length(hull) >= 2 &&
              (hull[end][1] - hull[end-1][1]) * (q[2] - hull[end-1][2]) -
              (hull[end][2] - hull[end-1][2]) * (q[1] - hull[end-1][1]) <= 0
            pop!(hull)
        end
        push!(hull, q)
    end
    return hull
end