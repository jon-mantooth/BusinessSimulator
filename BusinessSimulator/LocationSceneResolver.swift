struct LocationSceneContext {
    let productID: ProductID?
    let seasonOfYear: SeasonOfYear
    let weatherCondition: WeatherCondition
}

enum ResolvedLocationSceneContent {
    case empty
    case image(name: String, aspectRatio: Double)
    case customerAnimation(CustomerVisitSchedule)
    case playbackInterface
}

struct ResolvedLocationSceneAsset: Identifiable {
    let layout: LocationSceneAsset
    let content: ResolvedLocationSceneContent
    let position: LocationScenePosition

    var id: String {
        layout.id
    }
}

struct ResolvedLocationScene {
    let assets: [ResolvedLocationSceneAsset]
}

/// Converts the catalog's contextual scene slots into concrete image and
/// playback content for one product, date, and weather condition.
struct LocationSceneResolver {
    func resolve(
        _ scene: LocationSceneAssets,
        context: LocationSceneContext
    ) -> ResolvedLocationScene {
        let resolvedAssets = scene.assets
            .map { asset in
                ResolvedLocationSceneAsset(
                    layout: asset,
                    content: resolveContent(
                        for: asset,
                        context: context
                    ),
                    position: resolvedPosition(
                        for: asset,
                        context: context
                    )
                )
            }
            .sorted { lhs, rhs in
                lhs.layout.layerOrder < rhs.layout.layerOrder
            }

        return ResolvedLocationScene(assets: resolvedAssets)
    }

    private func resolvedPosition(
        for asset: LocationSceneAsset,
        context: LocationSceneContext
    ) -> LocationScenePosition {
        guard asset.id == "neighborhood-product-stand",
              asset.source == .productStand,
              context.seasonOfYear == .spring else {
            return asset.position
        }

        // The spring neighborhood artwork places the sidewalk lower than the
        // other seasonal backgrounds, so its stand follows that visual anchor.
        return LocationScenePosition(
            x: asset.position.x,
            y: 0.781
        )
    }

    private func resolveContent(
        for asset: LocationSceneAsset,
        context: LocationSceneContext
    ) -> ResolvedLocationSceneContent {
        switch asset.source {
        case .image(let imageName):
            guard let aspectRatio = asset.aspectRatio else {
                preconditionFailure(
                    "A fixed scene image must define its aspect ratio."
                )
            }

            return .image(
                name: imageName,
                aspectRatio: aspectRatio
            )

        case .seasonalDayBackground:
            return seasonalBackground(
                for: context.seasonOfYear,
                timeOfDay: "day"
            )

        case .seasonalNightBackground:
            return seasonalBackground(
                for: context.seasonOfYear,
                timeOfDay: "night"
            )

        case .seasonalSimulationBackground:
            return simulationBackground(for: context)

        case .weatherSimulationBackground(
            let sunnyImageName,
            let rainImageName,
            let snowImageName
        ):
            let imageName: String

            switch context.weatherCondition {
            case .rain:
                imageName = rainImageName
            case .snow:
                imageName = snowImageName ?? sunnyImageName
            case .sunny, .cloudy:
                imageName = sunnyImageName
            }

            guard let aspectRatio = asset.aspectRatio else {
                preconditionFailure(
                    "A weather simulation background must define its aspect ratio."
                )
            }

            return .image(
                name: imageName,
                aspectRatio: aspectRatio
            )

        case .productStand:
            guard let productID = context.productID else {
                return .empty
            }
            return dayStand(for: productID)

        case .customerAnimation:
            return .customerAnimation(
                customerSchedule(for: context)
            )

        case .simulationProductStand:
            guard let productID = context.productID else {
                return .empty
            }
            return simulationStand(for: productID)

        case .playbackInterface:
            return .playbackInterface
        }
    }

    private func customerSchedule(
        for context: LocationSceneContext
    ) -> CustomerVisitSchedule {
        // The prototype schedule is the current complete customer catalog.
        // This resolver is the single point where location-, season-, and
        // weather-specific eligibility will be applied as those assets grow.
        _ = context.weatherCondition
        return .prototype
    }

    private func seasonalBackground(
        for season: SeasonOfYear,
        timeOfDay: String
    ) -> ResolvedLocationSceneContent {
        let seasonName: String

        switch season {
        case .spring: seasonName = "spring"
        case .summer: seasonName = "summer"
        case .fall: seasonName = "fall"
        case .winter: seasonName = "winter"
        }

        return .image(
            name: "neighborhood_\(seasonName)_\(timeOfDay)",
            aspectRatio: 2.0 / 3.0
        )
    }

    private func simulationBackground(
        for context: LocationSceneContext
    ) -> ResolvedLocationSceneContent {
        let imageName: String

        switch (context.seasonOfYear, context.weatherCondition) {
        case (.spring, .rain):
            imageName = "neighborhood_summer_sim_raining"

        case (.spring, .sunny), (.spring, .cloudy), (.spring, .snow):
            imageName = "neighborhood_spring_sim_sunny"

        case (.summer, .rain):
            imageName = "neighborhood_summer_sim_raining"

        case (.summer, .sunny), (.summer, .cloudy), (.summer, .snow):
            imageName = "neighborhood_summer_sim_sunny"

        case (.fall, .rain):
            imageName = "neighborhood_fall_sim_raining"

        case (.fall, .sunny), (.fall, .cloudy):
            imageName = "neighborhood_fall_sim_sunny"

        case (.fall, .snow), (.winter, .sunny), (.winter, .cloudy),
             (.winter, .rain), (.winter, .snow):
            imageName = "neighborhood_winter_sim_sunny"
        }

        return .image(
            name: imageName,
            aspectRatio: 853.0 / 1844.0
        )
    }

    private func dayStand(
        for productID: ProductID
    ) -> ResolvedLocationSceneContent {
        switch productID {
        case .pies:
            return .image(
                name: "stand_pies",
                aspectRatio: 1210.0 / 1300.0
            )
        case .smoothies:
            return .image(
                name: "stand_smoothies",
                aspectRatio: 1312.0 / 1199.0
            )
        case .hotDogs:
            return .image(
                name: "stand_hotdogs",
                aspectRatio: 1339.0 / 1174.0
            )
        }
    }

    private func simulationStand(
        for productID: ProductID
    ) -> ResolvedLocationSceneContent {
        let imageName: String

        switch productID {
        case .pies:
            imageName = "pies"
        case .smoothies:
            imageName = "smoothies"
        case .hotDogs:
            imageName = "hotdogs"
        }

        return .image(
            name: imageName,
            aspectRatio: 768.0 / 1660.0
        )
    }
}
