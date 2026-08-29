import Testing
@testable import BusinessSimulator

struct AdvertisementTests {}

// MARK: - Advertisement State

extension AdvertisementTests {

    @Test
    func activeTierMatchesActiveAdvertisementTierLevel() throws {
        let advertisementState = try makeAdvertisementState()

        #expect(advertisementState.activeTier?.level == 0)
        #expect(
            advertisementState.activeTier?.advertisements.contains(
                advertisementState.activeAdvertisement!.advertisement
            ) == true
        )
    }

    @Test
    func nextTierIsImmediatelyAfterActiveTier() throws {
        let advertisementState = try makeAdvertisementState()

        #expect(advertisementState.activeTier?.level == 0)
        #expect(advertisementState.nextTier?.level == 1)
    }

    @Test
    func applyingUpgradeActivatesAdvertisementFromNextTier() throws {
        let advertisementState = try makeAdvertisementState()
        let nextTier = try #require(advertisementState.nextTier)
        let selectedAdvertisement = try #require(
            nextTier.advertisements.first
        )

        advertisementState.applyUpgrade(selectedAdvertisement)

        #expect(
            advertisementState.activeAdvertisement?.advertisement
                == selectedAdvertisement
        )
        #expect(
            advertisementState.activeAdvertisement?.tierLevel
                == nextTier.level
        )
        #expect(advertisementState.activeTier == nextTier)
    }

    @Test
    func captureRollbackStateReturnsActiveAdvertisement() throws {
        let advertisementState = try makeAdvertisementState()
        let activeAdvertisement = try #require(
            advertisementState.activeAdvertisement
        )

        let rollbackState = advertisementState.captureRollbackState()

        #expect(rollbackState == activeAdvertisement)
    }

    @Test
    func revertingUpgradeRestoresPreviousAdvertisement() throws {
        let advertisementState = try makeAdvertisementState()
        let rollbackState = advertisementState.captureRollbackState()
        let nextTier = try #require(advertisementState.nextTier)
        let selectedAdvertisement = try #require(
            nextTier.advertisements.first
        )

        advertisementState.applyUpgrade(selectedAdvertisement)
        advertisementState.revertUpgrade(to: rollbackState)

        #expect(advertisementState.activeAdvertisement == rollbackState)
        #expect(
            advertisementState.activeTier?.level
                == rollbackState.tierLevel
        )
    }

    @Test
    func highestTierHasNoNextTier() throws {
        let catalog = AdvertisementCatalog()
        let tiers = try #require(
            catalog.tiersByProduct[.smoothies]
        )
        let highestTier = try #require(
            tiers.max { $0.level < $1.level }
        )
        let highestTierAdvertisement = try #require(
            highestTier.advertisements.first
        )
        let advertisementState = AdvertisementState(
            tiers: tiers,
            activeAdvertisement: ActiveAdvertisement(
                advertisement: highestTierAdvertisement,
                tierLevel: highestTier.level
            )
        )

        #expect(advertisementState.activeTier?.level == highestTier.level)
        #expect(advertisementState.nextTier == nil)
    }
}

// MARK: - Advertisement Catalog and Tiers

extension AdvertisementTests {

    @Test
    func everyProductHasAllAdvertisementTiersInOrder() throws {
        let catalog = AdvertisementCatalog()

        for productID in [ProductID.smoothies, .hotDogs, .pies] {
            let tiers = try #require(catalog.tiersByProduct[productID])

            #expect(tiers.map(\.level) == [0, 1, 2, 3, 4, 5])
        }
    }

