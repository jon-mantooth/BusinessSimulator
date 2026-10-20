# Business Reporting Decisions

## Initial Design Goal

The first version of business reporting will prioritize metrics that meet all three of these criteria:

1. **Easy to collect:** The metric already exists in saved game data or can be derived reliably from existing daily summaries and business state without introducing a large new data-collection system.
2. **Easy to visualize:** The player can understand the metric quickly through a compact value, comparison, trend, or chart.
3. **Useful for decisions:** The metric helps the player identify a problem or choose a concrete adjustment, such as changing price, purchasing ingredients, increasing capacity, improving demand, or controlling costs.

The module should not display numbers solely because they are available. Each metric should help answer at least one of these questions:

- How did the business perform?
- Why did it perform that way?
- What could the player adjust next?

More complex forecasting and prescriptive recommendations can be added later after the foundational reporting is useful and reliable.

## Initial Report Scope

The first Finance module will contain three report types:

1. **Price analysis:** Evaluates the player's historical price relative to the ideal price and explores pricing tendencies across weather, business reputation, advertisement levels, and equipment levels.
2. **Sales analysis:** Compares actual sales with operational capacity, records sellout frequency and cause, and shows how much consumed ingredient value was lost to expiration.
3. **Financial summary:** Presents lifetime revenue, expenses, investment, profit, cash, units sold, and other historical totals for player information and a sense of progression. These totals are not treated as normalized measures of decision quality.

When the player opens Finance, the module will receive the persisted daily-summary history. Finance itself will not restructure or analyze the summaries. When the player opens a specific analysis, a report-specific builder will transform the summaries into a purpose-built analytical dataset for that analysis. Finance will not maintain a separate mutable reporting history.

## Price Decision Analysis

Price is one of the player's most important and frequently repeated decisions. The first reporting feature should help the player understand whether they consistently price too high or too low and under which business conditions that tendency occurs.

### Daily data

For every operating day, retain the values that were true for that day:

- Player-selected unit price
- Ideal unit price
- Weather
- Business reputation
- Advertisement level
- Primary-equipment level
- Simulation day and calendar date
- Product and location identifiers, so reporting can later be filtered across product and location changes

The historical ideal price must be stored for the day rather than recalculated later. Recalculation could produce an inaccurate history after formulas or business state change.

### Normalized price trend

The primary visualization will be a line graph with simulation day on the horizontal axis and normalized price deviation on the vertical axis.

```text
priceDeviation = (selectedPrice / idealPrice) - 1
```

- `0` means the player selected the ideal price.
- A positive value means the player priced above ideal.
- A negative value means the player priced below ideal.
- `0.20` means 20% above ideal; `-0.20` means 20% below ideal.

This is more informative than graphing the raw price because it allows days with different conditions and ideal prices to be compared on the same scale.

The initial visual range can run from `-1` to `1`, but the underlying historical value should not be discarded or permanently clamped. The presentation should handle values outside that range explicitly rather than silently changing the recorded result.

### Condition breakdowns

The player can select a condition to replace or supplement the trend with a bar chart over the same reporting period.

For **weather** and **business reputation**, days will be grouped into five understandable categories:

- Great
- Good
- Fair
- Poor
- Bad

Each bar will show the average normalized price deviation for days in that category. This can reveal patterns such as consistently overpricing during poor conditions or underpricing during strong conditions.

For **advertisement level** and **primary-equipment level**, days will be grouped by the level active on that day. Each bar will show the average normalized price deviation at that level. This can reveal whether the player changes price too aggressively—or not enough—after upgrading the business.

Each group should also expose its sample size. An average based on one day should not appear equally reliable to an average based on twenty days.

### Player decision supported

This report helps the player decide whether to raise or lower price generally and whether their pricing response to weather, reputation, advertising, or equipment upgrades has historically been appropriate.

### Details still to define

- Exact thresholds that map weather and business reputation into the five categories
- Whether the line graph displays every operating day or aggregates longer histories
- How values outside the initial `-1...1` visual range are displayed
- Whether condition bar charts show only the average or also show spread/variation
- Whether advertisement and equipment levels should display unavailable levels or only levels represented in the selected period

