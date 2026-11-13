import ActivityKit
import Foundation
import UIKit
import UserNotifications

typealias DayActivity = Activity<DayAttributes>

/// All ActivityKit calls of the spike. App target only (the widget extension never starts activities).
enum LiveActivityLab {

    // MARK: - Formatting helpers

    static func short(_ id: String) -> String {
        String(id.prefix(6))
    }

    static func stateName(_ state: ActivityState) -> String {
        switch state {
        case .pending: return "pending (ждёт старта)"
        case .active: return "active"
        case .stale: return "stale (устарело)"
        case .ended: return "ended"
        case .dismissed: return "dismissed"
        @unknown default: return "неизвестно: \(String(describing: state))"
        }
    }

    static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        return "\(String(reflecting: error)) | \(error.localizedDescription) | \(nsError.domain)#\(nsError.code)"
    }

    static func authSummary() -> String {
        let info = ActivityAuthorizationInfo()
        return "areActivitiesEnabled=\(info.areActivitiesEnabled), frequentPushesEnabled=\(info.frequentPushesEnabled)"
    }

    private static func makeContent(dayStart: Date, bedtime: Date, segmentName: String, index: Int) -> ActivityContent<DayAttributes.ContentState> {
        let state = DayAttributes.ContentState(
            dayStart: dayStart,
            bedtime: bedtime,
            segmentName: segmentName,
            phrase: SpikePhrases.phraseA(index),
            stalePhrase: SpikePhrases.phraseB(index),
            phraseIndex: index
        )
        let staleDate = SpikeSettings.stale.staleDate(segmentStart: dayStart, segmentEnd: bedtime)
        return ActivityContent(state: state, staleDate: staleDate, relevanceScore: 50)
    }

    // MARK: - 1. Start now (foreground app, or a LiveActivityIntent running in the background)

    @discardableResult
    static func startNow(bedtime requestedBedtime: Date, label: String) -> Bool {
        let now = Date()
        let bedtime = requestedBedtime > now.addingTimeInterval(30) ? requestedBedtime : now.addingTimeInterval(5 * 60)
        let content = makeContent(dayStart: now, bedtime: bedtime, segmentName: "Сейчас", index: Int.random(in: 0..<100))
        let attributes = DayAttributes(label: label, fontVariant: SpikeSettings.font.rawValue)
        SpikeLog.add("→ старт сейчас [\(label)] до \(SpikeTime.full(bedtime)), stale=\(SpikeTime.full(content.staleDate)), шрифт=\(attributes.fontVariant); \(authSummary())")
        do {
            let activity = try DayActivity.request(attributes: attributes, content: content, pushType: nil)
            SpikeLog.add("OK старт сейчас id=\(short(activity.id)) state=\(stateName(activity.activityState)); окон всего: \(DayActivity.activities.count)")
            return true
        } catch {
            SpikeLog.add("ОШИБКА старт сейчас [\(label)]: \(describe(error))")
            return false
        }
    }

    // MARK: - 2. Scheduled start (iOS 26: request(attributes:content:pushType:style:alertConfiguration:start:))

    @discardableResult
    static func schedule(start: Date, end: Date, segmentName: String, label: String, index: Int = 0) -> Bool {
        let content = makeContent(dayStart: start, bedtime: end, segmentName: segmentName, index: index)
        let attributes = DayAttributes(label: label, fontVariant: SpikeSettings.font.rawValue)
        let sound = SpikeSettings.sound
        let phrase = content.state.phrase
        let alert = AlertConfiguration(
            title: "\(segmentName)",
            body: "\(phrase)",
            sound: sound.alertSound
        )
        do {
            let activity = try DayActivity.request(
                attributes: attributes,
                content: content,
                pushType: nil,
                style: .standard,
                alertConfiguration: alert,
                start: start
            )
            SpikeLog.add("OK запланировано [\(label)] старт \(SpikeTime.full(start)), конец \(SpikeTime.full(end)), stale=\(SpikeTime.full(content.staleDate)), звук=\(sound.logName), id=\(short(activity.id)), state=\(stateName(activity.activityState)); окон всего: \(DayActivity.activities.count)")
            return true
        } catch {
            SpikeLog.add("ОШИБКА планирования [\(label)] старт \(SpikeTime.full(start)): \(describe(error)); окон всего: \(DayActivity.activities.count)")
            return false
        }
    }

    static func scheduleIn(minutes: Double, durationMinutes: Double, label: String) {
        let start = Date().addingTimeInterval(minutes * 60)
        schedule(
            start: start,
            end: start.addingTimeInterval(durationMinutes * 60),
            segmentName: "Через \(Int(minutes)) мин",
            label: label
        )
    }

    /// Three 3-minute segments starting in 1 minute, back to back.
    static func scheduleBackToBack() {
        let base = Date().addingTimeInterval(60)
        for i in 0..<3 {
            let start = base.addingTimeInterval(Double(i) * 180)
            schedule(
                start: start,
                end: start.addingTimeInterval(180),
                segmentName: "Отрезок \(i + 1)/3",
                label: "3 подряд #\(i + 1)",
                index: i
            )
        }
    }

    /// 08:00 on each given day offset, counting down to 23:00 of that day.
    static func scheduleMorning(dayOffsets: [Int], label: String) {
        for offset in dayOffsets {
            let start = SpikeTime.at(dayOffset: offset, hour: 8)
            let end = SpikeTime.at(dayOffset: offset, hour: 23)
            schedule(
                start: start,
                end: end,
                segmentName: "Утро +\(offset) дн.",
                label: "\(label) +\(offset)д",
                index: offset
            )
        }
    }

    /// Schedules up to `maxCount` activities (tomorrow 10:00, 10:01, …) and stops at the first error.
    static func scheduleUntilLimit(maxCount: Int = 12) {
        SpikeLog.add("→ тест лимита: до \(maxCount) окон на завтра 10:00+k мин; окон до теста: \(DayActivity.activities.count)")
        var succeeded = 0
        for k in 0..<maxCount {
            let start = SpikeTime.at(dayOffset: 1, hour: 10, minute: k)
            let ok = schedule(
                start: start,
                end: start.addingTimeInterval(10 * 60),
                segmentName: "Лимит #\(k + 1)",
                label: "лимит #\(k + 1)",
                index: k
            )
            if ok {
                succeeded += 1
            } else {
                break
            }
        }
        SpikeLog.add("← тест лимита: принято \(succeeded); окон всего: \(DayActivity.activities.count)")
    }

    /// How far ahead the system accepts a scheduled start.
    static func scheduleFarAhead() {
        scheduleMorning(dayOffsets: [3, 7, 14, 28], label: "дальность")
    }

    // MARK: - 4. List / end

    struct Row: Identifiable {
        let id: String
        let label: String
        let state: String
        let segment: String
        let start: Date
        let end: Date
        let staleDate: Date?
        let phrase: String
        let fontVariant: String
    }

    static func rows() -> [Row] {
        DayActivity.activities.map { activity in
            let content = activity.content
            return Row(
                id: activity.id,
                label: activity.attributes.label,
                state: stateName(activity.activityState),
                segment: content.state.segmentName,
                start: content.state.dayStart,
                end: content.state.bedtime,
                staleDate: content.staleDate,
                phrase: content.state.phrase,
                fontVariant: activity.attributes.fontVariant
            )
        }
    }

    static func endAll() async {
        let all = DayActivity.activities
        SpikeLog.add("→ завершить все: \(all.count) шт.")
        for activity in all {
            let before = stateName(activity.activityState)
            await activity.end(nil, dismissalPolicy: .immediate)
            SpikeLog.add("end id=\(short(activity.id)) [\(activity.attributes.label)]: \(before) → \(stateName(activity.activityState))")
        }
        SpikeLog.add("← после завершения окон: \(DayActivity.activities.count)")
    }

    private static let snapshotKey = "spike.lastStates.v1"

    /// Compares the current activity states with the last saved snapshot and logs every change.
    /// Called on launch, on return to foreground and every 2 s while the app is open, so the log shows
    /// e.g. "pending → active" for activities that started while the app was closed (question 1).
    static func snapshot(reason: String?) {
        var current: [String: String] = [:]
        for activity in DayActivity.activities {
            current[activity.id] = "\(stateName(activity.activityState)) [\(activity.attributes.label)]"
        }
        let previous = (UserDefaults.standard.dictionary(forKey: snapshotKey) as? [String: String]) ?? [:]
        var changes: [String] = []
        for (id, description) in current where previous[id] != description {
            changes.append("\(short(id)): \(previous[id] ?? "новое") → \(description)")
        }
        for (id, description) in previous where current[id] == nil {
            changes.append("\(short(id)): \(description) → исчезло из списка")
        }
        let prefix = reason.map { "[снимок, \($0)]" } ?? "[снимок]"
        if !changes.isEmpty {
            SpikeLog.add("\(prefix) " + changes.sorted().joined(separator: "; "))
        } else if reason != nil {
            SpikeLog.add("\(prefix) без изменений, окон: \(current.count)")
        }
        UserDefaults.standard.set(current, forKey: snapshotKey)
    }

    // MARK: - 5/6. LiveActivityIntent handlers (run in the app process)

    static func handleStartIntent(source: String) async {
        let appState = await MainActor.run { () -> String in
            switch UIApplication.shared.applicationState {
            case .active: return "active"
            case .inactive: return "inactive"
            case .background: return "background"
            @unknown default: return "unknown"
            }
        }
        SpikeLog.add("StartDayIntent.perform: источник=\(source), состояние приложения=\(appState)")
        startNow(bedtime: SpikeTime.nextBedtime(), label: "интент: \(source)")
    }

    static func swapPhrase(activityID: String) async {
        guard let activity = DayActivity.activities.first(where: { $0.id == activityID }) else {
            SpikeLog.add("SwapPhraseIntent: окно \(short(activityID)) не найдено")
            return
        }
        let old = activity.content
        var state = old.state
        state.phraseIndex += 1
        let now = Date()
        let showingB = activity.activityState == .stale || (old.staleDate.map { $0 <= now } ?? false)
        if showingB {
            state.stalePhrase = SpikePhrases.phraseB(state.phraseIndex)
        } else {
            state.phrase = SpikePhrases.phraseA(state.phraseIndex)
        }
        await activity.update(ActivityContent(state: state, staleDate: old.staleDate, relevanceScore: old.relevanceScore))
        let shown = showingB ? state.stalePhrase : state.phrase
        SpikeLog.add("SwapPhraseIntent: id=\(short(activityID)) новая фраза \(showingB ? "B" : "A"): «\(shown)»")
    }

    // MARK: - Notifications (context for question 3: is the alert sound tied to notification permission?)

    static func logNotificationSettings() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        SpikeLog.add("уведомления: authorizationStatus=\(settings.authorizationStatus.rawValue) (0 не спрашивали, 1 запрещено, 2 разрешено, 3 provisional), sound=\(settings.soundSetting.rawValue), alert=\(settings.alertSetting.rawValue), lockScreen=\(settings.lockScreenSetting.rawValue) (0 n/a, 1 выкл, 2 вкл)")
    }

    static func requestNotifications() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            SpikeLog.add("уведомления: requestAuthorization → \(granted)")
        } catch {
            SpikeLog.add("уведомления: ошибка запроса: \(describe(error))")
        }
        await logNotificationSettings()
    }
}
