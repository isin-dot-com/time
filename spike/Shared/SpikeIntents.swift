import ActivityKit
import AppIntents
import Foundation

// Compiled into BOTH targets (project.yml), because the widget extension needs the types for
// Button(intent:). Apple: "If you adopt the LiveActivityIntent ... protocol, the system runs the
// app intent in the app's process. Make sure to add your custom app intent to your app target."
// (WidgetKit > Adding interactivity to widgets and Live Activities).
// The extension copy is therefore a stub: LiveActivityLab exists only in the app target, and the
// WIDGET_EXTENSION compilation condition is defined only for the extension.

/// Starts a Live Activity counting down to 23:00. Used by the Lock Screen widget button (question 4)
/// and exposed as an App Shortcut for a Shortcuts time-of-day automation (question 5).
struct StartDayIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Начать день (spike)"

    @Parameter(title: "Источник")
    var source: String?

    init() {}

    init(source: String) {
        self.source = source
    }

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await LiveActivityLab.handleStartIntent(source: source ?? "команда/Siri")
        #endif
        return .result()
    }
}

/// The "другая фраза" button inside the Live Activity.
struct SwapPhraseIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Другая фраза (spike)"

    @Parameter(title: "ID окна")
    var activityID: String

    init() {}

    init(activityID: String) {
        self.activityID = activityID
    }

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await LiveActivityLab.swapPhrase(activityID: activityID)
        #endif
        return .result()
    }
}
