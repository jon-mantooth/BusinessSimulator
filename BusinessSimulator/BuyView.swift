//
//  BuyView.swift
//  BusinessSimulator
//

import SwiftUI

struct BuyView: View {

    @Environment(\.dismiss) private var dismiss

    let inventoryState: InventoryState
    let productInventory: ProductInventory
    let availableBudget: Double
    let confirmPurchase: (Int) -> Void

    @State private var purchaseQuantity: Int

    init(
        inventoryState: InventoryState,
        productInventory: ProductInventory,
        availableBudget: Double,
        initialPurchaseQuantity: Int = 0,
        confirmPurchase: @escaping (Int) -> Void
    ) {
        self.inventoryState = inventoryState
        self.productInventory = productInventory
        self.availableBudget = availableBudget
        self.confirmPurchase = confirmPurchase
        self._purchaseQuantity = State(
            initialValue: initialPurchaseQuantity
        )
    }

    private var inventory: Inventory {
        productInventory.inventory
    }

    private var currentAmount: Double {
        inventoryState.inventoryByAge.totalInventory
            * Double(inventory.purchaseAmount)
    }

    private var purchaseAmount: Double {
        Double(purchaseQuantity * inventory.purchaseAmount)
    }

    private var purchaseCost: Double {
        Double(purchaseQuantity) * inventory.pricePerUnit
    }

    private var newTotal: Double {
        currentAmount + purchaseAmount
    }

    private var currentProductsPossible: Int {
        productsPossible(with: currentAmount)
    }

    private var newProductsPossible: Int {
        productsPossible(with: newTotal)
    }

    private var canIncreasePurchase: Bool {
        purchaseCost + inventory.pricePerUnit <= availableBudget
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                titleHeader
                ingredientImage
                currentInventorySection
                purchaseInformationSection
                purchaseQuantitySection
                newTotalSection
                confirmButton
            }
            .frame(maxWidth: 700)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.97, blue: 0.86),
                    Color(red: 1.0, green: 0.91, blue: 0.68)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var titleHeader: some View {
        HStack {
            dismissButton(systemName: "chevron.left")

            Spacer()

            Text(inventory.name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Spacer()

            Color.clear
                .frame(width: 48, height: 48)
        }
    }

    private var ingredientImage: some View {
        GameIconView(
            icon: inventory.smallIcon,
            size: 64
        )
            .accessibilityLabel(inventory.name)
    }

    private var currentInventorySection: some View {
        informationSection(title: "CURRENT INVENTORY") {
            VStack(alignment: .leading, spacing: 2) {
                amountText(currentAmount)

                Text("Makes \(currentProductsPossible) products")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var purchaseInformationSection: some View {
        informationSection(title: "PURCHASE INFORMATION") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 8
            ) {
                informationTile(
                    title: "Purchase Unit",
                    value: inventory.purchaseAmountLabel,
                    systemName: "scalemass"
                )

                informationTile(
                    title: "Unit Cost",
                    value: inventory.pricePerUnit.formatted(
                        .currency(code: "USD")
                    ),
                    systemName: "tag"
                )

                informationTile(
                    title: "Recipe Amount",
                    value: productInventory.recipeAmountLabel,
                    systemName: "fork.knife"
                )

                informationTile(
                    title: "Shelf Life",
                    value: shelfLifeLabel,
                    systemName: "calendar"
                )
            }
        }
    }

    private var purchaseQuantitySection: some View {
        informationSection(title: "HOW MANY UNITS?") {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    quantityButton(
                        systemName: "minus",
                        disabled: purchaseQuantity == 0
                    ) {
                        purchaseQuantity -= 1
                    }

                    Text("\(purchaseQuantity)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)

                    quantityButton(
                        systemName: "plus",
                        disabled: !canIncreasePurchase
                    ) {
                        purchaseQuantity += 1
                    }
                }
                .frame(maxWidth: 340)
                .background(.white.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.orange.opacity(0.45), lineWidth: 1)
                }

                HStack(alignment: .top, spacing: 24) {
                    VStack(spacing: 2) {
                        Text("You're buying")
                            .font(.caption)
                            .fontWeight(.semibold)

                        amountText(purchaseAmount)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 2) {
                        Text("Purchase Cost")
                            .font(.caption)
                            .fontWeight(.semibold)

                        Text(
                            purchaseCost,
                            format: .currency(code: "USD")
                        )
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var newTotalSection: some View {
        informationSection(title: "NEW TOTAL") {
            VStack(alignment: .leading, spacing: 2) {
                Text("New Total After Purchase")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                amountText(newTotal)

                Text("Makes \(newProductsPossible) products")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var confirmButton: some View {
        Button {
            confirmPurchase(purchaseQuantity)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                GameIconView(
                    icon: inventory.smallIcon,
                    size: 30
                )

                Text("Confirm Purchase")
            }
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .controlSize(.regular)
    }

    private var shelfLifeLabel: String {
        if inventory.lifespan >= 180 {
            return "Stable"
        }

        return "\(inventory.lifespan) "
            + (inventory.lifespan == 1 ? "day" : "days")
    }

    private func productsPossible(with amount: Double) -> Int {
        guard productInventory.recipeAmount > 0 else {
            return 0
        }

        return Int(floor(amount / productInventory.recipeAmount))
    }

    private func amountText(_ amount: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(
                amount,
                format: .number.precision(.fractionLength(0...2))
            )
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(.green)

            if let unit = inventory.purchaseUnit {
                Text(unit)
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
    }

    private func informationSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)

            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.orange.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
    }

    private func informationTile(
        title: String,
        value: String,
        systemName: String
    ) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)

            HStack {
                Image(systemName: systemName)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 62)
        .padding(6)
        .background(.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.orange.opacity(0.35), lineWidth: 1)
        }
    }

    private func quantityButton(
        systemName: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .fontWeight(.bold)
                .frame(width: 64, height: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(disabled ? .gray : .green)
        .disabled(disabled)
    }

    private func dismissButton(systemName: String) -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: systemName)
                .font(.title2)
                .fontWeight(.bold)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
