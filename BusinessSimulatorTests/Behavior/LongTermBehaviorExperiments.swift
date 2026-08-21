/*
 TODO: This behavior experiment framework is an intentionally disabled outline.
 Rebuild it against the current simulation architecture when behavior testing
 resumes, including demand, market size, variance, and reproducible randomness.

@testable import BusinessSimulator

enum ExperimentDepartmentID {
    case production
    case distribution
    case marketing
    case finance
}

enum ExperimentFactorID {
    case demand
    case variance
    case marketSize
}

typealias ExperimentDimensions = [
    ExperimentFactorID: [
        ExperimentDepartmentID: [any Dimension]
    ]
]

private final class ExperimentDepartment: Department {
    let dimensions: [any Dimension]

    init(dimensions: [any Dimension]) {
        self.dimensions = dimensions
    }

    func calculateDemand() -> Double {
        dimensions.reduce(1.0) { demand, dimension in
            demand * dimension.calculateDemand()
        }
    }
}

func runLongTermBehaviorExperiment(
    productID: ProductID,
    price: Double,
    dimensions: ExperimentDimensions,
    periods: Int
) -> [[String: Double]] {
    precondition(periods > 0, "Periods must be greater than zero.")
    precondition(price > 0, "Price must be greater than zero.")

    guard let product = ProductCatalog().products.first(
        where: { $0.id == productID }
    ) else {
        preconditionFailure("Product \(productID.rawValue) was not found.")
    }

    let productState = ProductState(
        product: product,
        price: price
    )

    let departmentsByFactor = dimensions.mapValues { departments in
        departments.map { _, dimensions in
            ExperimentDepartment(dimensions: dimensions)
        }
    }

    var results: [[String: Double]] = []

    for period in 1...periods {
        let demandDepartments = departmentsByFactor[.demand] ?? []

        let demand = demandDepartments.reduce(1.0) { demand, department in
            demand * department.calculateDemand()
        }

        let revenue = productState.calculateBaselineRevenue(
            demand: demand
        )

        let sales = productState.calculatePredictedSales(
            predictedRevenue: revenue
        )

        results.append([
            "period": Double(period),
            "demand": demand,
            "revenue": revenue,
            "sales": Double(sales)
        ])
    }

    return results
}
*/
