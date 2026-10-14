import SwiftUI

struct MarketingSceneCatalog: SceneCatalog {
    private enum Layout {
        static let levelOneSourceWidth: CGFloat = 250
        static let levelOnePosition = CGPoint(x: 300, y: 390)
        static let levelTwoSourceWidth: CGFloat = 250
        static let levelTwoPosition = CGPoint(x: 565, y: 390)
        static let levelThreeSourceWidth: CGFloat = 250
        static let levelThreePosition = CGPoint(x: 300, y: 680)
        static let levelFourSourceWidth: CGFloat = 250
        static let levelFourPosition = CGPoint(x: 565, y: 680)
        static let levelFiveSourceWidth: CGFloat = 400
        static let levelFivePosition = CGPoint(x: 432, y: 535)
    }

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

    private let canvassing = DepartmentSceneAsset(
        id: "canvassing",
        imageName: "canvassing_asset",
        type: .element(
            sourceWidth: Layout.levelOneSourceWidth,
            position: Layout.levelOnePosition
        ),
        layerOrder: 100
    )

    private let clubhouseAdvertisement = DepartmentSceneAsset(
        id: "clubhouse-advertisement",
        imageName: "clubhouse_asset",
        type: .element(
            sourceWidth: Layout.levelOneSourceWidth,
            position: Layout.levelOnePosition
        ),
        layerOrder: 100
    )

    private let neighborhoodFlyers = DepartmentSceneAsset(
        id: "neighborhood-flyers",
        imageName: "neighborhood_flyers_asset",
        type: .element(
            sourceWidth: Layout.levelOneSourceWidth,
            position: Layout.levelOnePosition
        ),
        layerOrder: 100
    )

    private var levelOneAdvertisements: [String: DepartmentSceneAsset] { [
        "canvassing": canvassing,
        "clubhouse-advertisement": clubhouseAdvertisement,
        "neighborhood-flyers": neighborhoodFlyers
    ] }

    private let neighborhoodPicnic = DepartmentSceneAsset(
        id: "block-party-sponsorship",
        imageName: "neighborhood_picnic_asset",
        type: .element(
            sourceWidth: Layout.levelTwoSourceWidth,
            position: Layout.levelTwoPosition
        ),
        layerOrder: 100
    )

    private let neighborhoodGazette = DepartmentSceneAsset(
        id: "neighborhood-gazette-advertisement",
        imageName: "neighborhood_gazette_asset",
        type: .element(
            sourceWidth: Layout.levelTwoSourceWidth,
            position: Layout.levelTwoPosition
        ),
        layerOrder: 100
    )

    private var levelTwoAdvertisements: [String: DepartmentSceneAsset] { [
        "block-party-sponsorship": neighborhoodPicnic,
        "neighborhood-gazette-advertisement": neighborhoodGazette
    ] }

    private let newspaperAdvertisement = DepartmentSceneAsset(
        id: "town-newspaper-advertisement",
        imageName: "newspaper_asset",
        type: .element(
            sourceWidth: Layout.levelThreeSourceWidth,
            position: Layout.levelThreePosition
        ),
        layerOrder: 100
    )

    private let socialMediaAdvertisement = DepartmentSceneAsset(
        id: "social-media-advertisement",
        imageName: "social_media_asset",
        type: .element(
            sourceWidth: Layout.levelThreeSourceWidth,
            position: Layout.levelThreePosition
        ),
        layerOrder: 100
    )

    private var levelThreeAdvertisements: [String: DepartmentSceneAsset] { [
        "town-newspaper-advertisement": newspaperAdvertisement,
        "social-media-advertisement": socialMediaAdvertisement
    ] }

    private let beachVolleyballSponsorship = DepartmentSceneAsset(
        id: "beach-volleyball-sponsorship",
        imageName: "sponsorship_asset",
        type: .element(
            sourceWidth: Layout.levelFourSourceWidth,
            position: Layout.levelFourPosition
        ),
        layerOrder: 100
    )

    private let youthBaseballSponsorship = DepartmentSceneAsset(
        id: "youth-baseball-sponsorship",
        imageName: "sponsorship_asset",
        type: .element(
            sourceWidth: Layout.levelFourSourceWidth,
            position: Layout.levelFourPosition
        ),
        layerOrder: 100
    )

