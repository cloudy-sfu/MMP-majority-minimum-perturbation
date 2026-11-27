# MMP majority minimum perturbation
Solve minimum vote perturbation for a parliamentary majority change under Mixed Member Proportional rules from preliminary results to official results

![](https://shields.io/badge/dependencies-Julia_1.13-purple)
![](https://shields.io/badge/dependencies-Python_3.14-blue)

## Install

Create and activate a Python virtual environment.

Run the following command.

```
pip install -r requirements.txt
```

Create and activate a Julia project environment.

## Usage

Voting results are saved in `main.sqlite`. [Database schema](./database_schema.md) 

### Parliament seats

To calculate parliament seats of each party based on preliminary results, run the following command.

```
python calc_parliament_seats_preliminary.py
```

The results are output to `results/parliament_seats_preliminary.csv`.

### Shapley-Shubik power index

To calculate Shapley-Shubik power index of each party, run the following command.

```
python calc_shapley_shubik_power_index.py
```

The results are output to `results/shapley_shubik_power_index.csv`.

### Sensitivity analysis

New Zealand election rules are [Mixed Member Proportional](https://en.wikipedia.org/wiki/Mixed-member_proportional_representation) rules from 1996. The preliminary results are announced on election day, while official results are published about 3 weeks later, considering special votes (additional votes which are not counted in preliminary results), removing duplicated and invalid votes, and re-counting if requested.

This math optimization problem is designed for sensitivity analysis on preliminary results, evaluating the minimum effort that an union of party needs, to change the status of whether is it the majority of parliament. It is an integer minimum perturbation problem about votes modification.

[Election rules and model definition](./model.pdf)

Run the following command.

```
python calc_parliament_seats_preliminary.py
julia input_data.jl
```

It starts an interactive session to select the union of parties to analyze.

