//
//  PlaybackView.swift
//  BusinessSimulator
//

import SwiftUI

struct PlaybackView: View {
    let progress: Double
    let elapsedTime: TimeInterval
    let businessHours: BusinessHours
    let scene: ResolvedLocationScene
    let onSkip: () -> Void

    var body: some View {
        LocationSceneView(scene: scene) { content, canvasSize in
            dynamicContent(
                content,
                canvasSize: canvasSize
            )
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func dynamicContent(
        _ content: ResolvedLocationSceneContent,
        canvasSize: CGSize
    ) -> some View {
        switch content {
        case .customerAnimation(let schedule):
            if let activeCustomer = schedule.activeVisit(
                at: elapsedTime
            ) {
                CustomerVisitView(
                    assetName: activeCustomer.assetName,
                    state: activeCustomer.state
                )
                .frame(
                    width: canvasSize.width * 0.72,
                    height: canvasSize.height * 0.62,
                    alignment: .bottom
                )
                .position(
                    x: customerXPosition(
                        activeCustomer.position,
                        sceneWidth: canvasSize.width
                    ),
                    y: canvasSize.height * 0.58
                )
            }

        case .playbackInterface:
            playbackInterface(canvasSize: canvasSize)

        case .empty, .image:
            EmptyView()
        }
    }

    private func playbackInterface(
        canvasSize: CGSize
    ) -> some View {
        let clockSize = min(canvasSize.width * 0.34, 180)

        return ZStack {
            ClockView(
                progress: progress,
                businessHours: businessHours
            )
            .frame(width: clockSize, height: clockSize)
            .position(
                x: canvasSize.width * 0.5,
                y: canvasSize.height * 0.27
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
            width: canvasSize.width,
            height: canvasSize.height
        )
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
