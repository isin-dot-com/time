import ActivityKit
import Foundation

/// Alert sound for scheduled starts (question 3).
/// AlertConfiguration.AlertSound.named(_:) — "The name of the sound file to use for the alert. Choose a file
/// that's in your app's main bundle or the Library/Sounds folder of your app's data container."
/// The docs do not say whether the extension is required, so both spellings are offered.
enum SoundChoice: String, CaseIterable, Identifiable {
    case systemDefault
    case quietWav
    case silentWav
    case silentNoExtension

    var id: String { rawValue }

    var title: String {
        switch self {
        case .systemDefault: return "Системный (.default)"
        case .quietWav: return "Тихий: quiet.wav"
        case .silentWav: return "Тишина: silent.wav"
        case .silentNoExtension: return "Тишина: «silent» без расширения"
        }
    }

    var logName: String {
        switch self {
        case .systemDefault: return ".default"
        case .quietWav: return ".named(\"quiet.wav\")"
        case .silentWav: return ".named(\"silent.wav\")"
        case .silentNoExtension: return ".named(\"silent\")"
        }
    }

    var alertSound: AlertConfiguration.AlertSound {
        switch self {
        case .systemDefault: return .default
        case .quietWav: return .named("quiet.wav")
        case .silentWav: return .named("silent.wav")
        case .silentNoExtension: return .named("silent")
        }
    }
}

/// When the content becomes stale (question 2): the view shows phrase B once `context.isStale` is true.
enum StaleChoice: String, CaseIterable, Identifiable {
    case off
    case plus1
    case plus2
    case plus5
    case middle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: return "нет"
        case .plus1: return "+1м"
        case .plus2: return "+2м"
        case .plus5: return "+5м"
        case .middle: return "½"
        }
    }

    /// Offsets are counted from the segment start (for "старт сейчас" that is now).
    func staleDate(segmentStart: Date, segmentEnd: Date) -> Date? {
        switch self {
        case .off:
            return nil
        case .plus1:
            return segmentStart.addingTimeInterval(60)
        case .plus2:
            return segmentStart.addingTimeInterval(120)
        case .plus5:
            return segmentStart.addingTimeInterval(300)
        case .middle:
            // A Live Activity lives at most 8 h, so "middle" is the middle of what can actually be shown.
            let cappedEnd = min(segmentEnd, segmentStart.addingTimeInterval(8 * 3600))
            return segmentStart.addingTimeInterval(cappedEnd.timeIntervalSince(segmentStart) / 2)
        }
    }
}

/// Settings live in UserDefaults.standard so LiveActivityIntents (which run in the app process) see them too.
enum SpikeSettings {
    static let fontKey = "spike.font"
    static let soundKey = "spike.sound"
    static let staleKey = "spike.stale"

    static var font: FontVariant {
        FontVariant(rawValue: UserDefaults.standard.string(forKey: fontKey) ?? "") ?? .custom
    }

    static var sound: SoundChoice {
        SoundChoice(rawValue: UserDefaults.standard.string(forKey: soundKey) ?? "") ?? .systemDefault
    }

    static var stale: StaleChoice {
        StaleChoice(rawValue: UserDefaults.standard.string(forKey: staleKey) ?? "") ?? .plus2
    }
}
