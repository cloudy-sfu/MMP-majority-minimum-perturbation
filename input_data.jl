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
    print("Enter party ID(s) to form the union (seperated by comma like \"1, 2, 3, 4\"): ")
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
    println("Union selected: ", P_names.party_name[U])
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