    @Test
    func genericTiersContainExpectedAdvertisements() {
        let catalog = AdvertisementCatalog()

        #expect(
            advertisementIDs(in: catalog.tierZero)
                == [catalog.noAdvertisement.id]
        )
        #expect(
            advertisementIDs(in: catalog.tierOne) == [
                catalog.canvassing.id,
                catalog.neighborhoodFlyers.id,
                catalog.clubhouseAdvertisement.id
            ]
        )
        #expect(
            advertisementIDs(in: catalog.tierTwo) == [
                catalog.blockPartySponsorship.id,
                catalog.neighborhoodGazetteAdvertisement.id
            ]
        )
        #expect(
            advertisementIDs(in: catalog.tierThree) == [
                catalog.townNewspaperAdvertisement.id,
                catalog.socialMediaAdvertisement.id
            ]
        )
        #expect(
            advertisementIDs(in: catalog.tierFive)
                == [catalog.radioAdvertisement.id]
        )
    }

    @Test
    func tierFourContainsCorrectProductSpecificAdvertisements() {
        let catalog = AdvertisementCatalog()

        #expect(
            Set(advertisementIDs(in: catalog.smoothieTierFour)) == Set([
                catalog.beachVolleyballSponsorship.id,
                catalog.fitnessInfluencerPartnership.id,
                catalog.billboardAdvertisement.id
            ])
        )
        #expect(
            Set(advertisementIDs(in: catalog.hotDogTierFour)) == Set([
                catalog.youthBaseballSponsorship.id,
                catalog.sportsPodcastPartnership.id,
                catalog.billboardAdvertisement.id
            ])
        )
        #expect(
            Set(advertisementIDs(in: catalog.pieTierFour)) == Set([
                catalog.harvestEventSponsorship.id,
                catalog.gardeningPodcastPartnership.id,
                catalog.billboardAdvertisement.id
            ])
        )
    }

    @Test
    func productSpecificAdvertisementsDoNotLeakBetweenProducts() throws {
        let catalog = AdvertisementCatalog()
        let smoothieTier = try tier(
            level: 4,
            productID: .smoothies,
            catalog: catalog
        )
        let hotDogTier = try tier(
            level: 4,
            productID: .hotDogs,
            catalog: catalog
        )
        let pieTier = try tier(
            level: 4,
            productID: .pies,
            catalog: catalog
        )

        #expect(
            !advertisementIDs(in: smoothieTier).contains(
                catalog.youthBaseballSponsorship.id
            )
        )
        #expect(
            !advertisementIDs(in: hotDogTier).contains(
                catalog.harvestEventSponsorship.id
            )
        )
        #expect(
            !advertisementIDs(in: pieTier).contains(
                catalog.beachVolleyballSponsorship.id
            )
        )
    }

    @Test
    func timeRequiredAdvertisementRemainsFree() throws {
        let catalog = AdvertisementCatalog()
        let canvassing = try #require(
            catalog.tierOne.advertisements.first {
                $0.id == catalog.canvassing.id
            }
        )

        #expect(canvassing.dailyTimeRequired > 0)
        #expect(canvassing.price == 0)
    }

    @Test
    func advertisementsWithoutTimeRequirementReceivePositivePrices() {
        let catalog = AdvertisementCatalog()
        let pricedAdvertisements = [
            catalog.tierOne,
            catalog.tierTwo,
            catalog.tierThree,
            catalog.smoothieTierFour,
            catalog.hotDogTierFour,
            catalog.pieTierFour,
            catalog.tierFive
        ]
            .flatMap(\.advertisements)
            .filter { $0.dailyTimeRequired == 0 }

        #expect(pricedAdvertisements.allSatisfy { $0.price > 0 })
    }

    @Test
    func advertisementEffectScoresUseLevelOverTotalLevels() {
        let advertisement = Advertisement(
            id: AdvertisementID(rawValue: "effect-score-test"),
            name: "Effect Score Test",
            smallIcon: .system("megaphone.fill"),
            description: "Tests advertisement effect scores.",
            paymentSchedule: .oneTime,
            demandLevel: 2,
            marketSizeLevel: 3,
            totalLevels: 5
        )

        #expect(abs(advertisement.demandEffectScore - 0.4) < 0.000_001)
        #expect(abs(advertisement.marketSizeEffectScore - 0.6) < 0.000_001)
    }
}

// MARK: - Advertisement Purchase Integration

extension AdvertisementTests {

