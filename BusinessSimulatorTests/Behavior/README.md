# Behavioral Testing

## Purpose

Correctness tests verify that a function returns a specific expected result.
Behavioral tests serve a different purpose: they run the simulation many times
so we can observe its long-term behavior and decide whether the game is balanced
and behaves as intended.

These experiments will help answer questions such as:

- How does the 5% revenue standard deviation behave over 1,000 simulations?
- How does revenue change across a range of player prices?
- Is the freshness penalty large enough to matter over time?
- Do weather and freshness interact in a reasonable way?
- Does adding or removing one factor produce an understandable change?

Behavioral experiments do not initially need one exact correct output. Their
results will be summarized and evaluated subjectively. Once we understand the
desired ranges, some expectations may become automated statistical assertions.

## Experiment Design

Experiments should be defined as reusable scenarios. A scenario may specify:

- Number of simulation runs
- Product price
- Active dimensions or factors

The experiment runner should support two types of simulation:

1. Independent snapshots, where a fresh game state is created for each run.
2. Multi-day paths

Each factor should remain modular. For example, we should be able to compare
freshness alone, weather alone, freshness and weather together, or neither
without changing the implementation of those factors.

## Scope

The behavioral test suite should include experiments for every simulation
dimension, including:

- Demand
- Production capacity
- Market size
- Natural revenue variance with no other factors applied

It should also include experiments for individual gameplay factors. A factor
may affect more than one dimension, and each effect should be testable both in
isolation and in combination.

For example, a new oven might affect both demand and production capacity. We
should be able to run experiments that measure:

- The oven's effect on demand alone
- The oven's effect on production capacity alone
- The combined effect of the oven on demand and capacity

This allows us to understand which part of a factor produces each result and to
verify that its combined behavior remains balanced.

## Reproducible Randomness

The simulation currently generates revenue variance with random numbers. The
experiment system should eventually allow its random-number generator to be
injected and seeded.

Scenarios being compared should use the same random-number sequence. This keeps
the comparison fair: differences in results should come from the factor being
tested rather than one scenario randomly receiving more favorable days.

## Results

Experiments should summarize their runs rather than print every individual
simulation. Useful results may include:

- Average and median sales
- Average and median revenue
- Standard deviation
- Minimum and maximum
- Percentiles
- Absolute and percentage differences from a baseline scenario

Results should make it easy to compare prices and factor combinations in a
table. Exporting results to CSV may also be useful later.

### Future Visualizations

The experiment runner should produce structured results that can later be
passed to a separate visualization layer. Possible visualizations include:

- Price versus average revenue curves
- Freshness versus sales
- Revenue distributions
- Multi-day revenue trends
- Side-by-side factor comparisons
- Heat maps for combinations such as price and weather

Visualization should remain separate from experiment execution so charts and
reporting tools can change without affecting the simulation tests.

These longer-running experiments should remain separate from the normal unit
test suite so correctness tests stay fast.

## Timing

Behavioral-test infrastructure is intentionally postponed while enough of the
UI is built to determine whether the core game experience is viable. It should
not be postponed indefinitely.

The planned checkpoint is:

1. Finish and commit product freshness.
2. Build enough UI to evaluate the core gameplay loop.
3. Confirm that the game concept and interface are worth continuing.
4. Build the behavioral experiment runner before adding many more simulation
   factors.
5. Use the runner to establish pricing and freshness baselines before balancing
   weather and other future dimensions.
