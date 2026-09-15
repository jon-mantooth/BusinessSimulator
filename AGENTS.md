# Project Guidelines

## UI image assets

- Use `Assets.xcassets/SceneElements/EquipmentUI` as the sizing and compression guide for assets placed in any `*_UI` folder.
- Size each image for its actual displayed shape and maximum expected Retina display size; assets in a `*_UI` folder do not need to share one resolution.
- Crop unnecessary transparent padding before resizing, while preserving intentional shadows and edge details.
- Prefer the smallest PNG resolution that produces no visible quality loss on the supported devices.
- Before accepting new or replacement UI assets, compare their dimensions and file sizes with equivalent elements in `EquipmentUI` and optimize unusually large files.

