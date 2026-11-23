using SQLite, DBInterface, DataFrames, CSV, JLD2, PrettyTables

# %% Input data.
sql_vp = read("sqls/party_votes.sql", String)
sql_cer = read("sqls/candidate_votes.sql", String)
sql_e_iota = read("sqls/n_independent_candidates_per_electorate.sql", String)
sql_P_names = read("sqls/party_names.sql", String)

db = SQLite.DB("main.sqlite")
vp = DataFrame(DBInterface.execute(db, sql_vp))
cer = DataFrame(DBInterface.execute(db, sql_cer))
E_iota = DataFrame(DBInterface.execute(db, sql_e_iota))
P_names = DataFrame(DBInterface.execute(db, sql_P_names))
DBInterface.close!(db)

# %% Constants.
N = 120

P = vp.party_id
v = vp.votes
nP = length(P)

E = E_iota.electorate_id
iota = E_iota.n
nE = length(E)

p_idx = Dict(id => i for (i, id) in enumerate(P))
e_idx = Dict(id => i for (i, id) in enumerate(E))

c = [Int[] for _ in 1:nE]
R = [Int[] for _ in 1:nE]
for row in eachrow(cer)
    e = e_idx[row.electorate_id]
    push!(c[e], row.votes)
    push!(R[e], ismissing(row.party_id) ? 0 : p_idx[row.party_id])
end

# %% User input union.
println("Party ID list:")
pretty_table(P_names; fit_table_in_display_vertically = false)

while true
    print("Enter party ID(s) to form the union (seperated by comma, semi-colon, or space): ")
    raw = strip(readline())

    if isempty(raw)
        println("Invalid format: enter at least one party ID.")
        continue
    end

    tokens = split(raw, r"[,;\s]+")
    parsed = tryparse.(Int, tokens)

    if any(isnothing, raw)
        bad_tokens = tokens[isnothing.(parsed)]
        println(
            "Invalid format: could not parse as integer party ID(s): ",
            join(bad_tokens, ", ")
        )
        continue
    end

    party_ids = [id::Int for id in parsed]
    unknown_ids = sort!(collect(setdiff(party_ids, Set(P))))

    if !isempty(unknown_ids)
        println(
            "Party ID(s) not in the displayed party list: ",
            join(unknown_ids, ", ")
        )
        continue
    end

    # Convert original party IDs to the indices used by the model arrays.
    global U = sort!(unique([p_idx[id] for id in party_ids]))
    println("Union selected: ", P[U])
    break
end

# %% Calc. constant.
union_party_ids = Set(P[U])
parliament_seats = CSV.read("results/parliament_seats_preliminary.csv", DataFrame)
mask = in.(parliament_seats.party_id, Ref(union_party_ids))
union_seats = sum(parliament_seats.parliament_seats[mask])

m0 = 2 * union_seats - sum(parliament_seats.parliament_seats)

# %% Export.
jldsave(
    "raw/model_data.jld2"; 
    E, nE, P, nP, v, c, R, U,  # Input data
    iota, N, m0  # Constant
)

# %% JLD2 data-format contract for the model.
#
# Indexing convention:
#   All model-array indices are 1-based Julia positions, not database IDs.
#
# Party data:
#   P::Vector{Int64} (or Vector{Int}) contains database party IDs. These are
#   labels only; the mathematical model must not use their values as indices.
#   Use p = 1:nP to index party data.
#   v[p] is the baseline party-vote count for the p-th party in P.
#   Thus, v[j] corresponds to P[j].
#
# Electorate data:
#   E::Vector{String} contains database electorate IDs. These are labels only;
#   the mathematical model must not use their values as indices.
#   Use e = 1:nE to index electorate data.
#   The j-th electorate in E corresponds to c[j], R[j], and iota[j].
#
# Candidate-vote data:
#   c::Vector{Vector{Int64}} stores candidate-option vote counts by electorate.
#   R::Vector{Vector{Int64}} stores the corresponding option labels.
#   For every e and k, c[e][k] and R[e][k] describe the same option.
#   The position k is the correspondence between these arrays; do not assume
#   candidate options are identified by their vote counts.
#
#   Values in R[e] are party-array indices, not party database IDs:
#     - R[e][k] in 1:nP identifies the corresponding position in P.
#     - R[e][k] == 0 identifies an independent candidate option.
#   Repeated 0 values are allowed: each occurrence represents a separate
#   independent option. Do not deduplicate R[e] or use its values as unique
#   candidate identifiers. R[e] is sorted as supplied, with c[e] aligned to it.
#
# Union:
#   U::Vector{Int64} (or Vector{Int}) contains indices into P, not party IDs.
#   For example, U == [1, 5, 6] selects P[1], P[5], and P[6].
#
# Dimensions:
#   nP == length(P) == length(v)
#   nE == length(E) == length(c) == length(R) == length(iota)
#
# Constant:
#   N is the baseline parliament size; m0 is the baseline union majority margin.