    @Test
    func successfulPurchaseActivatesSelectedAdvertisement() throws {
        let gameState = makeInitializedGameState()
        let advertisementState = try #require(gameState.advertisementState)
        let previousAdvertisement = try #require(
            advertisementState.activeAdvertisement
        )
        let selectedAdvertisement = try #require(
            advertisementState.nextTier?.advertisements.first
        )
        let repository = AdvertisementPurchaseTestRepository()
        let workflow = PurchaseWorkflow(
            gameState: gameState,
            saveRepository: repository
        )

        let result = workflow.completePurchase(
            state: advertisementState,
            item: selectedAdvertisement
        )

        guard case .completed = result else {
            Issue.record("Expected the advertisement purchase to complete.")
            return
        }
        #expect(
            advertisementState.activeAdvertisement?.advertisement
                == selectedAdvertisement
        )
        #expect(
            advertisementState.activeAdvertisement != previousAdvertisement
        )
        #expect(repository.savedGame != nil)
    }

    @Test
    func failedPurchaseSaveRestoresPreviousAdvertisement() throws {
        let gameState = makeInitializedGameState()
        let advertisementState = try #require(gameState.advertisementState)
        let previousAdvertisement = try #require(
            advertisementState.activeAdvertisement
        )
        let selectedAdvertisement = try #require(
            advertisementState.nextTier?.advertisements.first
        )
        let repository = AdvertisementPurchaseTestRepository(
            shouldFailSave: true
        )
        let workflow = PurchaseWorkflow(
            gameState: gameState,
            saveRepository: repository
        )

        let result = workflow.completePurchase(
            state: advertisementState,
            item: selectedAdvertisement
        )

        guard case .saveFailed = result else {
            Issue.record("Expected the advertisement save to fail.")
            return
        }
        #expect(
            advertisementState.activeAdvertisement == previousAdvertisement
        )
        #expect(gameState.pendingBusinessEvents.isEmpty)
        #expect(
            gameState.upgradeTracker.canUpgrade(
                .advertisement,
                on: gameState.calendar.simulationDay
            )
        )
    }
}

private func makeAdvertisementState(
    productID: ProductID = .smoothies
) throws -> AdvertisementState {
    let catalog = AdvertisementCatalog()
    let tiers = try #require(catalog.tiersByProduct[productID])
    let startingTier = try #require(
        tiers.first { $0.level == 0 }
    )
    let startingAdvertisement = try #require(
        startingTier.advertisements.first
    )

    return AdvertisementState(
        tiers: tiers,
        activeAdvertisement: ActiveAdvertisement(
            advertisement: startingAdvertisement,
            tierLevel: startingTier.level
        )
    )
}

private func advertisementIDs(
    in tier: AdvertisementTier
) -> [AdvertisementID] {
    tier.advertisements.map(\.id)
}

private func tier(
    level: Int,
    productID: ProductID,
    catalog: AdvertisementCatalog
) throws -> AdvertisementTier {
    let tiers = try #require(catalog.tiersByProduct[productID])
    return try #require(tiers.first { $0.level == level })
}

private func makeInitializedGameState() -> GameState {
    let product = ProductCatalog().products.first {
        $0.id == .smoothies
    }!
    let gameState = GameState()
    gameState.initializeBusiness(product: product)
    return gameState
}

private enum AdvertisementPurchaseTestError: Error {
    case saveFailed
}

private final class AdvertisementPurchaseTestRepository:
    GameSaveRepository {
    private let shouldFailSave: Bool
    private(set) var savedGame: GameSave?

    init(shouldFailSave: Bool = false) {
        self.shouldFailSave = shouldFailSave
    }

    func save(_ gameSave: GameSave) throws {
        if shouldFailSave {
            throw AdvertisementPurchaseTestError.saveFailed
        }

        savedGame = gameSave
    }

    func load() throws -> GameSave? {
        savedGame
    }

    func hasSave() -> Bool {
        savedGame != nil
    }

    func deleteSave() throws {
        savedGame = nil
    }
}
