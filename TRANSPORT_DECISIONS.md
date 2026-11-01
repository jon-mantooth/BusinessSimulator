# Transport Design Decisions

## Terminology

- The dimension is named **Transport**, not Transportation. It moves products,
  not people.
- Placeholder identifiers were normalized to `Transport` / `transport` before
  the feature was implemented. No live Transport data existed, so no
  Transport-specific persistence migration was needed.

## Dimension Structure

Transport will follow the established dimension architecture:

- `Transport` represents one purchasable transport item.
- `TransportState` owns the player's current transport state.
- `TransportCatalog` defines the available items and their progression.
- `TransportDimension` contributes Transport's effect to the simulation.
- `TransportView` presents and purchases Transport upgrades.
- Purchases use the existing `PurchaseWorkflow` rather than a separate
  transaction system.

Transport belongs to the Distribution department alongside Storage.

## Revenue Effect

- Transport affects **market size only**. It does not affect demand or
  production capacity.
- Transport is responsible for 45% of the permanent market-size progression.
- Advertising already owns 40% and Business Reputation owns 15%, so adding
  Transport produces a complete permanent weighting of 100%.
- The game's permanent market-size range is 100% to 300%.
- Location no longer supplies a separate market-size multiplier. The 100
  percentage points introduced by entering location tier 2 must therefore be
  represented by the tiered dimensions that become effective there.
- Transport uses the shared market-size balancing calculation with its `0.45`
  weight rather than introducing a separate multiplier system.
- Business Reputation, Advertising, and Transport all use the same `3.0`
  location-two target at full effect. Their weights therefore combine to the
  exact intended permanent maximum:
  `3.0^0.45 * 3.0^0.40 * 3.0^0.15 = 3.0`.

## Progression Allocation

Transport's internal upgrade allocation is:

| Purchase | Share of Transport progression | Market-size increase |
| --- | ---: | ---: |
| Initial primary option | 40% | 40 percentage points |
| Primary upgrade 2 | 15% | 15 percentage points |
| Primary upgrade 3 | 15% | 15 percentage points |
| Secondary option 1 | 15% | 15 percentage points |
| Secondary upgrade 2 | 15% | 15 percentage points |
| **Fully upgraded** | **100%** | **100 percentage points** |

At location tier 2, the initial primary option also carries the 100-point
location-tier increase that is no longer supplied directly by Location. Its
active cumulative increase is therefore 140%, followed by four equal
15-percentage-point additions through the 200% target.

## Location Behavior

- The initial Transport option is available at location tier 1 and is required
  before relocation to location tier 2.
- All later Transport options are locked until location tier 2.
- The initial option provides no market-size effect while the business remains
  at location tier 1.
- Once the business reaches location tier 2, all earned Transport progression,
  including the initial option's 40% share, becomes active.

This mirrors Storage's distinction between owning an upgrade and the location
at which its simulation effect becomes applicable.

## Two Replacement Tracks

Transport uses a different ownership model from existing dimensions:

- The player begins with no Transport.
- The player must purchase primary Transport tier 1 first.
- After that purchase, primary and secondary Transport can be advanced
  independently.
- The primary track progresses sequentially from tier 1 through tier 3.
- The secondary track progresses sequentially from tier 1 through tier 2.
- Primary tier 2 requires primary tier 1; primary tier 3 requires primary tier
  2. Secondary tier 1 requires primary tier 1; secondary tier 2 requires
  secondary tier 1.
- Once primary tier 1 is owned, the player may advance either track in any
  valid sequential order, including completing one track before advancing the
  other.
- Both tracks are replacement tracks. An upgrade replaces the active item on
  its own track; it does not create a cumulative collection of every item ever
  purchased.
- Adding the first secondary item does not replace the primary item. The
  business can have one active primary item and one active secondary item.
- This ownership model also maps naturally to the existing department-scene
  system, which already supports separate primary and secondary Transport
  replacement assets.

The displayed level labels match the tracks directly: primary tiers 1–3 and
secondary tiers 1–2.

## State Model

`TransportState` will own the complete set of `TransportTier` definitions and
one `ActiveTransport` value. `ActiveTransport` contains up to one active
purchased item for each track:

- `primary`: optional active primary Transport item
- `secondary`: optional active secondary Transport item

The state will derive `primaryTier` and `secondaryTier` from those active
items and the tier definitions rather than store duplicate tier state. This
keeps the purchased item, its preserved weekly price, and its progression level
in sync.

