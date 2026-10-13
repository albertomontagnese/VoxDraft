import AVFoundation
import Speech

@MainActor
final class DictationEngine {
    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var finalContinuation: CheckedContinuation<String, Never>?
    private var lastTranscript = ""
    private var stopping = false
    var onPartial: ((String) -> Void)?
    var onError: ((String) -> Void)?

    func start(locale: Locale, localOnly: Bool) async throws {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        guard speechAllowed else { throw DictationError.speechPermission }
        let micAllowed = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { continuation.resume(returning: $0) }
        }
        guard micAllowed else { throw DictationError.microphonePermission }
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw DictationError.unavailable
        }
        guard !localOnly || recognizer.supportsOnDeviceRecognition else {
            throw DictationError.localUnavailable
        }
        self.recognizer = recognizer
        lastTranscript = ""
        stopping = false
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        request.requiresOnDeviceRecognition = localOnly
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            input.removeTap(onBus: 0)
            self.request = nil
            throw error
        }
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {
                    self.lastTranscript = result.bestTranscription.formattedString
                    self.onPartial?(self.lastTranscript)
                    if result.isFinal { self.finish() }
                }
                if let error {
                    if !self.stopping { self.onError?(error.localizedDescription) }
                    self.finish()
                }
            }
        }
    }

    func stop() async -> String {
        guard request != nil else { return lastTranscript }
        stopping = true
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        // Give the recognizer time to return its final punctuation and trailing words.
        let final = await withCheckedContinuation { continuation in
            finalContinuation = continuation
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                self?.finish()
            }
        }
        task?.cancel()
        task = nil
        request = nil
        recognizer = nil
        return final
    }

    private func finish() {
        guard let finalContinuation else { return }
        self.finalContinuation = nil
        finalContinuation.resume(returning: lastTranscript)
    }

    enum DictationError: LocalizedError {
        case speechPermission, microphonePermission, unavailable, localUnavailable
        var errorDescription: String? {
            switch self {
            case .speechPermission: return "Enable Speech Recognition for VoxDraft in System Settings."
            case .microphonePermission: return "Enable Microphone access for VoxDraft in System Settings."
            case .unavailable: return "Speech recognition is unavailable for this language right now."
            case .localUnavailable: return "On-device recognition is unavailable for this language. Turn off Local only or choose another language."
            }
        }
    }
}