### Design concern: exposing the ideal-price model

Ideal price is one of the game's most important pieces of hidden information. Although this report would not directly display the ideal price, showing the exact direction and magnitude of the player's deviation could allow players to infer or reverse-engineer the pricing model over time. The condition breakdowns could make this especially revealing by isolating the effects associated with weather, reputation, advertisement level, and equipment level.

Before implementation, we need to decide how much pricing guidance the report should provide. One possible compromise is to calculate exact deviation internally but expose only broad pricing-balance categories, such as much too low, slightly low, balanced, slightly high, and much too high. This would help players recognize tendencies without giving them a precise answer for future pricing decisions.

The intended principle is that reporting should help the player improve their judgment without solving the pricing decision for them.

## Sales Analysis

The second reporting feature should help the player determine whether the business needs more market opportunity, more operational capacity, or a different ingredient-purchasing strategy.

### Derived analytics model

`SalesAnalytics` is disposable in-memory state built from persisted operating
day summaries. It preserves chronological operating-day order, skips
relocation summaries, rebuilds during restore, and appends one row after each
completed operating day.

Each row retains actual sales, operational capacity, whether the business sold
out, its prioritized sellout cause, consumed ingredient cost, and expired
ingredient cost. The model exposes period-filtered results for the most recent
10 operating days, 30 operating days, or all operating days.

The three initial report results are:

- Actual sales and operational capacity by operating day
- Percentage of days in each mutually exclusive sellout outcome
- Consumed ingredient value compared with expired ingredient value

The sales-and-capacity graph also shows the selected product's maximum
operational capacity as a dotted target line. `SalesAnalytics` derives this
once at initialization from the product and the centralized tier-five
production-capacity schedule rather than duplicating it in every daily row.

Operational capacity excludes ingredients. Ingredient constraints remain in
the structured sales limits so actual sales and sellout causes can still be
calculated accurately.

When multiple constraints bind at the same unit count, the daily summary shows
every binding constraint. Sales Analytics assigns the day to one cause using
the easiest-to-remedy priority: ingredients, labor, equipment, then storage.
Transportation affects market size rather than capacity and is not a sellout
cause.

Ingredient waste is calculated as:

```text
expired cost / (consumed cost + expired cost)
```

This compares inventory leaving stock during the same period. Comparing
expiration with inventory purchases would mix purchase cohorts and could
produce misleading short-period percentages.

### Daily data

For every operating day, retain or derive:

- Effective operational capacity
- Maximum products that could be made from available ingredients
- Units customers attempted or were willing to purchase
- Units actually sold
- Whether the business sold out
- Approximate sellout time
- The binding constraint responsible for the sellout: labor, equipment, storage, or ingredients
- Quantity and cost of ingredients that expired
- Simulation day, calendar date, product, and location identifiers

The report must keep each sellout cause separate because every cause leads to a different player decision. The simulation should record the binding constraint when the daily result is calculated rather than asking the reporting module to infer the cause later.

### Daily interpretation

When available sales capacity is lower than customer opportunity, the report should show what percentage of the available market the business could serve. This indicates that the player may need additional operational capacity or a larger ingredient buffer.

When customer opportunity is lower than available sales capacity, the report should show what percentage of capacity the market used. This indicates that the player may need to invest in demand or market-size growth before purchasing more capacity.

Sellout time can provide a focused and intuitive indication of severity. Selling out shortly before closing is different from selling out near the beginning of the day. If the simulation already records actual unfulfilled demand, that value should be preferred over estimating market coverage from time alone. Sellout time remains useful as a player-facing explanation and supporting metric.

### Constraint diagnosis

The report should distinguish at least these outcomes:

- **Market constrained:** The business had unused sellable capacity, indicating that demand or market size may need investment.
- **Equipment constrained:** Equipment capacity was the binding sales limit.
- **Labor constrained:** Labor capacity was the binding sales limit.
- **Storage constrained:** Storage capacity was the binding sales limit.
- **Ingredient constrained:** Available ingredients were the binding sales limit.
- **Ingredient surplus:** Ingredients regularly expired, suggesting that the player is purchasing too large a buffer.
- **Balanced:** Customer opportunity, capacity, and ingredient availability were reasonably aligned.

