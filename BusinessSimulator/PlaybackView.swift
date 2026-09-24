//
//  PlaybackView.swift
//  BusinessSimulator
//

import SwiftUI

struct PlaybackView: View {
    let progress: Double
    let businessHours: BusinessHours
    let onSkip: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let clockSize = min(geometry.size.width * 0.34, 180)
            let activeCustomer = CustomerVisitSchedule.prototype.activeVisit(
                at: elapsedTime
            )

            ZStack {
                Image("animation_background")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()

                // Future customers belong between the background and stand
                // so the counter naturally masks their lower bodies.

                Image("stand")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()

                ClockView(
                    progress: progress,
                    businessHours: businessHours
                )
                    .frame(width: clockSize, height: clockSize)
                    .position(
                        x: geometry.size.width * 0.5,
                        y: geometry.size.height * 0.27
                    )

                VStack {
                    HStack {
                        Spacer()
                        SkipButton(action: onSkip)
                    }
                    Spacer()
                }
                .padding(.top, 52)
                .padding(.trailing, 22)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
        }
        .ignoresSafeArea()
    }
}
