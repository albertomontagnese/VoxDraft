import AppKit
import Combine

@MainActor
final class DictationController: ObservableObject {
    enum Phase: Equatable {
        case ready, preparing, recording, processing, finished, failed
    }

    @Published var phase: Phase = .ready
    @Published var transcript = ""
    @Published var message = ""
    @Published var lastText = ""
    let history = HistoryStore()

    private let engine = DictationEngine()
    private let inserter = TextInserter()
    private let hotkey = GlobalHotkey()
    private var hud: StatusHUD?
    private var generation = 0

    init() {
        hotkey.onPress = { [weak self] in
            Task { @MainActor in self?.toggle() }
        }
        engine.onPartial = { [weak self] text in self?.transcript = text }
        engine.onError = { [weak self] error in self?.message = error }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hud = StatusHUD(controller: self)
        }
    }

    var isRecording: Bool { phase == .recording }
    var shortcutAvailable: Bool { hotkey.isRegistered }

    func toggle() {
        switch phase {
        case .ready, .finished, .failed: Task { await start() }
        case .recording: Task { await stop() }
        case .preparing, .processing: break
        }
    }

    private func start() async {
        generation += 1
        let current = generation
        inserter.captureTarget()
        phase = .preparing
        transcript = ""
        message = "Requesting microphone and speech access…"
        hud?.show()
        let defaults = UserDefaults.standard
        let localeID = defaults.string(forKey: "locale") ?? Locale.current.identifier
        let localOnly = defaults.bool(forKey: "localOnly")
        do {
            try await engine.start(locale: Locale(identifier: localeID), localOnly: localOnly)
            guard current == generation else { return }
            phase = .recording
            message = "Listening · press ⌃⌥D to finish"
        } catch {
            fail(error.localizedDescription)
        }
    }

    private func stop() async {
        phase = .processing
        message = "Finishing transcription…"
        let raw = await engine.stop()
        guard !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fail("No speech was recognized. Try again closer to the microphone.")
            return
        }
        var result = UserDefaults.standard.bool(forKey: "basicCleanup") ? TextCleanup.basic(raw) : raw
        if UserDefaults.standard.bool(forKey: "useHermes") {
            message = "Polishing with local Hermes…"
            do {
                result = try await TextCleanup.hermes(result,
                    endpoint: UserDefaults.standard.string(forKey: "hermesEndpoint") ?? "http://127.0.0.1:11434/api/generate",
                    model: UserDefaults.standard.string(forKey: "hermesModel") ?? "hermes3")
            } catch {
                message = "Hermes unavailable; using transcription."
            }
        }
        transcript = result
        lastText = result
        history.add(result)
        let inserted = await inserter.insert(result)
        phase = .finished
        message = inserted ? "Inserted into the active app" : "Copied to clipboard · allow Accessibility to insert automatically"
        scheduleHide()
    }

    func insertHistory(_ record: DictationRecord) {
        inserter.captureTarget()
        Task {
            let inserted = await inserter.insert(record.text)
            phase = .finished
            transcript = record.text
            message = inserted ? "Inserted into the active app" : "Copied to clipboard · allow Accessibility to insert automatically"
            hud?.show()
            scheduleHide()
        }
    }

    func copyLast() {
        guard !lastText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(lastText, forType: .string)
    }

    func requestAccessibility() { inserter.requestAccessibility() }

    private func fail(_ text: String) {
        phase = .failed
        message = text
        hud?.show()
        scheduleHide()
    }

    private func scheduleHide() {
        let current = generation
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard let self, self.generation == current, self.phase != .recording else { return }
            self.hud?.hide()
        }
    }
}
