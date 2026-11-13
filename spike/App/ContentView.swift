import Combine
import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject private var log = SpikeLog.shared
    @State private var rows: [LiveActivityLab.Row] = []
    @State private var authText = ""
    @State private var endTime = Date().addingTimeInterval(30 * 60)
    @AppStorage(SpikeSettings.fontKey) private var fontChoice: FontVariant = .custom
    @AppStorage(SpikeSettings.soundKey) private var soundChoice: SoundChoice = .systemDefault
    @AppStorage(SpikeSettings.staleKey) private var staleChoice: StaleChoice = .plus2
    @Environment(\.scenePhase) private var scenePhase

    private let ticker = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statusSection
                    settingsSection
                    startNowSection
                    scheduleSection
                    activitiesSection
                    logSection
                }
                .padding()
            }
            .navigationTitle("Spike: окно дня")
        }
        .onAppear {
            refresh(reason: "открытие экрана")
        }
        .task {
            await LiveActivityLab.logNotificationSettings()
        }
        .onReceive(ticker) { _ in
            refresh(reason: nil)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                log.reload()
                refresh(reason: "возврат в приложение")
            }
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: "Сборка \(Self.buildNumber) · iOS \(UIDevice.current.systemVersion)")
                .font(.footnote)
            Text(verbatim: authText)
                .font(.footnote)
            HStack(spacing: 8) {
                Text(verbatim: "Свой шрифт:")
                    .font(.footnote)
                Text(verbatim: "0123456789:")
                    .font(Font.custom(SpikeFont.postScriptName, size: 22))
                Text(verbatim: Self.fontLoaded ? "загружен" : "НЕ загружен")
                    .font(.footnote)
                    .foregroundStyle(Self.fontLoaded ? Color.green : Color.red)
            }
            Button {
                Task { await LiveActivityLab.requestNotifications() }
            } label: {
                Label("Запросить разрешение на уведомления", systemImage: "bell")
            }
            .buttonStyle(.bordered)
        }
    }

    private var settingsSection: some View {
        GroupBox("Настройки (сохраняются, действуют и на виджет/команду)") {
            VStack(alignment: .leading, spacing: 10) {
                Text(verbatim: "Шрифт цифр в окне")
                    .font(.caption)
                Picker("Шрифт", selection: $fontChoice) {
                    ForEach(FontVariant.allCases) { variant in
                        Text(verbatim: variant.title).tag(variant)
                    }
                }
                .pickerStyle(.segmented)

                Text(verbatim: "staleDate: через сколько окно само переключится на фразу B")
                    .font(.caption)
                Picker("staleDate", selection: $staleChoice) {
                    ForEach(StaleChoice.allCases) { choice in
                        Text(verbatim: choice.title).tag(choice)
                    }
                }
                .pickerStyle(.segmented)

                Text(verbatim: "Звук оповещения при запланированном старте")
                    .font(.caption)
                Picker("Звук", selection: $soundChoice) {
                    ForEach(SoundChoice.allCases) { choice in
                        Text(verbatim: choice.title).tag(choice)
                    }
                }
                .pickerStyle(.menu)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var startNowSection: some View {
        GroupBox("1. Окно сейчас") {
            VStack(alignment: .leading, spacing: 10) {
                DatePicker("Конец отсчёта", selection: $endTime, displayedComponents: .hourAndMinute)
                HStack {
                    Button("+5 мин") { endTime = Date().addingTimeInterval(5 * 60) }
                    Button("+30 мин") { endTime = Date().addingTimeInterval(30 * 60) }
                    Button("до 23:00") { endTime = SpikeTime.nextBedtime() }
                }
                .buttonStyle(.bordered)
                Text(verbatim: "Отсчёт до \(SpikeTime.full(resolvedEndTime))")
                    .font(.caption)
                BigButton("Старт сейчас", systemImage: "play.fill") {
                    let end = resolvedEndTime
                    LiveActivityLab.startNow(bedtime: end, label: "сейчас → \(SpikeTime.hm(end))")
                    refresh(reason: nil)
                }
            }
        }
    }

    private var scheduleSection: some View {
        GroupBox("2. Запланировать (iOS 26, start:)") {
            VStack(alignment: .leading, spacing: 10) {
                Text(verbatim: "Звук: \(soundChoice.title) · staleDate: \(staleChoice.title) · шрифт: \(fontChoice.title)")
                    .font(.caption)
                BigButton("Через 2 мин (окно на 10 мин)", systemImage: "timer") {
                    LiveActivityLab.scheduleIn(minutes: 2, durationMinutes: 10, label: "+2 мин")
                    refresh(reason: nil)
                }
                BigButton("Через 10 мин (окно на 10 мин)", systemImage: "timer") {
                    LiveActivityLab.scheduleIn(minutes: 10, durationMinutes: 10, label: "+10 мин")
                    refresh(reason: nil)
                }
                BigButton("3 подряд по 3 мин (с +1 мин)", systemImage: "square.stack.3d.up") {
                    LiveActivityLab.scheduleBackToBack()
                    refresh(reason: nil)
                }
                BigButton("Завтра 08:00", systemImage: "sunrise") {
                    LiveActivityLab.scheduleMorning(dayOffsets: [1], label: "завтра")
                    refresh(reason: nil)
                }
                BigButton("Завтра и послезавтра 08:00", systemImage: "calendar") {
                    LiveActivityLab.scheduleMorning(dayOffsets: [1, 2], label: "2 дня")
                    refresh(reason: nil)
                }
                BigButton("Лимит: до 12 шт. (завтра 10:00+)", systemImage: "number") {
                    LiveActivityLab.scheduleUntilLimit(maxCount: 12)
                    refresh(reason: nil)
                }
                BigButton("Дальность: +3/+7/+14/+28 дней", systemImage: "calendar.badge.clock") {
                    LiveActivityLab.scheduleFarAhead()
                    refresh(reason: nil)
                }
            }
        }
    }

    private var activitiesSection: some View {
        GroupBox("3. Окна приложения: \(rows.count)") {
            VStack(alignment: .leading, spacing: 8) {
                if rows.isEmpty {
                    Text(verbatim: "Нет окон")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: "\(row.state) · \(row.label)")
                            .font(.footnote.bold())
                        Text(verbatim: "\(row.segment): \(SpikeTime.full(row.start)) → \(SpikeTime.full(row.end)); stale \(SpikeTime.full(row.staleDate)); шрифт \(row.fontVariant)")
                            .font(.caption2)
                        Text(verbatim: "id \(LiveActivityLab.short(row.id)) · \(row.phrase)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                }
                HStack {
                    Button {
                        refresh(reason: "кнопка «Обновить»")
                    } label: {
                        Label("Обновить", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    Button(role: .destructive) {
                        Task {
                            await LiveActivityLab.endAll()
                            refresh(reason: "после «Завершить все»")
                        }
                    } label: {
                        Label("Завершить все", systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var logSection: some View {
        GroupBox("Журнал (сохраняется, новые сверху)") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Button {
                        UIPasteboard.general.string = log.allText
                        SpikeLog.add("журнал скопирован в буфер обмена")
                    } label: {
                        Label("Копировать всё", systemImage: "doc.on.doc")
                    }
                    Spacer()
                    Button(role: .destructive) {
                        log.clear()
                    } label: {
                        Label("Очистить", systemImage: "trash")
                    }
                }
                .buttonStyle(.bordered)
                ForEach(Array(log.lines.suffix(300).reversed().enumerated()), id: \.offset) { item in
                    Text(verbatim: item.element)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Next occurrence of the picked hour:minute (the DatePicker keeps a stale date part otherwise).
    private var resolvedEndTime: Date {
        let components = Calendar.current.dateComponents([.hour, .minute], from: endTime)
        return SpikeTime.next(hour: components.hour ?? 23, minute: components.minute ?? 0)
    }

    private func refresh(reason: String?) {
        LiveActivityLab.snapshot(reason: reason)
        rows = LiveActivityLab.rows()
        authText = LiveActivityLab.authSummary()
    }

    private static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }

    private static var fontLoaded: Bool {
        UIFont(name: SpikeFont.postScriptName, size: 12) != nil
    }
}

struct BigButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}
