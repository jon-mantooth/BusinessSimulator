//
//  DayTransitionOverlay.swift
//  BusinessSimulator
//

import SwiftUI

struct DayTransitionOverlay: View {
    let message: DayTransitionMessage?

    var body: some View {
        GeometryReader { geometry in
            if let message {
                Text(text(for: message))
                    .font(font(for: message))
                    .fontWeight(.heavy)
                    .tracking(message == .open || message == .closed ? 4 : 0)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        Color(red: 0.78, green: 0.08, blue: 0.06)
                    )
                    .shadow(color: .white.opacity(0.9), radius: 2)
                    .shadow(color: .black.opacity(0.55), radius: 5, y: 3)
                    .frame(maxWidth: geometry.size.width * 0.9)
                    .position(
                        x: geometry.size.width * 0.5,
                        y: geometry.size.height * 0.25
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .accessibilityHidden(message == nil)
    }

    private func text(for message: DayTransitionMessage) -> String {
        switch message {
        case let .date(date):
            return date.formatted(
                .dateTime.weekday(.wide).month(.wide).day()
            )
        case .open:
            return "OPEN"
        case .closed:
            return "CLOSED"
        }
    }

    private func font(for message: DayTransitionMessage) -> Font {
        switch message {
        case .date:
            return .system(size: 30, design: .rounded)
        case .open, .closed:
            return .system(size: 42, design: .rounded)
        }
    }
}
