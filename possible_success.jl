include("election_model.jl")

master = Model()
vp, cp, α, δ, x = add_votes!(master)
rules = add_rules!(master, vp, cp, nothing)
@constraint(master, sgn * rules.m >= Int(m0 <= 0))

frontier = supported_frontier(master, α, δ) do f, stop_at
    @objective(master, Min, f)
    xv = fscip!(master, "possible")
    xv
end

println(frontier)
jldsave("raw/frontier_possible.jld2"; frontier)