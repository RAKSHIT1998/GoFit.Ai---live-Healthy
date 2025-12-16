import Foundation

/// Local queued meal item (keeps clientId for mapping)
struct QueuedMeal: Codable, Identifiable {
    let id: String        // clientId (UUID string)
    let timestamp: Date
    let imageDataBase64: String? // optional base64 of image (small images) OR imageUrl local file path
    let items: [ParsedItemDTO]
    let recommendations: String?
    let rawAiResponse: [String: AnyCodable]? // optional raw for debugging
}

/// Small helper to encode Any -> Codable container
struct AnyCodable: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { value = v }
        else if let v = try? container.decode(Int.self) { value = v }
        else if let v = try? container.decode(Double.self) { value = v }
        else if let v = try? container.decode(String.self) { value = v }
        else if let v = try? container.decode([String: AnyCodable].self) { value = v.mapValues { $0.value } }
        else if let v = try? container.decode([AnyCodable].self) { value = v.map { $0.value } }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported") }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try container.encode(v)
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as [String: Any]: try container.encode(v.mapValues { AnyCodable($0) })
        case let v as [Any]: try container.encode(v.map { AnyCodable($0) })
        default: try container.encode(String(describing: value))
        }
    }
}

// MARK: - OfflineMealStore
final class OfflineMealStore {
    static let shared = OfflineMealStore()
    private init() { load() }

    private var queue: [QueuedMeal] = []
    private let fileURL: URL = {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("offline_meals_queue.json")
    }()

    private let queueLock = DispatchQueue(label: "offline.meal.queue")

    // load from disk
    func load() {
        queueLock.sync {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { queue = []; return }
            do {
                let data = try Data(contentsOf: fileURL)
                queue = try JSONDecoder().decode([QueuedMeal].self, from: data)
            } catch {
                print("OfflineMealStore.load error:", error)
                queue = []
            }
        }
    }

    // persist to disk
    private func persist() {
        queueLock.async {
            do {
                let data = try JSONEncoder().encode(self.queue)
                try data.write(to: self.fileURL, options: [.atomic])
            } catch {
                print("OfflineMealStore.persist error:", error)
            }
        }
    }

    // enqueue
    func enqueue(imageDataBase64: String?, items: [ParsedItemDTO], recommendations: String?, rawAi: [String: Any]? = nil) -> String {
        let id = UUID().uuidString
        let qm = QueuedMeal(id: id,
                            timestamp: Date(),
                            imageDataBase64: imageDataBase64,
                            items: items,
                            recommendations: recommendations,
                            rawAiResponse: rawAi?.mapValues { AnyCodable($0) })
        queueLock.sync {
            queue.append(qm)
            persist()
        }
        return id
    }

    // peek
    func allQueued() -> [QueuedMeal] {
        return queueLock.sync { queue }
    }

    // remove by client id
    func remove(clientId: String) {
        queueLock.sync {
            queue.removeAll { $0.id == clientId }
            persist()
        }
    }

    // clear all
    func clearAll() {
        queueLock.sync {
            queue.removeAll()
            persist()
        }
    }
}
