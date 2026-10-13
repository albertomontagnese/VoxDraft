import Foundation

struct DictationRecord: Identifiable, Codable {
    var id = UUID()
    var createdAt = Date()
    var text: String
}

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var records: [DictationRecord] = []
    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("VoxDraft", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("history.json")
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([DictationRecord].self, from: data) {
            records = saved
        }
    }

    func add(_ text: String) {
        records.insert(DictationRecord(text: text), at: 0)
        records = Array(records.prefix(100))
        save()
    }

    func delete(_ id: UUID) {
        records.removeAll { $0.id == id }
        save()
    }

    func clear() {
        records = []
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
