//
//  ClockView.swift
//  BusinessSimulator
//

import SwiftUI

struct ClockView: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(
                geometry.size.width,
                geometry.size.height
            )
            let tickLength = size * 0.08
            let tickWidth = size * 0.018

            ZStack {
                Circle()
                    .fill(Color(red: 0.94, green: 0.88, blue: 0.72))

                Circle()
                    .stroke(
                        Color(red: 0.25, green: 0.14, blue: 0.08),
                        lineWidth: size * 0.055
                    )

                ForEach(0..<12, id: \.self) { hour in
                    Capsule()
                        .fill(Color(red: 0.25, green: 0.14, blue: 0.08))
                        .frame(
                            width: tickWidth,
                            height: tickLength
                        )
                        .offset(y: -(size * 0.39))
                        .rotationEffect(.degrees(Double(hour) * 30))
                }

                Circle()
                    .fill(Color(red: 0.25, green: 0.14, blue: 0.08))
                    .frame(
                        width: size * 0.07,
                        height: size * 0.07
                    )
            }
            .frame(width: size, height: size)
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            .shadow(
                color: .black.opacity(0.28),
                radius: size * 0.035,
                y: size * 0.02
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Business day clock")
    }
}

#Preview {
    ClockView()
        .frame(width: 180, height: 180)
        .padding()
        .background(Color(red: 0.45, green: 0.68, blue: 0.85))
}
