//
//  CustomerVisitView.swift
//  BusinessSimulator
//

import SwiftUI

struct CustomerVisitView: View {
    let assetName: String
    let state: CustomerVisitState

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(y: verticalOffset)
            .accessibilityHidden(true)
    }

    private var opacity: Double {
        switch state.phase {
        case .waiting, .completed:
            return 0.0
        case .arriving:
            return state.phaseProgress
        case .receivingService:
            return 1.0
        case .departing:
            return 1.0 - state.phaseProgress
        }
    }

    private var scale: CGFloat {
        switch state.phase {
        case .waiting, .completed:
            return 0.88
        case .arriving:
            return interpolate(from: 0.88, to: 1.0)
        case .receivingService:
            return 1.0
        case .departing:
            return interpolate(from: 1.0, to: 0.88)
        }
    }

    private var verticalOffset: CGFloat {
        switch state.phase {
        case .waiting, .completed:
            return -18
        case .arriving:
            return interpolate(from: -18, to: 0)
        case .receivingService:
            return 0
        case .departing:
            return interpolate(from: 0, to: -18)
        }
    }

    private func interpolate(
        from start: CGFloat,
        to end: CGFloat
    ) -> CGFloat {
        let progress = min(max(state.phaseProgress, 0.0), 1.0)
        return start + (end - start) * CGFloat(progress)
    }
}
