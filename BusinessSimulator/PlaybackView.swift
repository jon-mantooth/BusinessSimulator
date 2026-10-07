//
//  PlaybackView.swift
//  BusinessSimulator
//

import SwiftUI

struct PlaybackView: View {
    let progress: Double
    let elapsedTime: TimeInterval
    let businessHours: BusinessHours
    let weatherCondition: WeatherCondition
    let scene: ResolvedLocationScene
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            LocationSceneView(scene: scene) { content, canvasSize in
                dynamicContent(
                    content,
                    canvasSize: canvasSize
                )
            }

            WeatherPlaybackLayer(condition: weatherCondition)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
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

private struct WeatherPlaybackLayer: View {
    let condition: WeatherCondition

    var body: some View {
        switch condition {
        case .rain:
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    drawRain(
                        context: &context,
                        size: size,
                        time: timeline.date.timeIntervalSinceReferenceDate
                    )
                }
            }

        case .snow:
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    drawSnow(
                        context: &context,
                        size: size,
                        time: timeline.date.timeIntervalSinceReferenceDate
                    )
                }
            }

        case .sunny, .cloudy:
            EmptyView()
        }
    }

    private func drawRain(
        context: inout GraphicsContext,
        size: CGSize,
        time: TimeInterval
    ) {
        let dropCount = 95

        for index in 0..<dropCount {
            let horizontalSeed = unitValue(index * 47 + 13)
            let verticalSeed = unitValue(index * 71 + 29)
            let speed = 0.72 + unitValue(index * 31) * 0.45
            let progress = wrapped(verticalSeed + time * speed)
            let x = horizontalSeed * size.width
            let y = progress * (size.height + 34) - 17
            let length = 13 + unitValue(index * 19) * 11

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(
                to: CGPoint(
                    x: x - length * 0.28,
                    y: y + length
                )
            )

            context.stroke(
                path,
                with: .color(.white.opacity(0.48)),
                lineWidth: 1.2
            )
        }
    }

    private func drawSnow(
        context: inout GraphicsContext,
        size: CGSize,
        time: TimeInterval
    ) {
        let flakeCount = 58

        for index in 0..<flakeCount {
            let horizontalSeed = unitValue(index * 53 + 11)
            let verticalSeed = unitValue(index * 79 + 17)
            let speed = 0.055 + unitValue(index * 23) * 0.055
            let progress = wrapped(verticalSeed + time * speed)
            let drift = sin(time * 1.15 + Double(index)) * 10
            let diameter = 3 + unitValue(index * 37) * 4
            let x = horizontalSeed * size.width + drift
            let y = progress * (size.height + diameter) - diameter

            context.fill(
                Path(
                    ellipseIn: CGRect(
                        x: x,
                        y: y,
                        width: diameter,
                        height: diameter
                    )
                ),
                with: .color(.white.opacity(0.82))
            )
        }
    }

    private func unitValue(_ seed: Int) -> Double {
        let value = (seed &* 1_103_515_245 &+ 12_345) & 0x7fff_ffff
        return Double(value) / Double(0x7fff_ffff)
    }

    private func wrapped(_ value: Double) -> Double {
        value - floor(value)
    }
}
