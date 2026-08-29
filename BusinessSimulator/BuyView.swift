//
//  BuyView.swift
//  BusinessSimulator
//

import SwiftUI

struct BuyView: View {

    @Environment(\.dismiss) private var dismiss

    let productInventory: ProductInventory
    let currentAmount: Double
    let accent: Color
    let canAffordPurchase: (Int) -> Bool
    let confirmPurchase: (Int) -> Void

    @State private var purchaseQuantity: Int

    init(
        productInventory: ProductInventory,
        currentAmount: Double,
        accent: Color,
        initialPurchaseQuantity: Int = 0,
        canAffordPurchase: @escaping (Int) -> Bool,
        confirmPurchase: @escaping (Int) -> Void
    ) {
        self.productInventory = productInventory
        self.currentAmount = currentAmount
        self.accent = accent
        self.canAffordPurchase = canAffordPurchase
        self.confirmPurchase = confirmPurchase
        self._purchaseQuantity = State(
            initialValue: initialPurchaseQuantity
        )
    }

    private var inventory: Inventory {
        productInventory.inventory
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
        canAffordPurchase(purchaseQuantity + 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 5) {
                titleHeader
                GameIconView(
                    icon: inventory.smallIcon,
                    size: 42
                )
                .accessibilityLabel(inventory.name)
                currentInventorySection
                purchaseInformationSection
                purchaseQuantitySection
                newTotalSection
                confirmButton
            }
            .frame(maxWidth: 360)
            .padding(.horizontal, 24)
            .padding(.top, 6)
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(accent)
                .multilineTextAlignment(.center)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
    }

    private var currentInventorySection: some View {
        informationSection(title: "CURRENT INVENTORY") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    amountText(currentAmount)

                    Text("Makes \(currentProductsPossible) products")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                GameIconView(
                    icon: inventory.smallIcon,
                    size: 40
                )
            }
            .frame(maxWidth: .infinity)
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
            VStack(spacing: 5) {
                HStack(spacing: 0) {
                    quantityButton(
                        systemName: "minus",
                        disabled: purchaseQuantity == 0
                    ) {
                        purchaseQuantity -= 1
                    }

                    Text("\(purchaseQuantity)")
                        .font(.title3)
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
                        .stroke(accent.opacity(0.45), lineWidth: 1)
                }

                HStack(alignment: .top, spacing: 16) {
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
                        .font(.title3)
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
                    .font(.caption)
                    .fontWeight(.semibold)

                amountText(newTotal)

                Text("Makes \(newProductsPossible) products")
                    .font(.caption)
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
            Label("Add to Cart", systemImage: "cart.badge.plus")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
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
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(
                amount,
                format: .number.precision(.fractionLength(0...2))
            )
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.green)

            if let unit = inventory.purchaseUnit {
                Text(unit)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
        }
    }

    private func informationSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)

            content()
        }
        .padding(7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
    }

    private func informationTile(
        title: String,
        value: String,
        systemName: String
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)

            HStack {
                Image(systemName: systemName)
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .padding(4)
        .background(.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.4), lineWidth: 1)
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
                .frame(width: 62, height: 44)
                .contentShape(Rectangle())
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
                .font(.title3)
                .fontWeight(.bold)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
