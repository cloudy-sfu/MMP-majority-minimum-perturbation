using SCIP
include("election_model.jl")

master = Model()
vp, cp, α, δ, x = add_votes!(master)
# η_Lex: larger party ID has priority; data sorted by party ID, independents (R = 0) first
rules = add_rules!(master, vp, cp, (collect(nP:-1:1), [collect(length(R[e]):-1:1) for e in 1:nE]))
@constraint(master, sgn * rules.m >= Int(m0 <= 0))

# Adversarial oracle: η ≡ 0 relaxation with x fixed, worst-case margin
oracle = Model(SCIP.Optimizer)
set_silent(oracle)
ovp, ocp, _, _, ox = add_votes!(oracle)
orules = add_rules!(oracle, ovp, ocp, nothing)
@objective(oracle, Min, sgn * orules.m)

frontier = supported_frontier(master, α, δ) do f, stop_at
    @objective(master, Min, f)
    while true
        xv = fscip!(master, "guaranteed")
        round(Int, value(xv, f)) >= stop_at && return xv   # relaxation bound: no new extreme point
        fix.(ox, round.(Int, xv.(x)); force = true)
        optimize!(oracle)
        vpv = round.(Int, value.(ovp))
        sv = round.(Int, value.(orules.s))
        gv = round.(Int, value.(orules.g))
        round(Int, objective_value(oracle)) >= Int(m0 <= 0) && return xv
        # η0 consistent with the oracle's tie resolutions
        θs = minimum(vpv[p] // (2sv[p] - 1) for p in 1:nP if sv[p] >= 1)
        tier = [sv[p] >= 1 && vpv[p] // (2sv[p] - 1) == θs ? 1 :
                gv[p] == 1 && vpv[p] // (2sv[p] + 1) == θs ? 3 : 2 for p in 1:nP]
        wk = [argmax(value.(orules.w[e])) for e in 1:nE]
        r0 = add_rules!(master, vp, cp,
                        (invperm(sortperm(tier)), [invperm([wk[e]; setdiff(eachindex(R[e]), wk[e])]) for e in 1:nE]))
        @constraint(master, sgn * r0.m >= Int(m0 <= 0))
        println("scenario added")
    end
end

println(frontier)
jldsave("raw/frontier_guaranteed.jld2"; frontier)