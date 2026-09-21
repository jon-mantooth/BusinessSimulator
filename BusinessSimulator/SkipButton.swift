//
//  SkipButton.swift
//  BusinessSimulator
//

import SwiftUI

struct SkipButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("Skip")
                    .font(.subheadline.weight(.bold))

                Image(systemName: "forward.end.fill")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.black.opacity(0.68))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.65), lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Skip")
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.5)
        SkipButton(action: {})
    }
}
