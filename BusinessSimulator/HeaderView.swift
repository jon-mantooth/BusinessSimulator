//
//  HeaderView.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/23/26.
//

import SwiftUI

struct HeaderView: View {
    let gameState: GameState
    let onCalendarTapped: () -> Void
    let onWeatherTapped: () -> Void

    private let darkBrown = Color(red: 0.23, green: 0.12, blue: 0.06)
    private let orange = Color(red: 0.88, green: 0.43, blue: 0.08)
    private let green = Color(red: 0.04, green: 0.52, blue: 0.16)
    private let blue = Color(red: 0.08, green: 0.48, blue: 0.82)
    private let cloudColor = Color(red: 0.30, green: 0.38, blue: 0.46)

    var body: some View {
        HStack(spacing: 7) {
            //date
            headerButton(
                title: gameState.calendar.currentDate.formatted(
                    .dateTime.month(.abbreviated).day()
                ),
                systemImage: "calendar",
                color: orange,
                action: onCalendarTapped
            )

            weatherButton

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

    private var weatherButton: some View {
        let weather = gameState.weather.weather(
            for: gameState.calendar.currentDate
        )
        let displayedWeather = gameState.weather.displayedWeather(
            for: gameState.calendar.currentDate
        )

        let appearance = weatherAppearance(
            for: weather.condition
        )

        return headerButton(
            title: "\(displayedWeather)°",
            systemImage: appearance.systemImage,
            color: appearance.color,
            showsIconBackground: true,
            action: onWeatherTapped
        )
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

    private func weatherAppearance(
        for condition: WeatherCondition
    ) -> (systemImage: String, color: Color) {
        switch condition {
        case .sunny:
            return ("sun.max.fill", .yellow)
        case .cloudy:
            return ("cloud.fill", cloudColor)
        case .rain:
            return ("cloud.rain.fill", .blue)
        case .snow:
            return ("cloud.snow.fill", .cyan)
        }
    }

    private func headerButton(
        title: String,
        systemImage: String,
        color: Color,
        showsIconBackground: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                ZStack {
                    if showsIconBackground {
                        Circle()
                            .fill(Color.white.opacity(0.72))
                            .frame(width: 30, height: 30)
                    }

                    Image(systemName: systemImage)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(color)
                        .shadow(color: .white.opacity(0.7), radius: 1)
                        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                }

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