    private let harvestEventSponsorship = DepartmentSceneAsset(
        id: "harvest-event-sponsorship",
        imageName: "sponsorship_asset",
        type: .element(
            sourceWidth: Layout.levelFourSourceWidth,
            position: Layout.levelFourPosition
        ),
        layerOrder: 100
    )

    private let fitnessInfluencerPartnership = DepartmentSceneAsset(
        id: "fitness-influencer-partnership",
        imageName: "influencer_asset",
        type: .element(
            sourceWidth: Layout.levelFourSourceWidth,
            position: Layout.levelFourPosition
        ),
        layerOrder: 100
    )

    private let sportsPodcastPartnership = DepartmentSceneAsset(
        id: "sports-podcast-partnership",
        imageName: "influencer_asset",
        type: .element(
            sourceWidth: Layout.levelFourSourceWidth,
            position: Layout.levelFourPosition
        ),
        layerOrder: 100
    )

    private let gardeningPodcastPartnership = DepartmentSceneAsset(
        id: "gardening-podcast-partnership",
        imageName: "influencer_asset",
        type: .element(
            sourceWidth: Layout.levelFourSourceWidth,
            position: Layout.levelFourPosition
        ),
        layerOrder: 100
    )

    private let billboardAdvertisement = DepartmentSceneAsset(
        id: "billboard-advertisement",
        imageName: "billboard_asset",
        type: .element(
            sourceWidth: Layout.levelFourSourceWidth,
            position: Layout.levelFourPosition
        ),
        layerOrder: 100
    )

    private var smoothieLevelFourAdvertisements: [
        String: DepartmentSceneAsset
    ] { [
        "beach-volleyball-sponsorship": beachVolleyballSponsorship,
        "fitness-influencer-partnership": fitnessInfluencerPartnership,
        "billboard-advertisement": billboardAdvertisement
    ] }

    private var hotDogLevelFourAdvertisements: [
        String: DepartmentSceneAsset
    ] { [
        "youth-baseball-sponsorship": youthBaseballSponsorship,
        "sports-podcast-partnership": sportsPodcastPartnership,
        "billboard-advertisement": billboardAdvertisement
    ] }

    private var pieLevelFourAdvertisements: [
        String: DepartmentSceneAsset
    ] { [
        "harvest-event-sponsorship": harvestEventSponsorship,
        "gardening-podcast-partnership": gardeningPodcastPartnership,
        "billboard-advertisement": billboardAdvertisement
    ] }

    private let radioAdvertisement = DepartmentSceneAsset(
        id: "radio-advertisement",
        imageName: "radio_asset",
        type: .element(
            sourceWidth: Layout.levelFiveSourceWidth,
            position: Layout.levelFivePosition
        ),
        layerOrder: 200
    )

    private var levelFiveAdvertisements: [String: DepartmentSceneAsset] { [
        "radio-advertisement": radioAdvertisement
    ] }

    private var commonAdvertisements: [String: DepartmentSceneAsset] {
        levelOneAdvertisements
            .merging(levelTwoAdvertisements) { _, levelTwoAdvertisement in
                levelTwoAdvertisement
            }
            .merging(levelThreeAdvertisements) { _, levelThreeAdvertisement in
                levelThreeAdvertisement
            }
            .merging(levelFiveAdvertisements) { _, levelFiveAdvertisement in
                levelFiveAdvertisement
            }
    }

    private func advertisements(
        including levelFourAdvertisements: [String: DepartmentSceneAsset]
    ) -> [String: DepartmentSceneAsset] {
        commonAdvertisements.merging(levelFourAdvertisements) {
            _, levelFourAdvertisement in levelFourAdvertisement
        }
    }

    var cumulativeAssets: CumulativeSceneAssets { [
        .pies: [
            .advertisement: advertisements(
                including: pieLevelFourAdvertisements
            )
        ],
        .hotDogs: [
            .advertisement: advertisements(
                including: hotDogLevelFourAdvertisements
            )
        ],
        .smoothies: [
            .advertisement: advertisements(
                including: smoothieLevelFourAdvertisements
            )
        ]
    ] }
}
