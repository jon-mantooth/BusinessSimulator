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

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Your Product")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Select the product your company will specialize in.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ForEach(products) { product in
                productCard(for: product)
            }

            Spacer()

            Button("Continue") {
                if let selectedProduct {
                    onContinue(selectedProduct)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedProduct == nil)
        }
        .frame(maxWidth: 500)      // <-- Add this
        .padding()
        .frame(maxWidth: .infinity) // <-- Center it
    }

    private func productCard(for product: Product) -> some View {
        Button {
            selectedProduct = product
            onSelectionChanged(product)
        } label: {
            HStack(spacing: 16) {
                GameIconView(
                    icon: product.smallIcon,
                    size: 44
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(.headline)

                    Text(product.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                selectedProduct?.id == product.id
                    ? Color.accentColor.opacity(0.15)
                    : Color.secondary.opacity(0.08)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedProduct?.id == product.id
                            ? Color.accentColor
                            : Color.secondary.opacity(0.3),
                        lineWidth: selectedProduct?.id == product.id ? 2 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
