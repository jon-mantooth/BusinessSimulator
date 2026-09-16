import Foundation

struct LaborCatalog {
    static let demandWeight = 0.18

    let grillMaster: Labor
    let baker: Labor
    let mixologist: Labor
    let prepCook: Labor
    let lineCook: Labor
    let cleanupWorker: Labor

    init() {
        grillMaster = Labor(
            id: LaborID(rawValue: "grill-master"),
            name: "Grill Master",
            smallIcon: .system("flame.fill"),
            description: "An experienced grill cook who keeps hot dogs moving quickly and consistently.",
            demandLevel: 2
        )

        baker = Labor(
            id: LaborID(rawValue: "baker"),
            name: "Baker",
            smallIcon: .system("birthday.cake.fill"),
            description: "A skilled baker who produces dependable pies while managing the ovens efficiently.",
            demandLevel: 2
        )

        mixologist = Labor(
            id: LaborID(rawValue: "mixologist"),
            name: "Mixologist",
            smallIcon: .system("takeoutbag.and.cup.and.straw.fill"),
            description: "A smoothie specialist who blends drinks quickly and delivers consistent quality.",
            demandLevel: 2
        )

        prepCook = Labor(
            id: LaborID(rawValue: "prep-cook"),
            name: "Prep Cook",
            smallIcon: .system("fork.knife"),
            description: "Prepares ingredients ahead of service so production can continue without interruption.",
            demandLevel: 1
        )

        lineCook = Labor(
            id: LaborID(rawValue: "line-cook"),
            name: "Line Cook",
            smallIcon: .system("frying.pan.fill"),
            description: "Supports daily production wherever extra hands are needed during busy service periods.",
            demandLevel: 1
        )

        cleanupWorker = Labor(
            id: LaborID(rawValue: "cleanup-worker"),
            name: "Cleanup Worker",
            smallIcon: .system("sparkles"),
            description: "Keeps work areas clean and organized so the rest of the team can stay productive.",
            demandLevel: 1
        )
    }

    /// Returns the product specialist followed by the three shared workers.
    /// Capacity values are additive contributions above the player's baseline.
    func labor(
        for product: Product
    ) -> [Labor] {
        var primaryLabor: Labor

        switch product.id {
        case .hotDogs:
            primaryLabor = grillMaster
        case .pies:
            primaryLabor = baker
        case .smoothies:
            primaryLabor = mixologist
        }

        primaryLabor.capacity = capacity(
            ratio: LaborCapacityBalance.specialistRatio,
            idealUnitsSold: product.idealUnitsSold
        )
        primaryLabor.price = wage(
            for: primaryLabor,
            product: product
        )

        let secondaryLabor = [
            prepCook,
            lineCook,
            cleanupWorker
        ].map { labor in
            var configuredLabor = labor
            configuredLabor.capacity = capacity(
                ratio: LaborCapacityBalance.sharedWorkerRatio,
                idealUnitsSold: product.idealUnitsSold
            )
            configuredLabor.price = wage(
                for: configuredLabor,
                product: product
            )
            return configuredLabor
        }

        return [primaryLabor] + secondaryLabor
    }

    private func capacity(
        ratio: Double,
        idealUnitsSold: Int
    ) -> Int {
        LaborCapacityBalance.capacity(
            ratio: ratio,
            baseIdealUnitsSold: idealUnitsSold
        )
    }

    private func wage(
        for labor: Labor,
        product: Product
    ) -> Double {
        let dailyBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            demandEffectScore: labor.demandEffectScore,
            demandWeight: Self.demandWeight,
            capacityEffect: .additive(labor.capacity)
        )

        return UpgradePricing.calculatePrice(
            dailyBenefit: dailyBenefit,
            paymentSchedule: labor.paymentSchedule,
            tierLevel: 1
        ).rounded()
    }
}
