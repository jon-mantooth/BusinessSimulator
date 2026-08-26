//
//  InstructionsView.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/21/26.
//

import SwiftUI

struct InstructionsView: View {
    let product: Product

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {

            // Fixed header
            HStack {
                Spacer()

                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            // Scrollable card
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    Text(product.pluralName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    Divider()

                    Text(product.productLine.inputLabel)
                        .font(.headline)

                    VStack(spacing: 8) {
                        ForEach(product.productInventories, id: \.id) { requirement in
                            HStack(alignment: .firstTextBaseline) {
                                Text(requirement.inventory.name)

                                Spacer()

                                Text(requirement.recipeAmountLabel)
                                    .fontWeight(.medium)
                            }
                        }
                    }

                    Divider()

                    Text("Steps")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(
                            Array(product.instructions.enumerated()),
                            id: \.offset
                        ) { index, instruction in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1).")
                                    .fontWeight(.semibold)
                                    .frame(minWidth: 24, alignment: .leading)

                                Text(instruction)
                                    .fixedSize(
                                        horizontal: false,
                                        vertical: true
                                    )
                            }
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 500)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            Color(
                                red: 0.99,
                                green: 0.98,
                                blue: 0.93
                            )
                        )
                        .shadow(
                            color: .black.opacity(0.15),
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}
