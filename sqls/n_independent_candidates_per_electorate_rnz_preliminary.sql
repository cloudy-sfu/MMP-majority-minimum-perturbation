select electorate_id, sum(party_id is null) as n
from candidate_votes_rnz_preliminary
group by electorate_id
