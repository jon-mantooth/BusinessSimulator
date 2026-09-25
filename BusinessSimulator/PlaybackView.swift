//
//  PlaybackView.swift
//  BusinessSimulator
//

import SwiftUI

struct PlaybackView: View {
    let progress: Double
    let elapsedTime: TimeInterval
    let businessHours: BusinessHours
    let productID: ProductID
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

                if let activeCustomer {
                    CustomerVisitView(
                        assetName: activeCustomer.assetName,
                        state: activeCustomer.state
                    )
                        .frame(
                            width: geometry.size.width * 0.72,
                            height: geometry.size.height * 0.62,
                            alignment: .bottom
                        )
                        .position(
                            x: customerXPosition(
                                activeCustomer.position,
                                sceneWidth: geometry.size.width
                            ),
                            y: geometry.size.height * 0.58
                        )
                }

                Image(standImageName)
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

    private var standImageName: String {
        switch productID {
        case .pies:
            return "pies"
        case .smoothies:
            return "smoothies"
        case .hotDogs:
            return "hotdogs"
        }
    }

    private func customerXPosition(
        _ position: CustomerVisitPosition,
        sceneWidth: CGFloat
    ) -> CGFloat {
        switch position {
        case .left:
            return sceneWidth * 0.34
        case .center:
            return sceneWidth * 0.50
        case .right:
            return sceneWidth * 0.66
        }
    }
}
