//
//  ContentView.swift
//  HelloSwift
//
//  Created by jon mantooth on 7/12/26.
//

import SwiftUI

struct HomeView: View {
    let hasSavedGame: Bool
    let onBeginJourney: () -> Void
    let onContinue: () -> Void

    private let darkBrown = Color(red: 0.23, green: 0.12, blue: 0.06)
    private let gold = Color(red: 0.82, green: 0.54, blue: 0.20)

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 10) {
                logo

                decorativeDivider

                if hasSavedGame {
                    Button {
                        onContinue()
                    } label: {
                        Text("Continue")
                            .font(.system(.title3, design: .serif))
                            .fontWeight(.bold)
                            .foregroundStyle(darkBrown)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.82, blue: 0.42),
                                Color(red: 0.95, green: 0.61, blue: 0.14)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(gold, lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
                    .frame(maxWidth: 330)
                    .padding(.top, 6)
                }

                Button {
                    onBeginJourney()
                } label: {
                    Text("Begin New Journey")
                        .font(.system(.title3, design: .serif))
                        .fontWeight(.bold)
                    .foregroundStyle(darkBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .background {
                    if hasSavedGame {
                        Color.white.opacity(0.72)
                    } else {
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.82, blue: 0.42),
                                Color(red: 0.95, green: 0.61, blue: 0.14)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(gold, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
                .frame(maxWidth: 330)
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
            .position(
                x: geometry.size.width * 0.5,
                y: geometry.size.height * 0.22
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    private var logo: some View {
        VStack(spacing: -7) {
            Image(systemName: "storefront")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(gold)
                .padding(.bottom, 2)

            Text("BUSINESS")
                .font(.system(size: 52, weight: .black, design: .serif))
                .tracking(-3)
                .foregroundStyle(Color(red: 0.16, green: 0.07, blue: 0.025))
                .scaleEffect(x: 0.88, y: 1.08)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .shadow(color: gold, radius: 0, x: 1, y: 0)
                .shadow(color: gold, radius: 0, x: -1, y: 0)
                .shadow(color: gold, radius: 0, x: 0, y: 1)
                .shadow(color: gold, radius: 0, x: 0, y: -1)
                .shadow(color: .white.opacity(0.3), radius: 0, x: 0, y: -1)
                .shadow(color: .black.opacity(0.35), radius: 3, y: 3)

            Text("SIMULATOR")
                .font(.system(size: 32, weight: .black, design: .serif))
                .tracking(0.5)
                .foregroundStyle(darkBrown)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .shadow(color: .white.opacity(0.7), radius: 1)
        }
    }

    private var decorativeDivider: some View {
        HStack(spacing: 8) {
            Rectangle()
                .frame(height: 1)

            Circle()
                .frame(width: 5, height: 5)

            Diamond()
                .frame(width: 9, height: 9)

            Circle()
                .frame(width: 5, height: 5)

            Rectangle()
                .frame(height: 1)
        }
        .foregroundStyle(gold)
        .frame(maxWidth: 260)
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
