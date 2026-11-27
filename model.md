# Minimum votes modification for a parliamentary majority change



This optimizations model solves how many added or transferred votes would lead to changes in parliamentary majority. The model starts from an existed voting results (usually preliminary results) and a given union of party.

If the union is currently the strict majority (excluding hung parliament), the target is minimum changes of votes making them losing the strict majority; otherwise, the target is to make them gaining the strict majority.

>[!note]
>
>We consider party votes and candidate votes are independent (no corresponding relationship).

>   [!note]
>
>   We assume independent members of parliament are always opposite to the selected union. The union cannot include independent members of parliament.

The primary outputs are two separate Pareto frontiers of votes modification that changes the majority status. Because official tie breaking algorithm has randomness, the possible-success frontier records non-dominated results under at least one admissible tie breaking outcome, and the guaranteed-success frontier records non-dominated results under every admissible tie breaking outcome.

## Election rules

New Zealand uses [Mixed Member Proportional](https://elections.nz/democracy-in-nz/what-is-new-zealands-system-of-government/what-is-mmp) rule to forms the parliament. 

There are two types of ballots, party ballots and candidate ballots. Before the election, the list of candidate parties is fixed. Each valid party ballot should vote exactly one party.

>   [!note]
>
>   In the election, each voter can commit a ballot including a party vote and a candidate vote. When one vote in the ballot is invalid, the other vote can still be valid if it clearly expresses the intention. The two votes actually have correlation, but analyzing them correspondingly would introduce complexity about partially valid votes. To avoid such complexity, we assume the party vote and candidate vote are from two independent ballots.

There are 71 electorates.

>   [!note]
>
>   This model doesn't distinguish the difference between the 64 general electorates and 7 Māori electorates. In reality, non-Māori voters can only vote in general electorates, and Māori can choose to join either general or Māori electorate (exactly one of them).

Each candidate ballot belongs to exactly one electorate. Before the election, the list of candidates in this electorate is fixed. Each candidate represents to no more than one party. If any candidate doesn't represent any party, they is independent candidate. The candidate who gets the most votes is the winner of the electorate. If multiple candidates get the same number of votes, the election office draws one of them randomly. We define a party wins an electorate if and only if the winner candidate of the electorate represents this party.

Two seats allocation rules are executed in parallel:

| Allocated seats    | Definition                                                   | Process                                                      |
| ------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Electorate seats   | Parliament seats to be allocated to each party from electorate winners. | The winner of each electorate gets 1 parliament seat for their party, and the winner themselves become parliament members. |
| Proportional seats | Parliament seats to be allocated to each party by proportion of party ballots. | The baseline of parliament size is 120. First, all independent candidates as the winner of their electorates directly have a parliament seat. Then, the remaining seats (less than or equal to 120) are allocated to eligible parties. To be eligible, a party should get at least 5% of all party ballots, or is the winner of at least 1 electorate. Seats allocation is processed by Sainte-Laguë highest-average method, based on the number of party ballots among all eligible parties. If quotients of multiple party are the same when allocating the last seat in Sainte-Laguë process, the election office draws one of them randomly. The party will list party members to become parliament members for these seats. |

Tie happens in two cases:

1.   When multiple candidates have the same number of votes in an electorate.
2.   When multiple quotients in Sainte-Laguë process are equal.

The official tie-breaking algorithm is random drawing.

>   [!note]
>
>   The eligibility "at least 5% of all party ballots" is based on all valid party votes nationwide, including valid votes for parties that ultimately fail to qualify, as a whole.
>
>   When allocating parliament seats, however, proportions are based on only valid party votes for eligible parties, excluding votes for non-eligible parties, as a whole. The situation that no party is eligible is not defined.

Overall, the number of parliament seats for a party equals to the maximum of the two rules. The electorate winners are prior to other party members to become parliament members. Therefore, if the number of electorates that a party wins is more than the number of parliament seats, overhanging happens, where the number of parliament seats is more than 120. Overhang does not reduce other parties’ allocations. In this case, they cannot list party members other than electorate winners to become parliament members.

## Input data

Every electorate candidate is either independent or affiliated with exactly 1 party. Each party contests each electorate at most once.

Let "electorate ballot option" be parties or independent labels, therefore we eliminate the concept of candidate. For a candidate option who represent a party, the "ballot option" is that party. For an independent candidate option, the "ballot option" is a dummy party where this independent candidate is the only member.

| Symbol   | Meaning                                                      |
| -------- | ------------------------------------------------------------ |
| $E$      | Set of electorates.                                          |
| $P$      | Set of parties.                                              |
| $R_e$    | Set of all ballot options in electorate $e \in E$.           |
| $v(p)$   | Baseline national party votes for party $p\in P$.            |
| $c(e,r)$ | Baseline electorate votes for ballot option $r\in R_e$ in electorate $e \in E$. |
| $U$      | A selected union of parties $U \subset P$, for sensitivity analysis of changing status of strict majority parliament seats. |

## Constants

Let $I_e = R_e \setminus  P$, the set of independent ballot options in electorate $e \in E$.

Let $\iota_e = |I_e|$, the number of independent electorate candidates (integer) in electorate $e \in E$.

Let $m_0$ be the union’s majority margin in the fixed baseline result, where $m_0 > 0$ means the union currently holds a strict majority, so the objective is to lose it, and $m_0\le0$ means it does not, so the objective is to gain one.

Let $N = 120$ be initial parliament size before calculating overhanging.

## Decision variables

The baseline vote totals $v(p)$ and $c(e,r)$ represent a fixed reference count, such as preliminary election results. From preliminary to official results, New Zealand’s official count includes checking and counting special votes and counting ordinary votes again. 

-   Additional votes can represent previously uncounted ballots entering the totals, particularly validated special votes; these are additions to the reference count, not newly cast ballots. 
-   Transferred votes can represent corrections that reassign ballots previously credited to one party or candidate to another following checking or recounting, not voters changing their choices after voting. A judicial recount can lead to an amended result declaration.

Both operations can be interpreted as hypothetical changes for sensitivity analysis, measuring how many added or transferred ballots would be needed to change the union’s majority status.

For each party $p\in P$, define non-negative integer variables

| Symbol | Meaning                                 |
| ------ | --------------------------------------- |
| $A(p)$ | Added party ballots for $p$.            |
| $J(p)$ | Transferred party ballots into $p$.     |
| $K(p)$ | Transferred party ballots out from $p$. |

For each electorate $e\in E$ and ballot option $r\in R_e$, define non-negative integer variables

| Symbol   | Meaning                                     |
| -------- | ------------------------------------------- |
| $A(e,r)$ | Added candidate ballots for $r$.            |
| $J(e,r)$ | Transferred candidate ballots into $r$.     |
| $K(e,r)$ | Transferred candidate ballots out from $r$. |

## Derived variables and constraints

### Votes modification

Final party votes for any party are
$$
v'(p)=v(p)+A(p)+J(p)-K(p),\quad p\in P
$$
Final candidate votes for each candidate in each electorate are
$$
c'(e,r)=c(e,r)+A(e,r)+J(e,r)-K(e,r), \quad e\in E,\ r\in R_e
$$
Total added ballots are
$$
\alpha= \sum_{p\in P}A(p) + \sum_{e\in E}\sum_{r\in R_e}A(e,r)
$$
Total transferred ballots are
$$
\delta=\sum_{p\in P}K(p)+\sum_{e\in E}\sum_{r\in R_e}K(e,r)
$$
Each transfer counts once in $\delta$. Incoming and outgoing totals describe the same transferred ballots and must not both be counted.

Party ballots and candidate ballots remain separate modification units. Changing both votes associated with one voter therefore counts as two modifications.

Total valid party ballots are
$$
V=\sum_{p\in P}v'(p)
$$

Transfers must balance within each ballot pool.
$$
\sum_{p\in P}J(p)=\sum_{p\in P}K(p) \\
\sum_{r\in R_e}J(e,r)=\sum_{r\in R_e}K(e,r),\quad e\in E
$$
Transferred-in ballots and newly added ballots cannot fund further transfers. Each original ballot is transferred at most once.
$$
K(p)\le v(p), \quad p\in P \\
K(e,r)\le c(e,r), \quad e\in E,\ r\in R_e
$$
The aggregate total transferred ballots must be realized by transfers between distinct options
$$
J(p)+K(p) \le \sum_{q\in P}K(q), \quad p\in P \\
J(e,r)+K(e,r) \le \sum_{s\in R_e}K(e,s), \quad e\in E,\ r\in R_e
$$

>   [!note]
>
>   Because
>   $$
>   J(p)+K(p) \le \sum_{q\in P}K(q) \Leftrightarrow J(p)\le\sum_{q\in P\setminus\{p\}}K(q)
>   $$

>   [!note]
>
>   Final votes must be non-negative
>   $$
>   v'(p)\ge 0, \quad p\in P \\
>   c'(e,r)\ge 0, \quad e\in E,\ r\in R_e
>   $$
>   These constraints are not necessary, because they're satisfied anyway
>   $$
>   v'(p) = v(p)+A(p)+J(p)-K(p) \\
>   K(p)\le v(p) \\
>   \implies
>   v'(p) = \underbrace{v(p)-K(p)}_{\ge0} + \underbrace{A(p)}_{\ge0} + \underbrace{J(p)}_{\ge0} \ge 0
>   $$
>   Similar things happen to $c'(e, r)$.

### Tie breaking

There are two definition of tie breaking without randomness.

-   Possible success: At least one admissible tie resolution achieves the selected majority change for the modification plan.
-   Guaranteed success: Every admissible tie resolution achieves the selected majority change for the same modification plan.

Let $\eta(\cdot)$ be tie-priority settings.

For an electorate $e \in E$ and two distinct ballot options $r, s \in R_e$, let
$$
\eta(e, r, s) = \begin{cases}
1, \quad \text{if~} s \text{~has priority over~} r \\
0, \quad \text{otherwise}
\end{cases}
$$
For two distinct parties $p, q \in P$, let
$$
\eta(p, q) = \begin{cases}
1, \quad \text{if~} q \text{~has priority over~} p \\
0, \quad \text{otherwise}
\end{cases}
$$
Let $\mathcal H$ be the set of all complete tie-priority settings obtained by combining the possible electorate orders and party orders. The pairwise values come from those orders. Reverse comparisons have complementary values, and cyclic priorities are not allowed. The set $\mathcal H$ is defined independently of the votes modification. Modified votes determine whether a priority comparison matters, not which settings are in $\mathcal H$.

### Electorate seats

Let $w(e,r)\in\{0,1\}, e\in E,\ r\in R_e$  indicate that ballot option $r$ wins electorate $e$.

The number of electorate seats is
$$
d(p) = \sum_{e \in E, \\ p \in R_e} w(e, p), \quad p \in P
$$
Parliament seats held by independent candidates are
$$
n = \sum_{e \in E} \sum_{r \in I_e} w(e, r)
$$
Because every electorate has exactly one winner, there is
$$
n+\sum_{p\in P}d(p)=|E|
$$
Each electorate has exactly one winner
$$
\sum_{r\in R_e}w(e,r)=1, \quad e\in E
$$
A winner must defeat every other ballot option by final votes, using the fixed electorate priority only at equality. For each electorate $e$ and each pair of distinct options $r$ and $s$ in $R_e$, there is
$$
w(e, r) = 1 \implies c'(e,r) - c'(e,s) \ge \eta(e, r, s), \quad s\in R_e \setminus \{r\}
$$

### Proportional seats

Proportional seats are allocated to eligible parties only. The eligibility is defined as follows.

Let $h(p)\in\{0,1\}$ indicate that party $p \in P$ reaches the 5% threshold, therefore
$$
h(p) = \mathbb{1}[20 \cdot v'(p)-V \ge 0]
$$

>   [!note]
>
>   $\mathbb{1}[\cdot]$ denotes the indicator function.

Let $u(p)\in\{0,1\}$ indicate that party $p \in P$ wins at least one electorate, therefore
$$
u(p)\le d(p)\le |E| u(p)
$$
Let $g(p)\in\{0,1\}$ indicate that party $p \in P$ qualifies for proportional allocation, therefore
$$
g(p)\ge h(p) \\
g(p)\ge u(p) \\
g(p)\le h(p)+ u(p)
$$

### Sainte-Laguë method

Let $z(p,k)\in\{0,1\}, p\in P, k=1,\dots,N$ indicate that quotient $v'(p) \over 2k-1$ is allocated a proportional seat.

Only eligible parties participates in the allocation
$$
z(p,k)\le g(p), \quad p\in P, ~k=1,...,N
$$
Let $y(p, k)$ indicate that party $p \in P$ is eligible but quotient $v'(p) \over 2k-1$ is NOT allocated a proportional seat, therefore
$$
y(p,k) = g(p) - z(p,k), \quad p\in P, ~k=1,...,N
$$
For a specific party $p \in P$, the quotients are indexed in order ($k = 1, ..., N$), therefore seats are allocated from the first, continuously, in order. If the previous quotient is not allocated a seat, the subsequent quotient is impossible to be allocated a seat.
$$
z(p,k+1)\le z(p,k), \quad p\in P, ~k=1,...,N-1
$$
The number of proportional seats is
$$
B=N-n
$$
All the proportional seats are exactly allocated
$$
\sum_{p\in P}\sum_{k=1}^{N}z(p,k)=B
$$
The number of proportional seats each party is allocated is
$$
s(p)=\sum_{k=1}^{N}z(p,k) \quad p \in P
$$
Let $\phi(p) \in \{0, 1\}, p \in P$ be a tie-breaking flag. If quotient ${v'(p) \over 2k-1} = \theta$, party $p$ is allocated a seat if and only if $\phi(p) = 1$.

There is $\phi(q) \ge \phi(p)$ for all distinct $p, q \in P$ with $\eta(p, q) = 1$. 
$$
\varphi(q) \ge \varphi(p) + \eta(p,q) - 1, \quad p,q\in P, p\ne q
$$
Let $\theta \ge 0$ be the threshold of Sainte-Laguë quotient. If the quotient is larger than $\theta$, the corresponding party is allocated a seat. If the quotient equals to $\theta$, whether the corresponding party is allocated a seat depends on tie-priority.

Let $\gamma = {1 \over 2N-1}$ be the strictness gap of the Sainte-Laguë threshold.

The corresponding party is allocated a seat if and only if the quotient larger or equal to threshold $\theta$. Only when the party has priority to the threshold $\phi(\cdot) = 1$, the quotient can be equal to the threshold.
$$
z(p,k)=1 \implies v'(p) - (2k-1)\theta \ge \gamma\,(1-\varphi(p)) \\
y(p,k)=1 \implies v'(p) - (2k-1)\theta \le -\gamma\,\varphi(p)
$$


>   [!note]
>
>   A selected quotient must be larger than or equal to every unselected quotient
>   $$
>   z(p,k)=1 \and z(q,j)=0 \and g(q)=1 \\
>   p,q\in P, \quad p\ne q, \quad k,j=1,...,N \\
>   \implies \begin{cases}
>   \frac{v'(p)}{2k-1} \ge \frac{v'(q)}{2j-1}, \quad \text{if~} \eta(p, q) = 0  \\
>   \frac{v'(p)}{2k-1} > \frac{v'(q)}{2j-1}, \quad \text{if~} \eta(p, q) = 1  \\
>   \end{cases} \\
>   \overset{\text{linearity}}{\implies} (2j-1) v'(p)  - (2k-1) v'(q) \ge \eta(p, q)
>   $$
>   The currently used constraint is better than pairwise for every allocated $(p,k)$ and unallocated eligible $(q,j)$, using $2|P|N$ instead of $|P|^2N^2$ conditional constraints.
>
>   Set $\theta$ equal to the last allocated quotient $\theta=v'(q)/(2j-1)$, and set $\varphi(p)=1$ for parties with priority at least as high as $q$ (including $q$).
>
>   Start with the original quotient $Q_{p,k}={v'(p)\over 2k-1}$. Subtracting the threshold gives
>   $$
>   \begin{aligned}
>   Q_{p,k}- \theta & = \frac{v'(p)}{2k-1}-\frac{v'(q)}{2j-1} \\
>   & = \frac{(2j-1)v'(p)-(2k-1)v'(q)}{(2k-1)(2j-1)}
>   \end{aligned} \\
>   p,q\in P, \quad p\ne q, \quad k,j=1,...,N 
>   $$
>   The original Sainte-Laguë comparison is between $Q_{p,k}={v'(p) \over 2k-1}$ and the threshold $\theta$. To see how that comparison becomes the expression in the constraints, multiply the difference by $2k-1$.
>   $$
>   \begin{aligned}
>   (2k-1)(Q_{p,k}-\theta)
>   &= (2k-1)\left(\frac{v'(p)}{2k-1}-\theta\right)\\
>   &= v'(p)-(2k-1)\theta
>   \end{aligned}
>   $$
>   Since $2k-1>0$, this does not change the sign. The expression in the constraints is positive when the quotient is above the cutoff, zero when it is tied, and negative when it is below the threshold.
>
>   If not $v'(p) = v'(q)$, the difference is at least 1, so the quotient satisfies
>   $$
>   v'(p)-(2k-1)\theta \ge {1 \over 2j-1} \ge {1 \over 2N-1} = \gamma
>   $$
>   Proof:
>
>   Let two quotient of party $p, q$ both equal $\theta$, and $q$ has priority over $p$ with $\eta(p, q) = 1$.  If party $p$ is allocated a seat while $q$ isn't. The constraint would lead to
>   $$
>   z(p,k) = 1, {v'(p) \over 2k-1} = \theta \Rightarrow \phi(p) = 1 \\
>   y(q,k) = 1, {v'(q) \over 2j-1} = \theta \Rightarrow \phi(p) = 0
>   $$
>   It would violate constraint $\phi(q) \ge \phi(p)$.
>
>   Therefore, party $p$ is forced to lose the seat and $q$ get this seat.

> [!note]
>
> Under New Zealand’s election rules, a party on the party ballot can qualify for proportional allocation by winning an electorate, even if it falls below the 5% party-vote threshold. In this model, party and electorate votes are modified independently, so the optimizer can reduce a party’s nationwide party vote to zero while it still wins an electorate. The party remains eligible and keeps the electorate seats it wins.
>
> If at least one eligible party has positive party votes, it supplies $N$ positive Sainte-Laguë quotients for at most $N$ seats. A zero-vote party’s quotients are all zero, so none reaches the cutoff. That party receives no proportional seats ($s(p)=0$), but keeps its electorate seats ($t(p)=d(p)$).
>
> A positive baseline party-vote total stays positive because transfers preserve the total and additions only increase it. But a positive total does not guarantee that any **eligible** party has positive votes: all party votes could belong to parties that neither reach 5% nor win an electorate. If seats remain to be allocated and the only eligible parties have zero votes, all their quotients tie at zero. The model’s single flag $\varphi(p)$ cannot select some but not all of a party’s equal quotients, so the formulation does not handle that case in general. This situation cannot happen when $|P| \le 20$.

### Parliament seats

The number of parliament seats of each party is
$$
t(p)=\max\{s(p),d(p)\}, \quad p \in P
$$
Total parliament size is
$$
H=n+\sum_{p\in P}t(p)
$$
The number of parliament seats of union $U$ is
$$
S = \sum_{p\in U}t(p)
$$
The strict majority margin is
$$
m=2S-H
$$

## Objective

The baseline margin $m_0$ is an constant. The combination of given $x = (A, J, K)$ and $\eta \in \mathcal{H}$ will determine $m$.

The success condition (of majority change) is
$$
\begin{cases}
m \ge 1, \quad \text{if~} m_0 \le 0 \\
m \le 0, \quad \text{if~} m_0 > 0
\end{cases}
$$
Let $F(\eta), \eta \in \mathcal{H}$ be the feasible set of votes modification $x$ and satisfied the success condition under given $\eta$.

Let $\underline{F}$ be the feasible set of "possible success", $\overline{F}$ be that of "guaranteed success".
$$
\underline{F} = \bigcup_{\eta \in \mathcal{H}} F(\eta) \\
\overline{F} = \bigcap_{\eta \in \mathcal{H}} F(\eta)
$$
The objective is bi-objective optimization
$$
\min_{\text{Pareto}} (\alpha, \delta)
$$
where the Pareto frontier is defined as the extreme supported points: the vertices of the lower-left convex hull of all achievable $(\alpha, \delta)$. Points on a hull edge between two vertices, such as $(\alpha+1, \delta-1)$ on a segment of slope -1, and points strictly inside the hull are excluded.

Use the same objective in two models: possible success model requires $x \in \underline{F}$, and guaranteed success model requires $x \in \overline{F}$.

Denote this optimization problem as unrestricted master problem.

## Solving method

### Possible success

Let the value of any $\eta$  in constraints be 0, then solve the unrestricted master problem. Then $\varphi$ is unconstrained, so every tie resolution is admissible; equivalently $\gamma = 0$ and $\varphi$ is omitted.

### Guaranteed success

Define mutable $\mathcal{S} \subseteq \mathcal{H}$.

Denote restricted master problem as an optimization model, where $\displaystyle \min_{\text{Lex}} (\alpha, \delta)$ is the objective function, $x$ is fixed and feasible $\forall \eta \in \mathcal{S}$.

>   [!note]
>
>   Lexicographical minimization $\displaystyle \min_{\text{Lex}} (\alpha, \delta)$  is defined as follows.
>
>   First, reduce $\displaystyle \min_{\text{Lex}} (\alpha, \delta)$ to single objective $\min \alpha$, where $\delta$ is free. Let $\alpha^*$ be optimal solution of reduced objective.
>
>   Then, optimize $\min \delta \text{~s.t.~} \alpha = \alpha^*$ under the same constraints.
>
>   Therefore, the optimal solution of $\displaystyle \min_{\text{Lex}} (\alpha, \delta)$ is $(\alpha^*, \delta^*)$.

>   [!note]
>
>   The restricted master problem is equivalent to unrestricted master problem when $\mathcal{S} = \mathcal{H}$.

Let $x^*$ be the optimal solution of restricted master problem. Let $m(x^*, \eta)$ be the margin obtained by applying the election rules to $x^*$ and $\forall \eta \in \mathcal{H}$.

The worst case strict majority margin is
$$
\begin{cases}
\displaystyle \min_{\eta \in \mathcal{H}} m(x^*, \eta), \quad m_0 \le 0 \\
\displaystyle \max_{\eta \in \mathcal{H}} m(x^*, \eta), \quad m_0 > 0
\end{cases}
$$
Denote adversarial oracle as an optimization model, where worst case strict majority margin is the objective function, $x^*$ is given and fixed. It is equivalent to the possible-success constraint set where $\forall \eta(\cdot) = 0$ with $x = x^*$.

The guaranteed success implies
$$
\begin{cases}
\left[ \displaystyle \min_{\eta \in \mathcal{H}} m(x^*, \eta) \right] \ge 1, \quad m_0 \le 0 \\
\left[ \displaystyle \max_{\eta \in \mathcal{H}} m(x^*, \eta) \right] \le 0, \quad m_0 > 0
\end{cases}
$$

>   [!note]
>
>   The Pareto frontier is solved by dichotomic weighted-sum search.
>
>   First solve $\displaystyle \min_{\text{Lex}} (\alpha, \delta)$ and $\displaystyle \min_{\text{Lex}} (\delta, \alpha)$, giving the two terminal points. If they differ, let the queue $\mathcal Q$ contain this pair.
>
>   Then, take a pair $(\alpha_\text{L}, \delta_\text{L}), (\alpha_\text{R}, \delta_\text{R}), \alpha_\text{L} < \alpha_\text{R}$. Let $\omega_\alpha = \delta_\text{L} - \delta_\text{R}, \omega_\delta = \alpha_\text{R} - \alpha_\text{L}$ and solve
>   $$
>   \min\ \omega_\alpha \alpha + \omega_\delta \delta
>   $$
>   If the optimum $(\alpha_\text{M}, \delta_\text{M})$ satisfies $\omega_\alpha \alpha_\text{M} + \omega_\delta \delta_\text{M} < \omega_\alpha \alpha_\text{L} + \omega_\delta \delta_\text{L}$, it is a new supported point, and both pairs $(\alpha_\text{L}, \delta_\text{L}), (\alpha_\text{M}, \delta_\text{M})$ and $(\alpha_\text{M}, \delta_\text{M}), (\alpha_\text{R}, \delta_\text{R})$ are added to $\mathcal Q$. Otherwise, no extreme supported point lies between $(\alpha_\text{L}, \delta_\text{L})$ and $(\alpha_\text{R}, \delta_\text{R})$.
>
>   Finally, remove points that are not strict vertices of the lower-left convex hull.

The solving process of unrestricted master problem under guaranteed success is as follows.

Initially, let $\mathcal{S} = \{ \eta_\text{Lex} \}$, where $\eta_\text{Lex}$ means party $q$ has priority over $p$ if and only if party ID of $q$ is larger than $p$, for both Sainte-Laguë process and electorate winner $\forall e \in E$.

For each iteration in lexicographical minimization process of restricted master problem,

-   For scenario generation loop,
    -   Solve this single objective restricted master problem and get $x^*$.
    -   Solve adversarial oracle for this $x^*$.
    -   If adversarial oracle find $\eta_0$ which makes objective of restricted master problem violates the guaranteed success implication, 
        -   Add $\eta_0$ to $\mathcal{S}$. (It updates restricted master problem for next iteration.)
    -   Otherwise, 
        -   $x^*$ is a Pareto point in Pareto frontier of unrestricted master problem in guaranteed success case.
        -   Break scenario generation loop.