This should allow the player to see not only how often the business sells out, but why it sells out.

### Player decisions supported

This report helps the player decide whether to:

- Invest in demand or market-size upgrades
- Purchase capacity upgrades
- Buy a larger ingredient buffer
- Reduce ingredient purchasing to limit expiration losses

### Presentation direction

A normalized daily trend can compare customer opportunity with sellable capacity. Supporting summaries can show:

- Frequency of sellouts
- Average sellout time
- Sellouts grouped by their recorded cause: equipment, labor, storage, or ingredients
- Average unused capacity
- Ingredient-expiration cost over the selected period

The exact graph design and normalization formula remain to be determined. The visualization should make the limiting factor obvious without presenting several similar percentages that the player must interpret independently.

### Details still to define

- Whether the simulation already records total attempted demand or whether it must be added
- How sellout time is calculated when sales occur in discrete simulation periods
- Whether effective sellable capacity uses operational capacity, ingredient capacity, or displays both
- How a day is classified when two or more constraints share the same limiting value
- How ingredient expiration cost is valued when ingredients were purchased on different days or at different effective prices
- What tolerance defines a balanced day rather than a constrained day

## Lifetime Financial Summary

The module may also include an informational financial summary covering the player's full game history. Unlike the price and capacity analyses, these totals are not intended to measure decision quality. Revenue, expenses, and profit naturally increase as the business expands, so an increase does not necessarily mean that the player is operating more effectively.

The purpose of this section is player edification and a satisfying record of business growth.

Potential lifetime values include:

- Total revenue
- Total operating expenses
- Total one-time investment
- Total profit
- Current cash balance
- Total units sold
- Total operating days

Expenses could eventually be divided into useful historical categories such as ingredients, labor, advertising, relocation, and upgrades, provided the existing transaction and summary history supports those categories reliably.

This section should be visually and conceptually separated from the decision-analysis reports. It should be described as a business history or lifetime summary, not as evidence that the player is performing well or poorly.

The term **balance sheet** should be used only if the game eventually tracks assets, liabilities, and equity as point-in-time values. Until then, **financial summary** or **lifetime financials** is more accurate.

## Reporting Data Architecture

Persisted daily summaries will be the source of truth for Finance reporting. Finance may maintain an eager, in-memory analytical dataset for convenient access, but that dataset remains disposable derived state and is never persisted as a second source of truth.

The architecture will have three responsibilities:

1. **Daily summary:** Stores the raw historical facts that were true for the completed day.
2. **Report-specific builder/calculator:** Builds a smaller purpose-built dataset from the daily summaries when Finance is initialized or restored, then appends an observation after each applicable completed day.
3. **Finance view:** Renders the prepared report and does not contain the business calculations itself.

The report builder creates a derived in-memory model. It is eagerly available during gameplay but does not become another persisted source of truth; restoration always reconstructs it from saved summaries.

### Reasons for this design

- Prevents daily summaries and a separate reporting tracker from becoming inconsistent
- Allows reports to be rebuilt after reporting formulas or category thresholds change
- Supports filtering the same history by date, product, location, operating period, or business level
- Preserves the underlying facts needed for future reports that have not yet been designed
- Makes historical results easier to inspect and debug
- Keeps report-specific updates limited to the workflows that produce applicable observations

Daily summaries should store raw inputs whenever practical rather than only storing the current derived score. For example, store selected price and historical ideal price rather than only a pricing category, and store each relevant capacity value rather than only a final balance label.

### Data-volume consideration

Even a long game is expected to contain only hundreds of daily summaries. The memory and processing cost of keeping the price-analysis observations eagerly available is negligible, so the simpler always-initialized lifecycle is preferred over optional lazy-cache logic.

### Eager price-analysis dataset

Each completed operating day is one discrete historical observation. A realistic game is expected to contain hundreds of daily summaries rather than thousands or millions, so iterating through the complete history is inexpensive.

