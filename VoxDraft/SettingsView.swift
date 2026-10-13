import AppKit
import Speech
import SwiftUI

struct SettingsView: View {
    @ObservedObject var controller: DictationController
    @AppStorage("locale") private var locale = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    @AppStorage("localOnly") private var localOnly = false
    @AppStorage("basicCleanup") private var basicCleanup = true
    @AppStorage("useHermes") private var useHermes = false
    @AppStorage("hermesEndpoint") private var endpoint = "http://127.0.0.1:11434/api/generate"
    @AppStorage("hermesModel") private var model = "hermes3"

    private var locales: [Locale] {
        SFSpeechRecognizer.supportedLocales().sorted {
            ($0.localizedString(forIdentifier: $0.identifier) ?? $0.identifier) <
            ($1.localizedString(forIdentifier: $1.identifier) ?? $1.identifier)
        }
    }

    var body: some View {
        TabView {
            Form {
                Picker("Language", selection: $locale) {
                    ForEach(locales, id: \.identifier) { language in
                        Text(language.localizedString(forIdentifier: language.identifier) ?? language.identifier)
                            .tag(language.identifier)
                    }
                }
                Toggle("Recognize on this Mac only", isOn: $localOnly)
                Text("When off, Apple may use its speech service for languages without local recognition.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Remove filler sounds and tidy punctuation", isOn: $basicCleanup)
                Divider()
                Text("Global shortcut: Control + Option + D. Press once to start, again to insert.")
                Button("Open Accessibility settings") {
                    controller.requestAccessibility()
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            .padding(22)
            .tabItem { Label("Dictation", systemImage: "mic") }

            Form {
                Toggle("Polish text with local Hermes via Ollama", isOn: $useHermes)
                TextField("Ollama endpoint", text: $endpoint)
                    .disabled(!useHermes)
                TextField("Model", text: $model)
                    .disabled(!useHermes)
                Text("Ollama is optional. Install it separately and run `ollama pull hermes3`. VoxDraft sends text only to the local address above. If Hermes is unavailable, dictation still inserts the speech transcript.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .padding(22)
            .tabItem { Label("Hermes", systemImage: "sparkles") }

            HistoryView(controller: controller)
                .tabItem { Label("History", systemImage: "clock") }
        }
        .frame(width: 600, height: 420)
    }
}

private struct HistoryView: View {
    @ObservedObject var controller: DictationController
    @ObservedObject private var history: HistoryStore

    init(controller: DictationController) {
        self.controller = controller
        self.history = controller.history
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Recent dictations").font(.headline)
                Spacer()
                if !history.records.isEmpty {
                    Button("Clear history") { history.clear() }
                }
            }
            if history.records.isEmpty {
                ContentUnavailableView("No dictations yet", systemImage: "waveform", description: Text("Completed dictations are saved on this Mac."))
            } else {
                List {
                    ForEach(history.records) { record in
                        VStack(alignment: .leading, spacing: 7) {
                            Text(record.text).lineLimit(3).textSelection(.enabled)
                            HStack {
                                Text(record.createdAt, style: .date)
                                    .font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Button("Copy") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(record.text, forType: .string)
                                }
                                Button("Insert") { controller.insertHistory(record) }
                                Button("Delete", role: .destructive) { history.delete(record.id) }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(18)
    }
}
