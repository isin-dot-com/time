import SwiftUI
import UIKit

@main
struct TimeSpikeApp: App {
    init() {
        // Also runs when the system launches the process in the background for a LiveActivityIntent,
        // so this line in the log tells the tester that the widget/shortcut actually woke the app.
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        let fontLoaded = UIFont(name: SpikeFont.postScriptName, size: 12) != nil
        SpikeLog.add("— процесс приложения запущен (сборка \(build), iOS \(UIDevice.current.systemVersion)); свой шрифт в приложении: \(fontLoaded ? "загружен" : "НЕ загружен")")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