FinanceView will render prepared results and will not perform reporting calculations. A new game begins with an empty price-analysis dataset. Restoring a game rebuilds the dataset from persisted operating summaries. Each newly completed operating day appends one observation, while relocation and other non-operating days append nothing.

A price-analysis observation should contain only the values needed by that report, such as day, date, location, normalized price deviation, weather information, business reputation, advertisement level, and equipment level. It should be sortable and filterable without requiring the analysis view to understand the larger `DaySummary` model. `locationID` already exists on `DaySummary`, so no additional persisted field is required.

The initial price-analysis dataset will contain one row for every operating summary with these columns:

- Simulation day, retained for historical traceability
- Consecutive operating-day position, used for chart spacing
- Calendar date
- Location ID
- Selected price
- Historical ideal price
- Daily high and low temperatures
- Weather demand multiplier actually applied during simulation
- Business reputation active when the day was simulated
- Primary-equipment level active when the day was simulated
- Advertisement level active when the day was simulated
- Derived price deviation: `(selectedPrice / idealPrice) - 1`

Relocation and other non-operating summaries will not produce price-analysis rows. The exact price deviation will remain available internally even if the player-facing visualization later uses coarse categories to protect the ideal-price model.

The chronological graph can use these observations directly. When the player selects weather, reputation, advertisement, or equipment analysis, the price-analysis model can group and average the already-normalized observations. With only hundreds of observations, calculating a selected grouping on demand remains inexpensive and preserves flexibility for filters.

The default price-analysis view will graph price deviation by consecutive operating-day position. Relocation and other non-operating days therefore do not create empty horizontal gaps. The underlying simulation day remains available for historical lookup. The player may filter the dataset to a recent window, such as the last 10 or last 30 operating days. The selected window will be applied before any visualization is calculated:

1. Filter the price-analysis observations to the selected period.
2. For the trend view, sort the filtered observations by simulation day and chart them directly.
3. For a breakdown view, group the filtered observations by weather category, reputation category, advertisement level, or equipment level.
4. Average the price deviation within each group and retain its observation count.

This ensures that changing the reporting period updates both the daily trend and all grouped analyses consistently.

This creates two clear transformations:

1. Daily summaries become price-analysis observations during initialization/restoration, with later operating summaries appended as they are finalized.
2. Those observations become the selected chart or grouping as the player changes the analysis controls.

### Derived-report lifecycle

The price-analysis dataset is initialized with Finance and remains available throughout gameplay, so opening or reopening the analysis does not trigger a historical rebuild.

The dataset is derived state and will never be persisted. A normal operating day appends its newly finalized observation. Restoring a different game reconstructs the complete dataset from that game's persisted summaries. Relocation and other non-operating summaries are ignored.

Normal daily-save failures do not require analytical rollback because gameplay does not roll back after a failed daily save. If the app exits before a later successful save, both the in-memory dataset and unsaved gameplay state disappear; restoration reconstructs the dataset from the last successfully persisted summaries. If a later save succeeds, it persists the full current summary history.

The dataset belongs to the gameplay Finance model rather than an individual Finance modal, allowing it to survive view presentation changes. The views do not own its validity.

We will not persist running sums, counts, or category averages. Doing so would create duplicate historical state, complicate formula changes and date filtering, and provide no meaningful performance benefit at the expected data volume.

If future measurement reveals an actual performance problem, derived reports may be indexed further without changing the daily summaries as the source of truth.

### Weather reporting data

Weather demand uses a representative operating-hours temperature calculated
60% of the way from the daily low to the daily high. Daily summaries persist
the original high and low temperatures as well as the exact weather demand
multiplier applied during simulation.

The raw temperatures allow historical observations to be recalculated if the
operating-hours formula changes. The stored multiplier preserves the effect
the player actually experienced even if the gameplay formula changes later.
Weather classifications are not persisted because they are report-specific
derived values.

Finance owns the weather-analysis boundaries and classifies the stored
multiplier directly as Fair or Worse, Good, or Great. The exact multiplier is
retained, so the categories and boundaries can be changed later without a save
migration or loss of historical precision.
