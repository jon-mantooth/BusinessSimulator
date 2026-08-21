//
//  WeatherForecastView.swift
//  BusinessSimulator
//

import SwiftUI

struct WeatherForecastView: View {
    @Environment(\.dismiss) private var dismiss

    let forecast: [DailyWeather]

    private let darkBrown = Color(red: 0.23, green: 0.12, blue: 0.06)
    private let orange = Color(red: 0.88, green: 0.32, blue: 0.08)
    private let blue = Color(red: 0.16, green: 0.45, blue: 0.72)
    private let gold = Color(red: 0.82, green: 0.54, blue: 0.20)
    private let cloudColor = Color(red: 0.30, green: 0.38, blue: 0.46)

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.yellow)

                Text("5-Day Forecast")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(orange)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(darkBrown.opacity(0.72))
                }
                .accessibilityLabel("Close forecast")
            }

            HStack(spacing: 7) {
                ForEach(forecast) { weather in
                    forecastCard(for: weather)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.98, blue: 0.92),
                    Color(red: 1.0, green: 0.94, blue: 0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(gold, lineWidth: 2)
        }
        .padding(16)
    }

    private func forecastCard(
        for weather: DailyWeather
    ) -> some View {
        let appearance = weatherAppearance(for: weather.condition)

        return VStack(spacing: 7) {
            Text(weather.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 14, weight: .bold))

            Text(weather.date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.system(size: 12))

            Image(systemName: appearance.systemImage)
                .font(.system(size: 28))
                .foregroundStyle(appearance.color)
                .symbolRenderingMode(.multicolor)
                .shadow(color: .white.opacity(0.7), radius: 1)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 1)

            Text(appearance.name)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Divider()

            Text("\(weather.highTemperature)°")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(orange)

            Text("\(weather.lowTemperature)°")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(blue)
        }
        .foregroundStyle(darkBrown)
        .frame(maxWidth: .infinity, minHeight: 190)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(.white.opacity(0.43))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(darkBrown.opacity(0.13), lineWidth: 1)
        }
    }

    private func weatherAppearance(
        for condition: WeatherCondition
    ) -> (name: String, systemImage: String, color: Color) {
        switch condition {
        case .sunny:
            return ("Sunny", "sun.max.fill", .yellow)
        case .cloudy:
            return ("Cloudy", "cloud.fill", cloudColor)
        case .rain:
            return ("Rain", "cloud.rain.fill", .blue)
        case .snow:
            return ("Snow", "cloud.snow.fill", .cyan)
        }
    }
}
