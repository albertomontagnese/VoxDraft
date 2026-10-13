import AppKit
import SwiftUI

@MainActor
final class StatusHUD {
    private let panel: NSPanel

    init(controller: DictationController) {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 390, height: 122),
                        styleMask: [.nonactivatingPanel, .borderless],
                        backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = true
        panel.contentView = NSHostingView(rootView: HUDView(controller: controller))
    }

    func show() {
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.midX - 195, y: frame.minY + 38))
        }
        panel.orderFrontRegardless()
    }

    func hide() { panel.orderOut(nil) }
}

private struct HUDView: View {
    @ObservedObject var controller: DictationController

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: controller.phase == .recording ? "waveform" : "text.bubble.fill")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(controller.phase == .recording ? .red : .cyan)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 7) {
                Text(controller.phase == .recording ? "VoxDraft is listening" : "VoxDraft")
                    .font(.headline)
                Text(controller.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !controller.transcript.isEmpty {
                    Text(controller.transcript)
                        .font(.subheadline)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(width: 390, height: 122, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.13)))
    }
}
