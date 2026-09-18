# Labor Design Decisions

Use this file to record decisions made during the labor feature, including enough rationale to understand why each decision was made.

## Decisions

- Labor will follow the established equipment architecture wherever its behavior is equivalent.
- A labor group will be modeled after `SecondaryEquipmentCollection`, allowing the game to distinguish owned and available labor options.
- `LaborDimension` will affect both demand and production capacity.
- Hiring is permanent. The player cannot fire a worker after hiring them.
- Hired workers remain in the owned labor group, and their benefits and recurring costs remain active for the rest of the game.
- Labor wages are charged daily. This keeps each day's profit representative and avoids concentrating payroll into one weekly summary. This may be revisited during gameplay testing.
- Equipment and labor will use coordinated production-capacity targets, but their values will be deliberately offset so only one is the limiting factor at a time. This avoids requiring two purchases before the player receives any capacity benefit.
- Labor will have one main component and three secondary additions. The secondary additions will incrementally increase capacity in a manner similar to secondary equipment.
- Labor items do not have a primary/secondary category in the model. All hired workers belong to the same cumulative owned-labor pool and follow the same purchase and cost behavior.
- Every `Labor.capacity` value represents an additive contribution. Player labor provides the 120% baseline, the primary chef contributes an additional 50%, and each of the three other workers contributes an additional 20%.
- The product-specific labor specialists are Grill Master for hot dogs, Baker for pies, and Mixologist for smoothies.
- Prep Cook, Line Cook, and Cleanup Worker are shared across all products.
- The product-specific specialist contributes two of labor's five total demand levels. Each of the three shared workers contributes one demand level, allowing a fully staffed business to reach 5/5.
- Labor receives 18% of total demand growth. The specialist contributes 7.2 percentage points and each shared worker contributes 3.6 percentage points.
- Labor is priced against the base business state regardless of hiring order. A worker's projected demand and capacity benefits are added together, and the daily wage begins at 120% of that projected base-state daily profit. The wage is intentionally unprofitable immediately but becomes profitable as the business grows.

## Equipment and Labor Capacity Curves

Equipment capacity follows the shared `ProductionCapacityBalance` curve. Tier zero begins at 90% of the product's ideal units sold, and tier five reaches 200%. The 110-percentage-point increase is divided evenly across five tier transitions.

Main labor has a tier-zero capacity of 120% and a tier-one capacity of 170%. These are the initial chosen balance values and may still be adjusted after gameplay testing.

| Tier | Equipment capacity | Main labor capacity |
|---:|---:|---:|
| 0 | 90% | 120% |
| 1 | 112% | 170% |
| 2 | 134% | — |
| 3 | 156% | — |
| 4 | 178% | — |
| 5 | 200% | — |

Actual whole-unit capacities can differ slightly from these percentages because the game rounds the baseline, target, and tier increases.

Fully upgraded primary and secondary equipment reaches approximately 225% to 230% of ideal units sold, depending on the product and whole-unit rounding. Fully upgraded labor should reach the same general range.

After the primary chef raises labor capacity to 170%, the three secondary labor additions provide 60 additional percentage points combined. Each secondary hire adds 20% of ideal units sold.

| Labor state | Cumulative capacity | Increase |
|---|---:|---:|
| Player only | 120% | — |
| Primary chef hired | 170% | 50 percentage points |
| Primary chef + secondary hire 1 | 190% | 20 percentage points |
| Primary chef + secondary hires 1–2 | 210% | 20 percentage points |
| Fully staffed | 230% | 20 percentage points |

### Intended capacity progression

- At the beginning of the game, the player working alone can comfortably meet ordinary demand because labor capacity is above equipment capacity.
- Equipment becomes the first production bottleneck and must be upgraded before additional labor is required.
- When equipment advances beyond the player's tier-zero labor capacity, the player can hire secondary workers as a temporary solution or hire the primary chef.
- Secondary labor can postpone the primary-chef purchase, but cannot replace it indefinitely.
- Hiring the primary chef raises main labor capacity to 170%, supporting approximately two more equipment tiers before labor becomes the bottleneck again.
