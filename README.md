# MMP majority minimum perturbation
Solve minimum vote perturbation for a parliamentary majority change under Mixed Member Proportional rules from preliminary results to official results

![](https://shields.io/badge/dependencies-Julia_1.13-purple)

## Install

Create and activate a Julia project environment.

## Usage

New Zealand election rules are [Mixed Member Proportional](https://en.wikipedia.org/wiki/Mixed-member_proportional_representation) rules from 1996. The preliminary results are announced on election day, while official results are published about 3 weeks later, considering special votes (additional votes which are not counted in preliminary results), removing duplicated and invalid votes, and re-counting if requested.

This math optimization problem is designed for sensitivity analysis on preliminary results, evaluating the minimum effort that an union of party needs, to change the status of whether is it the majority of parliament. It is an integer minimum perturbation problem about votes modification.

[Election rules and model definition](./model.pdf)



## Development

### Collect data: New Zealand 2026 election

The results are already included in `main.sqlite`. [Database schema](./database_schema.md) 

The scripts are only valid before official results of New Zealand 2026 election are declared.

Create and activate a Python 3.14 virtual environment.

Run the following command to install required PyPI packages.

```
pip install -r requirements.txt
```

Run the following command to collect data.

```
python get_electorates_list_rnz_preliminary.py
python get_parties_rnz.py
python get_votes_rnz_preliminary.py
```

