import Foundation

struct RelocationDimensionAvailabilityRequest {}

enum RelocationDimensionAvailability: Equatable {
    case available
}

enum RelocationRequirement: CaseIterable, Equatable {
    case storageLevel
    case transportationLevel
    case equipmentLevel
    case laborLevel
    case advertisementLevel
    case businessReputation
    case balance
}

/// The minimum business progress required to relocate to a destination.
struct RelocationRequirements: Equatable {
    let storageLevel: Int
    let transportationLevel: Int
    let equipmentLevel: Int
    let laborLevel: Int
    let advertisementLevel: Int
    let businessReputation: Double
    let balance: Double
}

/// A snapshot of the player's current progress used to evaluate relocation.
/// Storage and transportation can remain nil until those dimensions exist;
/// an unavailable current value never satisfies its requirement.
struct RelocationReadiness: Equatable {
    let storageLevel: Int?
    let transportationLevel: Int?
    let equipmentLevel: Int
    let laborLevel: Int
    let advertisementLevel: Int
    let businessReputation: Double
    let balance: Double
}

struct RelocationRequirementStatus: Equatable {
    let requirement: RelocationRequirement
    let requiredValue: Double
    let currentValue: Double?

    var isMet: Bool {
        guard let currentValue else {
            return false
        }

        return currentValue >= requiredValue
    }
}

enum RelocationItemAvailability: Equatable {
    case available(requirements: [RelocationRequirementStatus])
    case unavailable(requirements: [RelocationRequirementStatus])

    var requirements: [RelocationRequirementStatus] {
        switch self {
        case .available(let requirements),
             .unavailable(let requirements):
            return requirements
        }
    }

    var canRelocate: Bool {
        switch self {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }
}

struct RelocationRequest {
    let destination: Location
    let requirements: RelocationRequirements
    let readiness: RelocationReadiness
}

/// Evaluates whether the business is ready to relocate. Transaction behavior
/// will be added once the immediate and recurring relocation effects have
/// been defined.
struct RelocationWorkflow {
    func dimensionAvailability(
        for request: RelocationDimensionAvailabilityRequest
    ) -> RelocationDimensionAvailability {
        .available
    }

    func itemAvailability(
        for request: RelocationRequest
    ) -> RelocationItemAvailability {
        let requirements = requirementStatuses(for: request)

        if requirements.allSatisfy(\.isMet) {
            return .available(requirements: requirements)
        }

        return .unavailable(requirements: requirements)
    }

    private func requirementStatuses(
        for request: RelocationRequest
    ) -> [RelocationRequirementStatus] {
        let required = request.requirements
        let current = request.readiness

        return [
            RelocationRequirementStatus(
                requirement: .storageLevel,
                requiredValue: Double(required.storageLevel),
                currentValue: current.storageLevel.map { Double($0) }
            ),
            RelocationRequirementStatus(
                requirement: .transportationLevel,
                requiredValue: Double(required.transportationLevel),
                currentValue: current.transportationLevel.map { Double($0) }
            ),
            RelocationRequirementStatus(
                requirement: .equipmentLevel,
                requiredValue: Double(required.equipmentLevel),
                currentValue: Double(current.equipmentLevel)
            ),
            RelocationRequirementStatus(
                requirement: .laborLevel,
                requiredValue: Double(required.laborLevel),
                currentValue: Double(current.laborLevel)
            ),
            RelocationRequirementStatus(
                requirement: .advertisementLevel,
                requiredValue: Double(required.advertisementLevel),
                currentValue: Double(current.advertisementLevel)
            ),
            RelocationRequirementStatus(
                requirement: .businessReputation,
                requiredValue: required.businessReputation,
                currentValue: current.businessReputation
            ),
            RelocationRequirementStatus(
                requirement: .balance,
                requiredValue: required.balance,
                currentValue: current.balance
            )
        ]
    }
}
