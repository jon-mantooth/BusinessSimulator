/// Defines the common interface for a workflow without prescribing its
/// domain-specific validation rules or transaction behavior.
protocol Workflow {
    associatedtype DimensionAvailabilityRequest
    associatedtype DimensionAvailability
    associatedtype ItemRequest
    associatedtype ItemAvailability
    associatedtype CompletionResult

    func dimensionAvailability(
        for request: DimensionAvailabilityRequest
    ) -> DimensionAvailability

    func itemAvailability(
        for request: ItemRequest
    ) -> ItemAvailability

    func complete(
        _ request: ItemRequest
    ) -> CompletionResult
}
