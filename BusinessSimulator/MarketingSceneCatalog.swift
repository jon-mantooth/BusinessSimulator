struct MarketingSceneCatalog: SceneCatalog {
    private let pieBackground = DepartmentSceneAsset(
        id: "marketing-background-pies",
        imageName: "marketing_background_pies",
        type: .background,
        layerOrder: 0
    )

    private let hotDogBackground = DepartmentSceneAsset(
        id: "marketing-background-hotdogs",
        imageName: "marketing_background_hotdogs",
        type: .background,
        layerOrder: 0
    )

    private let smoothieBackground = DepartmentSceneAsset(
        id: "marketing-background-smoothies",
        imageName: "marketing_background_smoothies",
        type: .background,
        layerOrder: 0
    )

    var productDependentAssets: ProductDependentSceneAssets { [
        .pies: [pieBackground],
        .hotDogs: [hotDogBackground],
        .smoothies: [smoothieBackground]
    ] }

    let replacementAssets: ReplacementSceneAssets = [:]
    let cumulativeAssets: CumulativeSceneAssets = [:]
}
