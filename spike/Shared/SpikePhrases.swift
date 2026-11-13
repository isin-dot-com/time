import Foundation

/// Hardcoded phrases. "A:" = fresh content, "B:" = after staleDate, so the tester sees which one is on screen.
enum SpikePhrases {
    static let a: [String] = [
        "A: День длинный. Начни с одного дела.",
        "A: 15 часов. Потом их не будет.",
        "A: Лента никуда не денется. День — денется.",
        "A: У тебя впереди целый день. Он твой.",
        "A: Час. Хватит, чтобы закончить одно."
    ]

    static let b: [String] = [
        "B: Окно само сменило фразу (staleDate).",
        "B: Половина позади. Что главное сейчас?",
        "B: Телефон подождёт.",
        "B: Последний час. Самое время начать, да?",
        "B: Ты сегодня уже много сделал."
    ]

    static func phraseA(_ index: Int) -> String {
        a[((index % a.count) + a.count) % a.count]
    }

    static func phraseB(_ index: Int) -> String {
        b[((index % b.count) + b.count) % b.count]
    }
}
