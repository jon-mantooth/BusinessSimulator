//
//  PrepView.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/20/26.
//

import SwiftUI

struct PrepInventoryProjection {

    static func productsPossible(
        for productInventoryState: ProductInventoryState,
        currentAmount: Double,
        purchaseQuantity: Int
    ) -> Int {
        let inventory = productInventoryState.productInventory.inventory
        let projectedAmount = currentAmount
            + Double(purchaseQuantity * inventory.purchaseAmount)
        let recipeAmount = productInventoryState.effectiveRecipeAmount

        guard recipeAmount > 0 else { return 0 }

        return Int(floor(projectedAmount / recipeAmount))
    }

    static func limitingProductCount(
        productInventoryStates: [ProductInventoryState],
        currentAmounts: [InventoryType: Double],
        purchaseAmounts: [InventoryType: Int]
    ) -> Int? {
        activeProductCounts(
            productInventoryStates: productInventoryStates,
            currentAmounts: currentAmounts,
            purchaseAmounts: purchaseAmounts
        )
        .map(\.count)
        .min()
    }

    static func limitingIngredientIDs(
        productInventoryStates: [ProductInventoryState],
        currentAmounts: [InventoryType: Double],
        purchaseAmounts: [InventoryType: Int]
    ) -> Set<InventoryType> {
        let productCounts = activeProductCounts(
            productInventoryStates: productInventoryStates,
            currentAmounts: currentAmounts,
            purchaseAmounts: purchaseAmounts
        )

        guard let minimumCount = productCounts.map(\.count).min() else {
            return []
        }

        return Set(
            productCounts
                .filter { $0.count == minimumCount }
                .map(\.id)
        )
    }

    private static func activeProductCounts(
        productInventoryStates: [ProductInventoryState],
        currentAmounts: [InventoryType: Double],
        purchaseAmounts: [InventoryType: Int]
    ) -> [(id: InventoryType, count: Int)] {
        productInventoryStates.compactMap { productInventoryState in
            guard productInventoryState.isActive else { return nil }

            let inventoryType = productInventoryState.id
            return (
                id: inventoryType,
                count: productsPossible(
                    for: productInventoryState,
                    currentAmount: currentAmounts[
                        inventoryType,
                        default: 0
                    ],
                    purchaseQuantity: purchaseAmounts[
                        inventoryType,
                        default: 0
                    ]
                )
            )
        }
    }
}

struct PrepView: View {
    
    let product: Product
    let productInventoryStates: [ProductInventoryState]
    let initialPrice: Double
    let currentAmounts: [InventoryType: Double]
    let handleStartDay: ([InventoryType: Int], String, Double) -> Void
    let updateDisplayedBalance: (Double) -> Void
    let canAffordPurchase: (Double) -> Bool
    let onPriceEditingChanged: (Bool) -> Void
    
    //a dictionary mapping the amount for purchase to the ingredient
    @State private var purchaseAmounts: [InventoryType: Int] = [:]
    @State private var selectedProductInventoryState: ProductInventoryState?

    //a real time running total of costs so the player can see how their
    //inventory decisions will affect their total balance before making a final decision 
    private var projectedCost: Double {
        productInventoryStates.reduce(0) { total, productInventoryState in
            let productInventory = productInventoryState.productInventory
            let inventory = productInventory.inventory
            let quantity = purchaseAmounts[inventory.type, default: 0]

            return total + Double(quantity) * inventory.pricePerUnit
        }
    }

    private var limitingProductCount: Int? {
        PrepInventoryProjection.limitingProductCount(
            productInventoryStates: productInventoryStates,
            currentAmounts: currentAmounts,
            purchaseAmounts: purchaseAmounts
        )
    }
    @State private var showingInstructions = false
    @State private var priceDigits: String
    @FocusState private var isPriceFieldFocused: Bool

