# Storage Design Decisions

## Structure

- Storage is a tiered, product-specific dimension with tiers 0–5.
- Every tier contains exactly one storage option.
- Tier 0 is the free starting state and represents having no dedicated
  storage.
- Storage upgrades are sequential replacements. A newly purchased tier
  replaces the active storage item from the preceding tier.
- Every storage purchase is a one-time payment.
- Storage purchases use the existing global weekly upgrade restriction.

### Tier and Item Separation

Storage could have been modeled as a list of `Storage` items that each carried
their own level and required location tier. We chose to retain a separate
`StorageTier` layer instead.

This separates progression-related behavior from the internal characteristics
of the purchased item:

- `StorageTier` owns the storage level, required location tier, and the logic
  that calculates capacity and price for that point in progression.
- `Storage` owns the item's identity, name, description, icon, payment
  schedule, and its finalized price and capacity.
- `StorageState` owns which configured storage tier is currently active.

Storage currently has exactly one option per tier, so either model would work.
Keeping the tier layer mirrors the structure used by the other purchasable
dimensions and preserves the flexibility to offer multiple storage options at
the same tier later without redesigning the progression model.

## Gameplay Effects

- Storage affects production capacity only.
- Storage does not affect demand, market size, ingredient freshness,
  spoilage, daily costs, or weekly costs.
- Storage is ignored as a sales limit while the business is at location
  level 1. The player prepares and sells products at home during this phase,
  so dedicated storage is unnecessary.
- Storage becomes an independent production-capacity limit at location level
  2. The player prepares products at home, transports them to the new
  location, and stores them there for service.
- Tier 1 is purchasable at location level 1 and is required for relocation to
  location level 2.
- Tiers 2–5 are purchasable only at location level 2.

## Capacity

Storage capacity is expressed as total capacity rather than additive
capacity. Each value is a percentage of the product's base ideal unit sales.

| Tier | Capacity |
|---:|---:|
| 0 | 0% |
| 1 | 230% |
| 2 | 255% |
| 3 | 280% |
| 4 | 305% |
| 5 | 330% |

At the beginning of location level 2, required primary equipment and the
product-specific primary laborer each support approximately 210% of ideal
sales. Storage tier 1 begins at 230%, providing initial headroom rather than
immediately constraining the player. Storage then progresses evenly to the
shared 330% maximum.

## Pricing

- Storage uses the existing capacity-benefit pricing algorithm.
- All calculated prices use the one-time payment schedule.
- Tier 1 uses location-level-1 pricing inputs.
- Tiers 2–5 use location-level-2 pricing inputs.
- Prices are calculated from the item's full replacement capacity, consistent
  with primary equipment pricing.

### Replacement and Additive Pricing

Capacity pricing distinguishes between replacement and additive upgrades.

1. A replacement purchase is a complete new asset. Its price must account for
   the asset's total benefit rather than only the improvement over the item it
   replaces. A manufacturer prices a 500-unit oven as a 500-unit oven even if
   the player's previous oven already produced 400 units.
2. Pricing total capacity makes replacement purchases substantially more
   expensive than pricing only their incremental benefit. Replacement and
   additive purchases therefore use independent balancing controls:
   `replacementTargetPaybackDays` is currently 6 days, while
   `additiveTargetPaybackDays` remains 12 days. Either curve can now be tuned
   without changing the other.
3. Mixed payment schedules create a second distinction. A one-time replacement
   price represents the full permanent benefit being purchased, while daily or
   weekly payments are balanced as a recurring share of the benefit the player
   receives. Applying those two models directly within one set of choices can
   make their prices difficult to compare.
4. When replacement choices mix one-time and recurring schedules, first
   calculate a recurring-equivalent price and derive the one-time price from
   it. Advertisement currently applies this rule by pricing every option on a
   weekly basis and charging four weeks of that price for a one-time option.
   This preserves a consistent relationship if the underlying weekly price
   changes later.

## State, Persistence, and Rollback

- The active storage item and its original purchase data must be persisted so
  later catalog changes do not alter an existing purchase.
- Unowned storage options may be rebuilt from the current catalog during
  restore.
- A failed save must restore the prior storage item and every other state
  changed by the purchase workflow, including finance, upgrade tracking, and
  pending business events.

## Distribution Channel

- `BusinessDimensions` already defined a distribution channel, but no
  distribution department was previously included in the simulation loop.
- Storage activates that existing channel through a `Distribution`
  department rather than being placed artificially in production.