The state will also derive the currently available next tiers. Depending on
progress, that list contains zero, one, or two items:

| Current state | Next options |
| --- | --- |
| No Transport | Primary tier 1 |
| Primary tier 1 only | Primary tier 2, Secondary tier 1 |
| Primary tier 2 only | Primary tier 3, Secondary tier 1 |
| Primary tier 3 only | Secondary tier 1 |
| Primary tier 1 + Secondary tier 1 | Primary tier 2, Secondary tier 2 |
| Primary tier 2 + Secondary tier 1 | Primary tier 3, Secondary tier 2 |
| Primary tier 3 + Secondary tier 2 | None |

The future `TransportView` can display the zero-to-two active items at the top
and this same zero-to-two next-tier list as purchase options below.

## Payment Schedule

Every Transport item uses a weekly payment. This reflects leasing or renting
vehicles and equipment: primary Transport progresses from a car to a van to a
truck, while secondary Transport represents a product/location-appropriate
delivery method such as a beach jet ski, farmers-market cart, or ballpark
vendor basket.

- The initial primary option begins charging when it is purchased, including at
  location tier 1, even though its market-size effect remains dormant until
  location tier 2.
- Replacing an item ends the prior weekly charge on that same track.
- Active primary and secondary items are charged concurrently.
- A replacement payment must represent the full benefit retained on its own
  track, not just the newest increment. Otherwise replacing a prior weekly
  payment would remove the charge for previously retained benefit.

## Weekly Pricing Model

Transport has no fixed combined purchase order after primary tier 1, so its
weekly prices must not depend on the state of the other track. Each item is
priced against the total progression supplied by its own active track:

| Active item | Transport progression represented by its weekly payment |
| --- | ---: |
| Primary tier 1 | 40% |
| Primary tier 2 | 55% |
| Primary tier 3 | 70% |
| Secondary tier 1 | 15% |
| Secondary tier 2 | 30% |

For example, purchasing primary tier 2 replaces the primary tier-1 payment, so
the new payment is priced for primary's retained 40% plus its new 15%, or 55%
of Transport progression. Secondary tier 1 is a separately active payment,
priced only for its own 15% contribution. Its tier-2 replacement covers its
retained 15% plus its new 15%.

This avoids depending on whether the other track has been purchased. It also
matches the established rule that recurring replacement payments cover the
full active benefit of the item they replace.

## Multiplicative Market-Size Progression

Transport retains the existing multiplicative framework between dimensions,
while its levels accumulate additively inside Transport. It returns no effect
at location tier 1. At location tier 2, its raw target is determined from the
combined active primary and secondary tiers:

| Combined Transport state | Cumulative increase | Raw target | Weighted multiplier |
| --- | ---: | ---: | ---: |
| No active effect | 0% | 1.00 | 1.000 |
| Primary tier 1 | 140% | 2.40 | 1.483 |
| One later upgrade | 155% | 2.55 | 1.524 |
| Two later upgrades | 170% | 2.70 | 1.564 |
| Three later upgrades | 185% | 2.85 | 1.602 |
| Fully upgraded | 200% | 3.00 | 1.640 |

The four later purchases each add `0.15` to the raw target regardless of their
order. The existing market-size calculation then applies Transport's `0.45`
weight to that combined raw target.

## Product Catalog Structure

Every product has the same five-item Transport progression and therefore uses
the same market-size effect and price at each corresponding tier:

- Primary tiers 1–3 use progressively larger road vehicles. The intended
  vehicle sequence is car, van, and truck, subject to a final catalog review.
- Secondary tiers 1–2 are product and location specific.

| Product | Secondary tier 1 | Secondary tier 2 |
| --- | --- | --- |
| Hot Dogs | Vendor basket and license to sell in the ballpark stands in addition to the stand | Larger vendor basket |
| Smoothies | Jet ski for marina sales | Larger jet-ski storage compartment |
| Pies | Cart for selling throughout the farmers market | Larger cart |

Items may use product-specific names, descriptions, icons, and Department
scene assets even where their simulation behavior and prices are shared.

## Implementation Order

Transport was implemented backend first. After the visual assets became
available, `TransportView` was added and wired through `DistributionView` and
the existing `PurchaseWorkflow`. Department-scene assets remain separate work
from the purchase modal.

## Open Design Decisions

1. Confirm the final primary vehicle order: car, van, truck versus car, truck,
   van.
2. Decide how the two tracks are presented and selected in `TransportView`
   when UI work resumes.
