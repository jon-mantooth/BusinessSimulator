//
//  FooterView.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/22/26.
//

import SwiftUI

enum GameArea {
    case gameMode
    case production
    case distribution
    case marketing
    case finance
}

struct FooterView: View {
    let selectedArea: GameArea
    let onAreaTapped: (GameArea) -> Void

    private let darkBrown = Color(red: 0.23, green: 0.12, blue: 0.06)
    private let gold = Color(red: 0.82, green: 0.54, blue: 0.20)
    private let gameModeGreen = Color(red: 0.04, green: 0.48, blue: 0.15)

    var body: some View {
        HStack(spacing: 3) {
            footerButton(
                title: "Production",
                systemImage: "hammer.fill",
                isSelected: selectedArea == .production,
                action: {
                    onAreaTapped(.production)
                }
            )

            footerButton(
                title: "Distribution",
                systemImage: "truck.box.fill",
                isSelected: selectedArea == .distribution,
                action: {
                    onAreaTapped(.distribution)
                }
            )

            footerButton(
                title: "Game Mode",
                systemImage: "gamecontroller.fill",
                isSelected: selectedArea == .gameMode,
                action: {
                    onAreaTapped(.gameMode)
                }
            )

            footerButton(
                title: "Marketing",
                systemImage: "megaphone.fill",
                isSelected: selectedArea == .marketing,
                action: {
                    onAreaTapped(.marketing)
                }
            )

            footerButton(
                title: "Finance",
                systemImage: "chart.line.uptrend.xyaxis",
                isSelected: selectedArea == .finance,
                action: {
                    onAreaTapped(.finance)
                }
            )
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.98, blue: 0.92),
                    Color(red: 1.0, green: 0.91, blue: 0.70)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(gold.opacity(0.85), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        .padding(.horizontal, 8)
        .padding(.bottom, 3)
    }

    private func footerButton(
        title: String,
        systemImage: String,
        isSelected: Bool = false,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))

                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .foregroundStyle(isSelected ? .white : darkBrown.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? gameModeGreen
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
