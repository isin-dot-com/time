import AppIntents

/// Exposes StartDayIntent to Shortcuts/Siri without setup, so the tester can build a
/// "Time of Day" automation (question 5). App target only — one provider per app.
struct SpikeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartDayIntent(),
            phrases: [
                "Start day in \(.applicationName)",
                "Начать день в \(.applicationName)"
            ],
            shortTitle: "Начать день",
            systemImageName: "sunrise.fill"
        )
    }
}
