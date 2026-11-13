import Combine
import Foundation

/// On-screen log with timestamps, persisted in UserDefaults so it survives relaunches and
/// captures what LiveActivityIntents did while the app was in the background.
final class SpikeLog: ObservableObject {
    static let shared = SpikeLog()

    @Published private(set) var lines: [String]

    private static let key = "spike.log.v1"
    private static let maxLines = 1500
    private static let lock = NSLock()

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM HH:mm:ss"
        return formatter
    }()

    private init() {
        lines = UserDefaults.standard.stringArray(forKey: SpikeLog.key) ?? []
    }

    /// Thread-safe; persists synchronously (the process may be suspended right after an intent returns).
    static func add(_ message: String) {
        let line = "\(formatter.string(from: Date())) \(message)"
        lock.lock()
        var stored = UserDefaults.standard.stringArray(forKey: key) ?? []
        stored.append(line)
        if stored.count > maxLines {
            stored.removeFirst(stored.count - maxLines)
        }
        UserDefaults.standard.set(stored, forKey: key)
        lock.unlock()

        let snapshot = stored
        if Thread.isMainThread {
            shared.lines = snapshot
        } else {
            DispatchQueue.main.async {
                SpikeLog.shared.lines = snapshot
            }
        }
        NSLog("[spike] %@", line)
    }

    func reload() {
        lines = UserDefaults.standard.stringArray(forKey: SpikeLog.key) ?? []
    }

    func clear() {
        SpikeLog.lock.lock()
        UserDefaults.standard.removeObject(forKey: SpikeLog.key)
        SpikeLog.lock.unlock()
        lines = []
        SpikeLog.add("журнал очищен")
    }

    var allText: String {
        lines.joined(separator: "\n")
    }
}
