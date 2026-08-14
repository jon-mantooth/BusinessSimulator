//
//  HeaderView.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/23/26.
//

import SwiftUI

struct HeaderView: View {
    let gameState: GameState

    private let darkBrown = Color(red: 0.23, green: 0.12, blue: 0.06)
    private let orange = Color(red: 0.88, green: 0.43, blue: 0.08)
    private let green = Color(red: 0.04, green: 0.52, blue: 0.16)
    private let blue = Color(red: 0.08, green: 0.48, blue: 0.82)

    var body: some View {
        HStack(spacing: 7) {
            headerButton(
                title: "Sep 1",
                systemImage: "calendar",
                color: orange
            )

            headerButton(
                title: "72°",
                systemImage: "sun.max.fill",
                color: .yellow
            )

            aiButton

            balanceDisplay
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 5, y: 2)
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var aiButton: some View {
        Button {
            // The AI consultant view will be connected with that feature.
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(blue)

                Text("AI")
                    .font(.system(size: 14, weight: .bold))

                Circle()
                    .fill(green)
                    .frame(width: 7, height: 7)
            }
            .foregroundStyle(darkBrown)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("AI Consultant, online")
    }

    private var balanceDisplay: some View {
        Text(
            gameState.finance.displayedBalance,
            format: .currency(code: "USD")
        )
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(darkBrown)
        .lineLimit(1)
        .minimumScaleFactor(0.55)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Balance")
        .accessibilityValue(
            gameState.finance.displayedBalance.formatted(
                .currency(code: "USD")
            )
        )
    }

    private func headerButton(
        title: String,
        systemImage: String,
        color: Color
    ) -> some View {
        Button {
            // Calendar and weather views will be connected with their features.
        } label: {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(darkBrown)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(title)
    }
}
