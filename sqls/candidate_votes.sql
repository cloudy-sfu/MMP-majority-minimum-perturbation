select electorate_id,
       party_id,
       votes
from candidate_votes_rnz_preliminary
order by electorate_id, party_id