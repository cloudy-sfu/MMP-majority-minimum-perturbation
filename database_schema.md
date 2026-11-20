# Database schema

`*_rnz`: Data source from RNZ https://www.rnz.co.nz/news/election-2026-results

`*_preliminary`: Preliminary results (2026-11-07 https://vote.nz/2026-general-election/about/overview/key-dates)



Table `parties_rnz`: All registered parties.

| Column name            | Data type | Description                               |
| ---------------------- | --------- | ----------------------------------------- |
| partyId                | integer   | Party ID assigned by RNZ.                 |
| party_displayName      | text      | Party name.                               |
| party_shortDisplayName | text      | Abbreviation of party name, named by RNZ. |
| party_colour           | text      | Color of the party in RNZ website.        |

Table `electorates_rnz_preliminary`: All electorates.

| Column name | Data type | Description                                                  |
| ----------- | --------- | ------------------------------------------------------------ |
| slug        | text      | Electorate ID, part of URL to voting results page in RNZ website. |
| name        | text      | Electorate name.                                             |
| isMaori     | integer   | 0: general electorate; 1: Māori electorate.                  |

Table `candidate_votes_rnz_preliminary`:  Results of candidate votes.

| Column name   | Data type | Description                                                  |
| ------------- | --------- | ------------------------------------------------------------ |
| electorate_id | text      | Refer to `slug` column in `electorates_rnz_preliminary` table. |
| candidate_id  | integer   | Candidate ID assigned by RNZ.                                |
| candidateName | text      | Candidate name.                                              |
| party_id      | integer   | The party of the candidate. Null if the candidate is independent.<br />Meaning of party ID refers to `partyId` column in `parties_rnz` table. |
| votes         | integer   | Number of votes the candidate gets in this electorate.       |

Table `party_votes_rnz_preliminary`: Results of party votes.

| Column name   | Data type | Description                                                  |
| ------------- | --------- | ------------------------------------------------------------ |
| electorate_id | text      | Refer to `slug` column in `electorates_rnz_preliminary` table. |
| partyId       | integer   | Refer to `partyId` column in `parties_rnz` table.            |
| votes         | integer   | Number of votes the party gets in this electorate.           |

