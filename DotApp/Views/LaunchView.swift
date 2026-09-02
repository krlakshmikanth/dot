import SwiftUI

struct LaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    let reduceMotionInDot: Bool
    let onFinished: () -> Void

    @State private var gathered = false
    @State private var revealed = false

    private var reduceMotion: Bool {
        systemReduceMotion || reduceMotionInDot
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if !reduceMotion {
                    ForEach(0..<52, id: \.self) { index in
                        Circle()
                            .fill(Color.primary)
                            .frame(width: particleSize(index), height: particleSize(index))
                            .position(
                                x: gathered ? proxy.size.width / 2 + targetX(index) : startX(index, width: proxy.size.width),
                                y: gathered ? proxy.size.height / 2 + targetY(index) : startY(index, height: proxy.size.height)
                            )
                            .opacity(revealed ? 0 : particleOpacity(index))
                            .animation(
                                .easeInOut(duration: 0.72).delay(Double(index % 8) * 0.018),
                                value: gathered
                            )
                            .animation(.easeOut(duration: 0.35), value: revealed)
                    }
                }

                VStack(spacing: 8) {
                    Text("dot")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .tracking(-5)
                    Text("by latte")
                        .font(.system(size: 15, weight: .medium))
                        .tracking(1.8)
                }
                .opacity(reduceMotion ? (revealed ? 1 : 0) : (gathered ? 1 : 0))
                .scaleEffect(reduceMotion ? 1 : (revealed ? 1 : 0.94))
                .animation(.easeOut(duration: reduceMotion ? 0.25 : 0.5), value: revealed)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("dot by latte")
            }
        }
        .task { await playAnimation() }
    }

    @MainActor
    private func playAnimation() async {
        if reduceMotion {
            revealed = true
            try? await Task.sleep(for: .milliseconds(600))
        } else {
            try? await Task.sleep(for: .milliseconds(120))
            gathered = true
            try? await Task.sleep(for: .milliseconds(760))
            revealed = true
            try? await Task.sleep(for: .milliseconds(600))
        }
        onFinished()
    }

    private func particleSize(_ index: Int) -> CGFloat {
        CGFloat(3 + (index * 7) % 6)
    }

    private func particleOpacity(_ index: Int) -> Double {
        0.35 + Double((index * 13) % 60) / 100
    }

    private func startX(_ index: Int, width: CGFloat) -> CGFloat {
        CGFloat((index * 83 + 29) % max(1, Int(width)))
    }

    private func startY(_ index: Int, height: CGFloat) -> CGFloat {
        CGFloat((index * 137 + 47) % max(1, Int(height)))
    }

    private func targetX(_ index: Int) -> CGFloat {
        CGFloat((index * 31) % 130) - 65
    }

    private func targetY(_ index: Int) -> CGFloat {
        CGFloat((index * 19) % 94) - 50
    }
}
