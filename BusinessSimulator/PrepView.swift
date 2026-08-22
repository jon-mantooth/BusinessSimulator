//
//  PrepView.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/20/26.
//

import SwiftUI

struct PrepView: View {
    
    let product: Product
    let initialPrice: Double
    let currentAmounts: [InventoryType: Double]
    let handleStartDay: ([InventoryType: Int], String, Double) -> Void
    let updateDisplayedBalance: (Double) -> Void
    let canAffordPurchase: (Double) -> Bool
    
    //a dictionary mapping the amount for purchase to the ingredient
    @State private var purchaseAmounts: [InventoryType: Int] = [:]
    @State private var selectedProductInventory: ProductInventory?

    //a real time running total of costs so the player can see how their
    //inventory decisions will affect their total balance before making a final decision 
    private var projectedCost: Double {
        product.productInventories.reduce(0) { total, productInventory in
            let inventory = productInventory.inventory
            let quantity = purchaseAmounts[inventory.type, default: 0]

            return total + Double(quantity) * inventory.pricePerUnit
        }
    }
    @State private var showingInstructions = false
    @State private var priceDigits: String

    init(
        product: Product,
        initialPrice: Double,
        currentAmounts: [InventoryType: Double],
        handleStartDay: @escaping ([InventoryType: Int], String, Double) -> Void,
        updateDisplayedBalance: @escaping (Double) -> Void,
        canAffordPurchase: @escaping (Double) -> Bool
    ) {
        self.product = product
        self.initialPrice = initialPrice
        self.currentAmounts = currentAmounts
        self.handleStartDay = handleStartDay
        self.updateDisplayedBalance = updateDisplayedBalance
        self.canAffordPurchase = canAffordPurchase

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
        ScrollView {
            VStack(spacing: 10) {
                header

                VStack(spacing: 10) {
                    ingredientColumnHeader

                    ForEach(product.productInventories) { productInventory in
                        inventoryRow(
                            productInventory: productInventory,
                            currentAmount: currentAmounts[productInventory.inventory.type, default: 0],
                            purchaseAmount: purchaseAmounts[
                                productInventory.inventory.type,
                                default: 0
                            ]
                        )
                    }
                }

                priceSection

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
                        .padding(.vertical, 6)
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
        .onChange(of: purchaseAmounts) {
            updateDisplayedBalance(projectedCost)
        }
        .sheet(item: $selectedProductInventory) { productInventory in
            let inventory = productInventory.inventory
            let inventoryType = inventory.type
            let initialQuantity = purchaseAmounts[
                inventoryType,
                default: 0
            ]
            let currentIngredientCost =
                Double(initialQuantity) * inventory.pricePerUnit

            BuyView(
                productInventory: productInventory,
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
    }
    
    private var header: some View {
        ZStack {
            HStack(spacing: 10) {
                GameIconView(
                    icon: product.smallIcon,
                    size: 36
                )

                Text(product.name)
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
                    InstructionsView(product: product)
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

            Text("Current")
                .frame(width: 70)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("Total (After Buy)")
                .frame(width: 88)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Color.clear
                .frame(width: 20)
        }
        .font(.caption)
        .fontWeight(.bold)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
    }

    private var priceSection: some View {
        HStack {
            Text("Price per product")
                .font(.headline)

            Spacer()

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
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.clear)
                    .tint(.clear)
                    .accessibilityLabel("Price per product")
                    .accessibilityValue(
                        price.formatted(.currency(code: "USD"))
                    )
                    .padding(.horizontal, 10)
            }
            .frame(width: 120, height: 42)
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
        .padding(10)
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    private func inventoryRow(
        productInventory: ProductInventory,
        currentAmount: Double,
        purchaseAmount: Int
    ) -> some View {
        let inventory = productInventory.inventory
        let totalAmount = currentAmount
            + Double(purchaseAmount * inventory.purchaseAmount)

        return Button {
            selectedProductInventory = productInventory
        } label: {
            HStack(spacing: 8) {
                HStack(spacing: 10) {
                    GameIconView(
                        icon: inventory.smallIcon,
                        size: 32
                    )
                        .frame(width: 42, height: 42)

                    Text(inventory.name)
                        .font(.caption)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)

                inventoryAmount(
                    currentAmount,
                    unit: inventory.purchaseUnit
                )
                .frame(width: 70)

                inventoryAmount(
                    totalAmount,
                    unit: inventory.purchaseUnit,
                    highlighted: true
                )
                .frame(width: 88)

                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                    .frame(width: 20)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
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

}
