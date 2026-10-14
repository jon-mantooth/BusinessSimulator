# Department Scene Asset Design

## Purpose

Department views should visually reflect the business the player has built. As
the player purchases equipment, labor, advertising, storage, and transportation,
the corresponding scene should gain or replace visual elements.

The first implementation was built for Distribution and assumed a simple,
fixed model: choose one asset for a product, dimension, and level. Production
and Marketing exposed several cases that do not fit that assumption.

## The Design Problem

### Independent dimension state

A department can contain several dimensions at different levels. Distribution,
for example, may have storage at one level and transportation at another. A
single department level cannot describe the complete scene.

### Replacement and additive upgrades

Some upgrades replace a previous asset:

- Primary equipment
- Storage
- Primary transportation

For these dimensions, only the asset for the active level should normally be
shown.

Other upgrades accumulate:

- Secondary equipment
- Labor
- Secondary transportation

For these dimensions, every owned item with a configured scene asset should be
shown.

### Presentation behavior can differ from operational behavior

Advertising is operationally a replacement-level dimension, but it should be
displayed cumulatively. A higher-level advertisement does not look like a
larger or improved version of the previous advertisement in the way an oven,
freezer, or vehicle can. The scene should instead retain a visual for every
advertisement the player has purchased, such as adding another flyer to a
board.

This means purchase behavior must not be used to infer scene behavior.

### Product-specific backgrounds and assets

Production has a different background for each product. Distribution currently
uses one shared background, although its scene elements may still vary by
product. Background selection therefore belongs in the scene catalog rather
than being hardcoded into a department view.

### Cross-dimension layering

The correct visual order is not always the same as the dimension order. A piece
of secondary equipment may need to appear behind one employee and in front of
another element. Each asset therefore needs its own scene-wide `layerOrder`.

## Implemented Solution

### Department scene assets and layers

Every visual is represented by a `DepartmentSceneAsset`. Its type defines how
the view renders it:

```swift
enum DepartmentSceneAssetType {
    case background
    case element(sourceWidth: CGFloat, position: CGPoint)
}

struct DepartmentSceneLayer {
    let layerOrder: Int
    let assets: [DepartmentSceneAsset]
}
```

A background is a normal scene asset with type `.background` and must use
layer `0`. An element contains its display width and position and must use a
layer greater than `0`.

The resolver returns `[DepartmentSceneLayer]`. Assets with the same layer order
are grouped together, and layers are returned in ascending order.

### Three scene-selection categories

Scene assets are selected in one of three ways:

1. **Product-dependent**: return assets that always belong to the selected
   product, such as a center island.
2. **Replacement**: return the asset matching a dimension's active level.
3. **Cumulative**: return every asset matching an owned or previously
   purchased item ID.

These categories describe visual selection only. They do not dictate how an
upgrade behaves operationally.

Examples:

| Dimension | Operational behavior | Scene selection |
| --- | --- | --- |
| Primary equipment | Replacement | Active level |
| Storage | Replacement | Active level |
| Primary transportation | Replacement | Active level |
| Secondary equipment | Additive | Owned item IDs |
| Labor | Additive | Owned item IDs |
| Secondary transportation | Additive | Owned item IDs |
| Advertisement | Replacement | Purchased item IDs |

### Catalogs and normalized scene input

`ProductionSceneCatalog`, `DistributionSceneCatalog`, and
`MarketingSceneCatalog` each conform to `SceneCatalog`. Every catalog exposes
the same three datasets:

- `productDependentAssets`
- `replacementAssets`
- `cumulativeAssets`

`DepartmentSceneResolver` uses the requested department to select the correct
catalog. The catalogs remain separate; there is no merged master asset
dictionary.

Each department supplies the catalog with its product and current visual state:

- Active levels for level-based dimensions
- Owned or purchased IDs for owned-item-based dimensions

The centralized resolver then:

1. Resolves all product-dependent assets for the selected product.
2. Resolves one asset for every requested replacement dimension and level.
3. Resolves all matching assets for every cumulative dimension and item ID.
4. Combines the three asset collections.
5. Ignores missing asset configurations, allowing an upgrade to have no scene
   representation.
6. Groups the assets by `layerOrder` and returns the layers in ascending order.

### View responsibilities

The department view does not decide which upgrades should be visible. It:

1. Converts its current dimension state into replacement levels and cumulative
   item IDs.
2. Requests resolved layers from `DepartmentSceneResolver`.
3. Renders the returned layers sequentially.
4. Renders interactive controls above the scene.

SwiftUI renders later elements above earlier elements, so ascending layer order
creates the intended stack.

### Catalog responsibilities

The catalog determines which assets apply and returns their presentation data.
Each `DepartmentSceneAsset` contains:

- A stable scene asset ID
- Image name
- Asset type
- Display width and position for elements
- Scene-wide layer order

The catalog defines static asset configuration. The resolver selects and
groups assets, while the view renders them.

Production currently selects its background through primary-equipment
replacement assets. This allows the background to vary by both product and
active primary-equipment level.

## Future Work: Advertisement Purchase History

Advertisement level alone cannot recreate the cumulative scene because a tier
may offer multiple choices. `AdvertisementState` therefore needs a persisted
list such as `purchasedAdvertisementIDs`.

When an advertisement purchase succeeds:

1. The active advertisement is replaced for operational calculations.
2. The purchased advertisement ID is appended to the history.
3. Both changes are saved atomically.

The purchase history must also be included in rollback state. If a purchase or
save fails, the appended ID is removed when the prior advertisement state is
restored.

This is game state rather than presentation configuration because it records
the exact choices the player made and cannot be reconstructed from the active
level alone.

## Persistence Boundary

Static presentation configuration is not persisted. Image names, positions,
sizes, layer order, and backgrounds remain in the catalogs so existing saves
receive visual changes automatically.

Only source game state is persisted:

- Product ID
- Active upgrade levels
- Owned additive items
- Advertisement purchase history

The resolved scene is rebuilt from that state whenever the view renders.

## Purchase Failure and Rollback

Scene assets do not require their own rollback mechanism. The scene is derived
from committed dimension state. A view should begin its replacement animation
only when the committed level or owned-item collection differs from what it is
currently displaying.

If a purchase fails and the workflow restores the prior state, the resolver
returns the prior scene and no visual transition is required.

## Testing Boundary

Unit tests should cover catalog and resolver behavior rather than SwiftUI image
rendering:

- Missing department, dimension, product, level, or item ID returns no asset.
- Level-based dimensions return only the active-level asset.
- Owned-item-based dimensions return all configured owned assets.
- Product-dependent, replacement, and cumulative assets are combined.
- Assets with the same layer order are grouped together.
- Layers are returned deterministically in ascending order.
- Department routing selects the corresponding scene catalog.
- Every product and primary-equipment level resolves exactly one layer-zero
  background.

Visual placement, sizing, image quality, and animation timing remain subjects
for device-based visual review.
