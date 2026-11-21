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
| Proportional seats | Parliament seats to be allocated to each party by proportion of party ballots. | The winner of each electorate gets 1 parliament seat for their party, and the winner themselves become parliament members. |
| Electorate seats   | Parliament seats to be allocated to each party from electorate winners. | The baseline of parliament size is 120. First, all independent candidates as the winner of their electorates directly have a parliament seat. Then, the remaining seats (less than or equal to 120) are allocated to eligible parties. To be eligible, a party should get at least 5% of all party ballots, or is the winner of at least 1 electorate. Seats allocation is processed by Sainte-Laguë highest-average method, based on the number of party ballots among all eligible parties. If quotients of multiple party are the same when allocating the last seat in Sainte-Laguë process, the election office draws one of them randomly. The party will list party members to become parliament members for these seats. |

Tie happens in two cases:

1.   When multiple candidates have the same number of votes in an electorate.
2.   When multiple quotients in Sainte-Laguë process are equal.

The official tie-breaking algorithm is random drawing.

>   [!note]
>
>   The eligibility "at least 5% of all party ballots" is based on all valid party votes nationwide, including valid votes for parties that ultimately fail to qualify, as a whole.
>
>   When allocating parliament seats, however, proportions are based on only valid party votes for eligible parties, excluding votes for non-eligible parties, as a whole.

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
>   v'(p)\ge0, \quad p\in P \\
>   c'(e,r)\ge0, \qquad e\in E,\ r\in R_e
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
A selected quotient must be larger than or equal to every unselected quotient
$$
z(p,k)=1 \and z(q,j)=0 \and g(q)=1 \\
p,q\in P, \quad p\ne q, \quad k,j=1,...,N \\
\implies \begin{cases}
\frac{v'(p)}{2k-1} \ge \frac{v'(q)}{2j-1}, \quad \text{if~} \eta(p, q) = 0  \\
\frac{v'(p)}{2k-1} > \frac{v'(q)}{2j-1}, \quad \text{if~} \eta(p, q) = 1  \\
\end{cases} \\
\overset{\text{linearity}}{\implies} (2j-1) v'(p)  - (2k-1) v'(q) \ge \eta(p, q)
$$

>   [!note]
>
>   $g(p) = 1$ is redundant, because $z(p,k) \le g(p)$, when $z(p, k) = 1$ there must be $g(p) = 1$.

The number of proportional seats each party is allocated is
$$
s(p)=\sum_{k=1}^{N}z(p,k) \quad p \in P
$$

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
\min (\alpha, \delta)
$$
Use the same objective in two models: possible success model requires $x \in \underline{F}$, and guaranteed success model requires $x \in \overline{F}$.

