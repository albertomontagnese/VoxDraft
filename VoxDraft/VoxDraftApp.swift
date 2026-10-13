import SwiftUI

@main
struct VoxDraftApp: App {
    @StateObject private var controller = DictationController()

    var body: some Scene {
        MenuBarExtra {
            Text(statusLabel)
            Button(controller.isRecording ? "Finish dictation" : "Start dictation") {
                controller.toggle()
            }
            .disabled(controller.phase == .preparing || controller.phase == .processing)
            if !controller.lastText.isEmpty {
                Button("Copy last dictation") { controller.copyLast() }
            }
            Divider()
            SettingsLink { Text("Settings and history…") }
            Button("Allow text insertion…") { controller.requestAccessibility() }
            Divider()
            Button("Quit VoxDraft") { NSApplication.shared.terminate(nil) }
        } label: {
            Image(systemName: controller.isRecording ? "waveform.circle.fill" : "mic.circle")
                .symbolRenderingMode(.palette)
                .foregroundStyle(controller.isRecording ? .red : .primary)
        }

        Settings {
            SettingsView(controller: controller)
        }
    }

    private var statusLabel: String {
        switch controller.phase {
        case .ready: return controller.shortcutAvailable ? "Ready · ⌃⌥D to dictate" : "Shortcut unavailable · use Start dictation"
        case .preparing: return "Preparing…"
        case .recording: return "Recording · ⌃⌥D to finish"
        case .processing: return "Processing…"
        case .finished, .failed: return controller.message
        }
    }
}