- The distribution department delegates all dimension behavior consistently
  with the other departments, allowing transportation to join the same
  channel later without restructuring the simulation pipeline.

## UI

- Storage will use a single tiered view with one option per tier.
- Capacity will be displayed as a total daily capacity, not an additive
  amount.
- Upgrade modals should begin with a fully populated visual mockup that defines
  the intended composition, hierarchy, spacing, and style.
- The production background should retain the decorative structure but remove
  all dynamic text and item images.
- SwiftUI should compose the dynamic information into self-contained panels
  (for example, item information, capacity, progress, and purchase controls)
  and place those panels onto normalized regions of the background.
- A panel owns the layout of its internal content. The background determines
  where the panel belongs, but individual labels should not be independently
  positioned against the background. This supports different text lengths and
  avoids repeated coordinate calibration.
- Static visual details stay baked into the background; SwiftUI owns dynamic
  data, state-dependent presentation, interaction, and accessibility.

## Catalog

### Pies

| Tier | Storage item | Description | Capacity |
|---:|---|---|---:|
| 0 | No Storage | Product is prepared and sold from home, so dedicated storage is not required. | 0% |
| 1 | Insulated Pie Holding Rack | A portable, insulated rack that protects finished pies and keeps them warm during transport and farmers-market service. | 230% of ideal sales (approximately 87 pies) |
| 2 | Heated Pie Display Cabinet | A compact powered cabinet that keeps more pies warm, organized, and ready for customers throughout market service. | 255% of ideal sales (approximately 97 pies) |
| 3 | Commercial Pie Warming Cabinet | A full-size heated cabinet with adjustable shelving that keeps a larger supply of pies consistently warm and ready for busy market days. | 280% of ideal sales (approximately 106 pies) |
| 4 | Dual-Zone Pie Holding Cabinet | A high-capacity cabinet with independently controlled warming zones, allowing different pie varieties to remain at their ideal serving temperatures during peak service. | 305% of ideal sales (approximately 116 pies) |
| 5 | Commercial Roll-In Pie Warmer | A premium roll-in warming system that holds full racks of finished pies with precise temperature control and rapid access during the busiest market service. | 330% of ideal sales (approximately 125 pies) |

### Hot Dogs

| Tier | Storage item | Description | Capacity |
|---:|---|---|---:|
| 0 | No Storage | Product is prepared and sold from home, so dedicated storage is not required. | 0% |
| 1 | Insulated Hot Dog Carrier | A portable insulated carrier that keeps prepared hot dogs warm and protected during transport to the ballpark. | 230% of ideal sales (approximately 324 hot dogs) |
| 2 | Hot Dog and Bun Steamer | A countertop steamer with separate compartments that keeps hot dogs hot and buns soft throughout service. | 255% of ideal sales (approximately 360 hot dogs) |
| 3 | Heated Hot Dog Holding Cabinet | A commercial heated cabinet that stores a larger supply at a consistent serving temperature during busy games. | 280% of ideal sales (approximately 395 hot dogs) |
| 4 | Dual-Zone Hot Dog Holding Station | A high-capacity station with independently controlled sections for hot dogs and buns, improving organization and temperature control. | 305% of ideal sales (approximately 430 hot dogs) |
| 5 | Commercial Ballpark Holding System | A premium high-volume holding system designed for rapid access and continuous service during the largest crowds. | 330% of ideal sales (approximately 465 hot dogs) |

### Smoothies

| Tier | Storage item | Description | Capacity |
|---:|---|---|---:|
| 0 | No Storage | Product is prepared and sold from home, so dedicated storage is not required. | 0% |
| 1 | Insulated Smoothie Cooler | A portable insulated cooler that keeps prepared smoothies cold and protected during transport to the beach. | 230% of ideal sales (approximately 345 smoothies) |
| 2 | Portable Electric Cooler | A powered portable cooler that maintains a reliable cold temperature throughout beach service. | 255% of ideal sales (approximately 383 smoothies) |
| 3 | Glass-Door Beverage Refrigerator | A commercial refrigerator that keeps a larger smoothie supply cold, organized, and visible for quick service. | 280% of ideal sales (approximately 420 smoothies) |
| 4 | Dual-Zone Refrigerated Cabinet | A high-capacity cabinet with independently controlled cooling zones for maintaining different smoothie varieties. | 305% of ideal sales (approximately 458 smoothies) |
| 5 | Commercial Roll-In Refrigerator | A premium high-volume refrigerator that accommodates full racks of prepared smoothies for the busiest beach days. | 330% of ideal sales (approximately 495 smoothies) |
