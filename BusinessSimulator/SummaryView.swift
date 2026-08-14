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

    private let darkBrown = Color(red: 0.23, green: 0.12, blue: 0.06)
    private let gold = Color(red: 0.84, green: 0.57, blue: 0.22)
    private let green = Color(red: 0.04, green: 0.48, blue: 0.15)
    private let red = Color(red: 0.78, green: 0.05, blue: 0.05)
    private let blue = Color(red: 0.08, green: 0.48, blue: 0.82)

    private var totalCosts: Double {
        summary.cashFlowCosts.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                summaryHeader
                salesSection
                costsSection
                resultsSection
                balanceSection

                if !summary.sections.isEmpty {
                    notesSection
                }

                continueButton
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.98, blue: 0.92),
                        Color(red: 1.0, green: 0.94, blue: 0.80)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(gold.opacity(0.9), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.22), radius: 12, y: 6)
            .frame(maxWidth: 700)
            .padding(.horizontal, 18)
            .padding(.vertical, 6)
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 14) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 42))
                .foregroundStyle(blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Day \(summary.day) Summary")
                    .font(.system(.title, design: .serif))
                    .fontWeight(.bold)
                    .foregroundStyle(darkBrown)

                Text("Here’s how your day went!")
                    .font(.subheadline)
                    .foregroundStyle(darkBrown.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 8)
    }

    private var salesSection: some View {
        summarySection(
            title: "Sales",
            systemImage: "chart.line.uptrend.xyaxis",
            color: green
        ) {
            HStack(spacing: 0) {
                metric(
                    label: "Units Sold",
                    value: summary.sales.formatted(),
                    color: green
                )

                Divider()
                    .frame(height: 44)

                metric(
                    label: "Revenue",
                    value: currency(summary.revenue),
                    color: green
                )
            }
            .padding(.vertical, 2)
        }
    }

    private var costsSection: some View {
        summarySection(
            title: "Costs",
            systemImage: "cart.fill",
            color: red
        ) {
            if summary.cashFlowCosts.isEmpty {
                Text("No costs recorded")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(
                    Array(summary.cashFlowCosts.enumerated()),
                    id: \.offset
                ) { index, cost in
                    summaryRow(
                        label: cost.name,
                        value: currency(cost.amount)
                    )

                    if index < summary.cashFlowCosts.count - 1 {
                        Divider()
                    }
                }

                Divider()

                summaryRow(
                    label: "Total Costs",
                    value: currency(totalCosts),
                    valueColor: red,
                    isEmphasized: true
                )
            }
        }
    }

    private var resultsSection: some View {
        let resultColor = summary.netCashFlow >= 0 ? green : red

        return summarySection(
            title: "Results",
            systemImage: "banknote.fill",
            color: resultColor
        ) {
            summaryRow(
                label: "Net Cash Flow",
                value: signedCurrency(summary.netCashFlow),
                valueColor: resultColor,
                isEmphasized: true
            )
        }
    }

    private var balanceSection: some View {
        summarySection(
            title: "Balance",
            systemImage: "dollarsign",
            color: gold
        ) {
            summaryRow(
                label: "Starting Balance",
                value: currency(summary.startingBalance)
            )

            Divider()

            summaryRow(
                label: "Ending Balance",
                value: currency(summary.balance),
                valueColor: summary.balance >= 0 ? green : red,
                isEmphasized: true
            )
        }
    }

    private var notesSection: some View {
        summarySection(
            title: "Notes",
            systemImage: "note.text",
            color: blue,
            contentColor: blue.opacity(0.08)
        ) {
            ForEach(
                Array(summary.sections.enumerated()),
                id: \.offset
            ) { sectionIndex, noteSection in
                VStack(alignment: .leading, spacing: 5) {
                    Text(noteSection.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(darkBrown)

                    ForEach(
                        Array(noteSection.notes.enumerated()),
                        id: \.offset
                    ) { _, note in
                        Text("•  \(note)")
                            .font(.subheadline)
                            .foregroundStyle(darkBrown.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if sectionIndex < summary.sections.count - 1 {
                    Divider()
                }
            }
        }
    }

    private var continueButton: some View {
        Button(action: onNextDay) {
            HStack(spacing: 10) {
                Text("Continue to Day \(summary.day + 1)")
                Image(systemName: "chevron.right")
            }
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                colors: [green, Color(red: 0.01, green: 0.34, blue: 0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }

    private func summarySection<Content: View>(
        title: String,
        systemImage: String,
        color: Color,
        contentColor: Color = .white.opacity(0.5),
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
            } icon: {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .clipShape(Circle())
            }
            .foregroundStyle(color)

            VStack(spacing: 8) {
                content()
            }
            .padding(12)
            .background(contentColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.18), lineWidth: 1)
            }
        }
        .padding(10)
        .background(.white.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func metric(
        label: String,
        value: String,
        color: Color
    ) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(darkBrown.opacity(0.75))

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func summaryRow(
        label: String,
        value: String,
        valueColor: Color = .primary,
        isEmphasized: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .fontWeight(isEmphasized ? .bold : .regular)

            Spacer()

            Text(value)
                .fontWeight(isEmphasized ? .bold : .semibold)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .font(isEmphasized ? .headline : .subheadline)
    }

    private func currency(_ amount: Double) -> String {
        amount.formatted(.currency(code: "USD"))
    }

    private func signedCurrency(_ amount: Double) -> String {
        let formattedAmount = currency(abs(amount))
        return amount >= 0 ? "+\(formattedAmount)" : "-\(formattedAmount)"
    }
}
