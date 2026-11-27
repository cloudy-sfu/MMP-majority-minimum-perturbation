# Bad practice of code generation

This document lists bad practice of code generation, which LLM should avoid. It is general for any programming language, not only Python. When LLM sees this, the scripts to work on is for research purpose instead of industrial product. Therefore, defensive code or redundant edge case handling is not necessary.

## Unnecessary helper function

For example, the result of an algorithm is close to integers, such as 0.9999999 in normal case, but LLM wants to guarantee the algorithm is correct and not generating non-integer values like 0.98. The requirement of algorithm is to output an integer.

Bad practice:

```python
def make_integer(value: float):
    y = round(value)
    eps = abs(value - y)
    if eps > 1e-5:
        raise Exception(f"{value} is expected to be integer, but not.")
    return y

b = make_integer(a)  # used everywhere in the algorithm
```

Good practice:

```python
b = round(a)
```

Reason:

If the algorithm is designed to return integers and is numerically accurate enough that floating-point errors cannot change which integer is nearest, `round(a)` is sufficient. Under those assumptions, a result such as 0.98 when 1 is expected should be investigated as a possible implementation or numerical accuracy problem, not handled as a routine edge case.

The `make_integer` helper does not fix such a problem; it only raises an exception and stops the computation. If closeness to an integer is an invariant worth checking, test it with a tolerance justified by the algorithm’s numerical accuracy rather than wrapping every call to `round()`.

## Embedded function

Bad practice:

```python
def build_model(t):
    model = OptimizationProblem(t)  # define the structure of model
    model.add(Objective)
    model.add(Constraint)
    return model

def solve(x):
    if x.p == 0:
	    model = build_model(0)
    else:
        model = build_model(1)
    solution = x ** model.k  # call the solver to solve the model
    return solution

def process(input_data):
    y = []
    for i in range(n):
        y_i = solve(input_data[i])
        y.append(y_i)
    return y

if __name__ == "__main__":
    input_data = ...
    result = process(input_data)
```

Good practice:

```python
input_data = ...
result = []
for i in range(n):
    if input_data[i].p == 0:
    	model = OptimizationProblem(0)  # define the structure of model
    else:
        model = OptimizationProblem(1)
    model.add(Objective)
    model.add(Constraint)
    y = input_data[i] ** model.k
    result.append(y)
```

Reason:

Function `build_model` is used only inside `solve`, and `solve` is used only inside `process`, and `process` is only called once in main scope. The call stack is very linear (or have very simple branches). In this case, the structure should be flattened into a plain script, because the possibility of sub-module being expended or more modules to be added doesn't need to be considered.

There is only one reference of `solve`. Although it is called many times in the for-loop, the code only needs one copy. Therefore, `solve` shouldn't be defined anyway.

Although `build_model` has two reference, but it is used continuously in the same namespace (scope of `solve` function) and always only called once. Even if they are not continuously (have other code block between references), as long as the later reference doesn't depend on the result of former reference, they can be moved into adjacent lines. Therefore, the function can still be expanded into context, where if-else clause applies only on the key lines.

This guidance would make the script easier to understand. If human reads line by line, they're less frequently redirected. The generated code would be easier for human to review.

## Redundant constant

If a constant is only used once, and its meaning is very obvious, it should be used in line instead of defined seperately.

Bad practice:

```python
import pandas as pd
from pathlib import Path

input_file_path = Path("data/survey_results.csv")
input_file = pd.read_csv(input_file_path)
...  # Long scripts to calculate
output_file_path = input_file.with_suffix(".pkl")
results.to_pickle(output_file_path)
```

Good practice:

```python
import pandas as pd

input_file = pd.read_csv("data/survey_results.csv")
...  # Long scripts to calculate
results.to_pickle("data/survey_results.pkl")
```

Reason:

Unless specifically mentioned by the user, the script is in program's root folder. The script is for research purpose, therefore is always executed when the current folder is the program's root folder. Dynamic current folder or execution from other location is impossible. Therefore, simple relative path is enough to identify the file.

The input and output file path of this script is fixed, instead of dynamic user input. In the bad practice, LLM infers the input and output file have the same base name, therefore builds a dependency relationship between the two file names. It is unnecessary and overengineering. When human reviews this script, they are redirected one more time to find the real output file path. When human changes the input file path, they accidently cause the change of output file path. The relationship is true only when the user describes such correlation in the demand.