//
//  SummaryView.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/26/26.
//

import SwiftUI

struct SummaryView: View {

    let summary: DaySummary
    let onNextDay: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Header

                    VStack(spacing: 4) {
                        Text("Day \(summary.day)")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Daily Summary")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // MARK: - Sales

                    summarySection(title: "Sales") {
                        summaryRow(
                            label: "Units Sold",
                            value: summary.sales.formatted()
                        )

                        Divider()

                        summaryRow(
                            label: "Revenue",
                            value: currency(summary.revenue)
                        )
                    }

                    // MARK: - Costs

                    summarySection(title: "Costs") {
                        if summary.costs.isEmpty {
                            Text("No costs recorded")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(
                                Array(summary.costs.enumerated()),
                                id: \.offset
                            ) { index, cost in

                                summaryRow(
                                    label: cost.name,
                                    value: currency(cost.amount)
                                )

                                if index < summary.costs.count - 1 {
                                    Divider()
                                }
                            }

                            Divider()

                            summaryRow(
                                label: "Total Costs",
                                value: currency(summary.totalCosts),
                                isEmphasized: true
                            )
                        }
                    }

                    // MARK: - Profit

                    summarySection(title: "Results") {
                        summaryRow(
                            label: "Profit",
                            value: currency(summary.profit),
                            isEmphasized: true
                        )
                    }

                    // MARK: - Balance

                    summarySection(title: "Balance") {
                        summaryRow(
                            label: "Starting Balance",
                            value: currency(summary.startingBalance)
                        )

                        Divider()

                        summaryRow(
                            label: "Ending Balance",
                            value: currency(summary.balance),
                            isEmphasized: true
                        )
                    }

                    // MARK: - Notes

                    if !summary.sections.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes")
                                .font(.title3)
                                .fontWeight(.semibold)

                            ForEach(
                                Array(summary.sections.enumerated()),
                                id: \.offset
                            ) { _, noteSection in

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(noteSection.name)
                                        .font(.headline)

                                    ForEach(
                                        Array(noteSection.notes.enumerated()),
                                        id: \.offset
                                    ) { _, note in

                                        Text("• \(note)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.regularMaterial)
                                )
                            }
                        }
                    }
                }
                .padding()
            }

            // MARK: - Next Day Button

            Button(action: onNextDay) {
                Text("Continue to Day \(summary.day + 1)")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

    // MARK: - Reusable Views

    private func summarySection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
    }

    private func summaryRow(
        label: String,
        value: String,
        isEmphasized: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .fontWeight(isEmphasized ? .semibold : .regular)

            Spacer()

            Text(value)
                .fontWeight(isEmphasized ? .bold : .medium)
        }
    }

    private func currency(_ amount: Double) -> String {
        amount.formatted(
            .currency(code: "USD")
        )
    }
}
