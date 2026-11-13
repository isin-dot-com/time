import ActivityKit
import Foundation

/// Compiled into BOTH the app and the widget extension (see project.yml).
/// The type name must be identical in both modules so the extension can render activities the app starts.
struct DayAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Start of the countdown / progress range (segment start).
        var dayStart: Date
        /// What the timer counts down to ("до отбоя").
        var bedtime: Date
        var segmentName: String
        /// Phrase A: shown while the content is fresh.
        var phrase: String
        /// Phrase B: shown once `context.isStale` becomes true (staleDate passed) — question 2.
        var stalePhrase: String
        var phraseIndex: Int

        /// Always a valid range: ClosedRange traps when lower > upper, which would kill the extension silently.
        var timerRange: ClosedRange<Date> {
            let upper = max(bedtime, dayStart.addingTimeInterval(1))
            return dayStart...upper
        }
    }

    /// Human label of the test that created the activity (e.g. "+2 мин", "завтра +1д").
    var label: String
    /// "custom" or "system" — FontVariant.rawValue. Static for the life of the activity.
    var fontVariant: String
}
