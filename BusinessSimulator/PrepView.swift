//
//  PrepView.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/20/26.
//

import SwiftUI

struct PrepView: View {
    
    let product: Product
    let currentAmounts: [InventoryType: Double]
    let handleStartDay: ([InventoryType: Int], String) -> Void
    let updateDisplayedBalance: (Double) -> Void
    let canAffordPurchase: (Double) -> Bool
    
    //a dictionary mapping the amount for purchase to the ingredient
    @State private var purchaseAmounts: [InventoryType: Int] = [:]

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
    @State private var price = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                
                VStack(spacing: 10) {
                    tableHeader
                    
                    ForEach(product.productInventories) { productInventory in
                        inventoryRow(
                            name: productInventory.inventory.name,
                            unit: productInventory.inventory.purchaseAmountLabel,
                            cost: productInventory.inventory.pricePerUnit,
                            currentAmount: currentAmounts[productInventory.inventory.type, default: 0],
                            purchaseAmount: binding(productInventory.inventory.type),
                            lifespan: productInventory.inventory.lifespan
                        )
                    }
                }
                
                HStack {
                    Text("Price")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    TextField("0.00", text: $price)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }
                
                Button("Start Day") {
                    handleStartDay(purchaseAmounts, price)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                .disabled(Double(price) == nil)
            }
            .frame(maxWidth: 700)
            .padding()
        }
        .onChange(of: purchaseAmounts) {
            updateDisplayedBalance(projectedCost)
        }
    }
    
    private var header: some View {
        ZStack {
            Text(product.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
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
        .padding(.bottom, 8)
    }
    
    private var tableHeader: some View {
        HStack(spacing: 6) {
            Text(product.productLine.inputLabel)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Unit")
                .frame(width: 42)

            Text("Cost")
                .frame(width: 52)
            
            Text("Shelf Life")
                .frame(width: 52)

            Text("Have")
                .frame(width: 42)

            Text("Buy")
                .frame(width: 92)
        }
        .font(.headline)
        .minimumScaleFactor(0.75)
    }
    
    private func binding(_ inventoryType: InventoryType) -> Binding<Int> {
        Binding(
            get: {
                purchaseAmounts[inventoryType, default: 0]
            },
            set: { newValue in
                purchaseAmounts[inventoryType] = newValue
            }
        )
    }
    
    private func inventoryRow(
        name: String,
        unit: String,
        cost: Double,
        currentAmount: Double,
        purchaseAmount: Binding<Int>,
        lifespan: Days
    ) -> some View {
        HStack(spacing: 6) {
            Text(name)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .layoutPriority(1)

            Text(unit)
                .frame(width: 50)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(cost, format: .currency(code: "USD"))
                .frame(width: 52)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(
                lifespan > 100
                ? "Stable"
                : "\(lifespan) \(lifespan == 1 ? "Day" : "Days")"
            )
            .frame(width: 58)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(.secondary)

            Text(currentAmount, format: .number.precision(.fractionLength(2)))
                .frame(width: 42)

            HStack(spacing: 4) {
                Button {
                    if purchaseAmount.wrappedValue > 0 {
                        purchaseAmount.wrappedValue -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14))
                        .frame(width: 28, height: 24)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Text("\(purchaseAmount.wrappedValue)")
                    .frame(minWidth: 20)
                
                Button {
                    let newProjectedCost = projectedCost + cost

                    if canAffordPurchase(newProjectedCost) {
                        purchaseAmount.wrappedValue += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .frame(width: 28, height: 24)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 92)
        }
    }
}