    init(
        product: Product,
        productInventoryStates: [ProductInventoryState],
        initialPrice: Double,
        currentAmounts: [InventoryType: Double],
        handleStartDay: @escaping ([InventoryType: Int], String, Double) -> Void,
        updateDisplayedBalance: @escaping (Double) -> Void,
        canAffordPurchase: @escaping (Double) -> Bool,
        onPriceEditingChanged: @escaping (Bool) -> Void
    ) {
        self.product = product
        self.productInventoryStates = productInventoryStates
        self.initialPrice = initialPrice
        self.currentAmounts = currentAmounts
        self.handleStartDay = handleStartDay
        self.updateDisplayedBalance = updateDisplayedBalance
        self.canAffordPurchase = canAffordPurchase
        self.onPriceEditingChanged = onPriceEditingChanged

        let initialPriceInCents = Int((initialPrice * 100).rounded())
        self._priceDigits = State(
            initialValue: initialPriceInCents > 0
                ? String(initialPriceInCents)
                : ""
        )
    }

    private var price: Double {
        Double(Int(priceDigits) ?? 0) / 100
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    header

                    VStack(spacing: 7) {
                        ingredientColumnHeader

                        ForEach(productInventoryStates) {
                            productInventoryState in
                            let productInventory =
                                productInventoryState.productInventory
                            inventoryRow(
                                productInventoryState:
                                    productInventoryState,
                                currentAmount: currentAmounts[productInventory.inventory.type, default: 0],
                                purchaseAmount: purchaseAmounts[
                                    productInventory.inventory.type,
                                    default: 0
                                ]
                            )
                        }
                    }

                    priceSection
                        .id("price-section")

                    Button {
                        handleStartDay(
                            purchaseAmounts,
                            String(price),
                            projectedCost
                        )
                    } label: {
                        Label("Start Day", systemImage: "play.fill")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 3)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)
                    .disabled(price <= 0)
                }
                .frame(maxWidth: 700)
                .padding(12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.97, blue: 0.86),
                            Color(red: 1.0, green: 0.91, blue: 0.68)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(product.accent.opacity(0.65), lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .onChange(of: isPriceFieldFocused) {
                onPriceEditingChanged(isPriceFieldFocused)

                if isPriceFieldFocused {
                    withAnimation {
                        proxy.scrollTo("price-section", anchor: .center)
                    }
                }
            }
            .onChange(of: purchaseAmounts) {
                updateDisplayedBalance(projectedCost)
            }
            .sheet(item: $selectedProductInventoryState) {
                productInventoryState in
                let productInventory =
                    productInventoryState.productInventory
                let inventory = productInventory.inventory
                let inventoryType = inventory.type
                let initialQuantity = purchaseAmounts[
                    inventoryType,
                    default: 0
                ]
                let currentIngredientCost =
                    Double(initialQuantity) * inventory.pricePerUnit

                BuyView(
                    productInventoryState: productInventoryState,
                    currentAmount: currentAmounts[
                        inventoryType,
                        default: 0
                    ],
                    accent: product.accent,
                    initialPurchaseQuantity: initialQuantity,
                    canAffordPurchase: { proposedQuantity in
                        let proposedIngredientCost =
                            Double(proposedQuantity)
                            * inventory.pricePerUnit
                        let proposedTotalCost =
                            projectedCost
                            - currentIngredientCost
                            + proposedIngredientCost

                        return canAffordPurchase(proposedTotalCost)
                    }
                ) { confirmedQuantity in
                    purchaseAmounts[inventoryType] = confirmedQuantity
                }
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        isPriceFieldFocused = false
                    }
                }
            }
        }
    }
    
    private var header: some View {
        ZStack {
            HStack(spacing: 10) {
                GameIconView(
                    icon: product.smallIcon,
                    size: 36
                )

                Text(product.pluralName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(product.accent)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 50)

            HStack {
                Spacer()

                Button {
                    showingInstructions = true
                } label: {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.title2)
                }
                .help(product.productLine.instructionLabel)
                .sheet(isPresented: $showingInstructions) {
                    InstructionsView(
                        product: product,
                        productInventoryStates: productInventoryStates
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 2)
    }

    private var ingredientColumnHeader: some View {
        HStack(spacing: 8) {
            Text(product.productLine.inputLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("On Hand")
                .frame(width: 54)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("After Buy")
                .frame(width: 66)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("Makes")
                .frame(width: 54)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Color.clear
                .frame(width: 16)
        }
        .font(.caption)
        .fontWeight(.bold)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
    }

    private var priceSection: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("Makes")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Text(
                    "\(limitingProductCount ?? 0) \(product.pluralName)"
                )
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(product.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text("Unit Price")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                ZStack(alignment: .trailing) {
                    Text(
                        price,
                        format: .currency(code: "USD")
                    )
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)

                    TextField("", text: $priceDigits)
                        .keyboardType(.numberPad)
                        .focused($isPriceFieldFocused)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.clear)
                        .tint(.clear)
                        .accessibilityLabel("Unit price")
                        .accessibilityValue(
                            price.formatted(.currency(code: "USD"))
                        )
                        .padding(.horizontal, 10)

                    if isPriceFieldFocused && !priceDigits.isEmpty {
                        Button {
                            priceDigits = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Clear price")
                    }
                }
                .frame(width: 120, height: 38)
                .background(.white.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(product.accent.opacity(0.45), lineWidth: 1)
                }
                .onChange(of: priceDigits) {
                    let digitsOnly = priceDigits.filter { $0.isNumber }

                    if priceDigits != digitsOnly {
                        priceDigits = digitsOnly
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(8)
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    private func inventoryRow(
        productInventoryState: ProductInventoryState,
        currentAmount: Double,
        purchaseAmount: Int
    ) -> some View {
        let productInventory = productInventoryState.productInventory
        let inventory = productInventory.inventory
        let totalAmount = currentAmount
            + Double(purchaseAmount * inventory.purchaseAmount)

        return Button {
            selectedProductInventoryState = productInventoryState
        } label: {
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    GameIconView(
                        icon: inventory.smallIcon,
                        size: 26
                    )
                        .frame(width: 32, height: 30)

                    Text(inventory.name)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity)

                inventoryAmount(
                    currentAmount,
                    unit: inventory.purchaseUnit
                )
                .frame(width: 54)

                inventoryAmount(
                    totalAmount,
                    unit: inventory.purchaseUnit,
                    highlighted: true
                )
                .frame(width: 66)

                productsPossible(
                    with: totalAmount,
                    productInventoryState: productInventoryState
                )
                .frame(width: 54)

                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                    .frame(width: 16)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(product.accent.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func inventoryAmount(
        _ amount: Double,
        unit: String?,
        highlighted: Bool = false
    ) -> some View {
        VStack(spacing: 1) {
            Text(
                amount,
                format: .number.precision(.fractionLength(0...2))
            )
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(
                highlighted ? Color.green : Color.primary
            )

            Text(unit ?? "units")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func productsPossible(
        with amount: Double,
        productInventoryState: ProductInventoryState
    ) -> some View {
        let recipeAmount = productInventoryState.effectiveRecipeAmount
        let productCount = recipeAmount > 0
            ? Int(floor(amount / recipeAmount))
            : 0
        let isLimitingIngredient = productCount == limitingProductCount

        return VStack(spacing: 1) {
            Text(productCount, format: .number)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(
                    isLimitingIngredient ? Color.red : Color.green
                )

            Text(product.pluralName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    private func projectedProductsPossible(
        for productInventoryState: ProductInventoryState
    ) -> Int {
        PrepInventoryProjection.productsPossible(
            for: productInventoryState,
            currentAmount: currentAmounts[
                productInventoryState.id,
                default: 0
            ],
            purchaseQuantity: purchaseAmounts[
                productInventoryState.id,
                default: 0
            ]
        )
    }

}
