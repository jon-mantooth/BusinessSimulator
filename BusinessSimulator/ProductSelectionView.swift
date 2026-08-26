//
//  ProductSelectionView.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/18/26.
//

import SwiftUI

struct ProductSelectionView: View {
    let products: [Product]
    let onSelectionChanged: (Product) -> Void
    let onContinue: (Product) -> Void

    @State private var selectedProduct: Product?

    private let darkBrown = Color(red: 0.23, green: 0.12, blue: 0.06)
    private let gold = Color(red: 0.82, green: 0.54, blue: 0.20)
    private let cream = Color(red: 1.0, green: 0.97, blue: 0.89)

    var body: some View {
        ScrollView {
            VStack(spacing: 9) {
                Text("Select Your Product")
                    .font(.system(.title, design: .serif))
                    .fontWeight(.bold)
                    .foregroundStyle(darkBrown)

                Text("Select the product your company\nwill specialize in.")
                    .font(.subheadline)
                    .foregroundStyle(darkBrown.opacity(0.82))
                    .multilineTextAlignment(.center)

                decorativeDivider

                VStack(spacing: 7) {
                    ForEach(products) { product in
                        productCard(for: product)
                    }
                }

                continueButton
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [
                        cream,
                        Color(red: 1.0, green: 0.93, blue: 0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(gold.opacity(0.8), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            .frame(maxWidth: 350)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    private var decorativeDivider: some View {
        HStack(spacing: 7) {
            Rectangle()
                .frame(width: 48, height: 1)

            Image(systemName: "heart")
                .font(.caption)

            Rectangle()
                .frame(width: 48, height: 1)
        }
        .foregroundStyle(gold.opacity(0.75))
    }

    private var continueButton: some View {
        Button {
            if let selectedProduct {
                onContinue(selectedProduct)
            }
        } label: {
            Text("Continue")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(darkBrown)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.80, blue: 0.37),
                    Color(red: 0.95, green: 0.60, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(gold, lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
        .frame(maxWidth: 210)
        .disabled(selectedProduct == nil)
        .opacity(selectedProduct == nil ? 0.55 : 1)
    }

    private func productCard(for product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id

        return Button {
            selectedProduct = product
            onSelectionChanged(product)
        } label: {
            HStack(spacing: 9) {
                GameIconView(
                    icon: product.smallIcon,
                    size: 44
                )
                .frame(width: 50)

                VStack(alignment: .leading, spacing: 3) {
                    Text(product.pluralName)
                        .font(.system(.headline, design: .serif))
                        .fontWeight(.bold)
                        .foregroundStyle(darkBrown)

                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(darkBrown.opacity(0.78))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 4)

                ZStack {
                    Circle()
                        .stroke(gold, lineWidth: 2)

                    if isSelected {
                        Circle()
                            .fill(gold)
                            .padding(5)
                    }
                }
                .frame(width: 26, height: 26)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(isSelected ? 0.72 : 0.45))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        gold.opacity(isSelected ? 0.9 : 0.35),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}
