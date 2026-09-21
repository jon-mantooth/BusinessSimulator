//
//  ClockView.swift
//  BusinessSimulator
//

import SwiftUI

struct ClockView: View {
    let progress: Double
    let businessHours: BusinessHours

    var body: some View {
        GeometryReader { geometry in
            let size = min(
                geometry.size.width,
                geometry.size.height
            )
            let displayedMinutes = businessHours.playbackMinutes(
                at: progress
            )
            let displayedHour = displayedMinutes / 60.0
            let hourHandAngle = displayedHour * 30.0
            let minuteHandAngle = displayedHour * 360.0

            ZStack {
                Image("clock_face")
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())

                Capsule()
                    .fill(Color(red: 0.25, green: 0.14, blue: 0.08))
                    .frame(
                        width: size * 0.045,
                        height: size * 0.24
                    )
                    .offset(y: -(size * 0.12))
                    .rotationEffect(.degrees(hourHandAngle))

                Capsule()
                    .fill(Color(red: 0.55, green: 0.16, blue: 0.10))
                    .frame(
                        width: size * 0.025,
                        height: size * 0.34
                    )
                    .offset(y: -(size * 0.17))
                    .rotationEffect(.degrees(minuteHandAngle))

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
