import Foundation

/// Bildirim ayarları, UsageService'in kalıcı alanlarından türetilir
struct ThresholdSettings: Equatable, Sendable {
    var at50: Bool
    var at75: Bool
    var at100: Bool
    var onReset: Bool
}

/// Bir kovanın tek bir yoklamadaki durumu; eşik karşılaştırması için yeterli
struct BucketSnapshot: Equatable, Sendable {
    let percent: Int
    let resetsAt: String?
}

enum UsageEvent: Equatable, Sendable {
    case reached50
    case reached75
    case limitReached
    case reset
}

/// Önceki ve yeni kova durumundan bildirim olaylarını türetir. Yan etkisi yoktur,
/// bu yüzden UsageService'ten bağımsız test edilebilir.
enum UsageThresholds {
    static func events(previous: BucketSnapshot?, current: BucketSnapshot, settings: ThresholdSettings) -> [UsageEvent] {
        // İlk yoklamada karşılaştırma yapılacak geçmiş yok; uygulama açılışında sahte bildirim üretmemek için sessiz kal
        guard let previous else { return [] }

        var events: [UsageEvent] = []
        let old = previous.percent
        let new = current.percent

        if settings.at50, old < 50, new >= 50 { events.append(.reached50) }
        if settings.at75, old < 75, new >= 75 { events.append(.reached75) }
        if settings.at100, old < 100, new >= 100 { events.append(.limitReached) }

        if settings.onReset, old > 0, didReset(previous: previous, current: current) {
            events.append(.reset)
        }
        return events
    }

    /// Sıfırlanma iki şekilde anlaşılır: kullanım sıfıra düştü, ya da kullanım azaldı ve
    /// sıfırlanma zamanı ileri kaydı (pencere yenilendi ama kullanıcı hemen kullanmaya başladı).
    private static func didReset(previous: BucketSnapshot, current: BucketSnapshot) -> Bool {
        if current.percent == 0 { return true }
        guard current.percent < previous.percent,
              let oldReset = ISO8601.parse(previous.resetsAt),
              let newReset = ISO8601.parse(current.resetsAt) else { return false }
        return newReset > oldReset
    }
}
