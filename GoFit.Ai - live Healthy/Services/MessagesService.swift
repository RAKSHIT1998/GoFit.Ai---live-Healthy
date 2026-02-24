import Foundation

final class MessagesService: ObservableObject {
    static let shared = MessagesService()

    @Published var isLoading = false
    @Published var error: String?

    private let baseURL: String

    private init() {
        if let baseURL = UserDefaults.standard.string(forKey: "backendURL"), !baseURL.isEmpty {
            self.baseURL = baseURL
        } else {
            self.baseURL = "https://gofit-ai-live-healthy-1.onrender.com"
        }
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func fetchConversations(completion: @escaping (Result<[ConversationSummary], Error>) -> Void) {
        let endpoint = "\(baseURL)/api/messages"
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        isLoading = true
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                    return
                }
                do {
                    let decoded = try self?.makeDecoder().decode(ConversationsResponse.self, from: data)
                    completion(.success(decoded?.conversations ?? []))
                } catch {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    func fetchConversation(friendId: String, completion: @escaping (Result<[MessageItem], Error>) -> Void) {
        let endpoint = "\(baseURL)/api/messages/\(friendId)"
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        isLoading = true
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                    return
                }
                do {
                    let decoded = try self?.makeDecoder().decode(MessagesResponse.self, from: data)
                    completion(.success(decoded?.messages ?? []))
                } catch {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    func sendMessage(friendId: String, message: String, completion: @escaping (Result<MessageItem, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/messages/\(friendId)"
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [String: Any] = ["message": message, "messageType": "text"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                    return
                }
                do {
                    let decoded = try self?.makeDecoder().decode(MessageSendResponse.self, from: data)
                    if let decoded = decoded {
                        completion(.success(decoded.data))
                    } else {
                        completion(.failure(NSError(domain: "DecodeError", code: -1)))
                    }
                } catch {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

struct MessageSendResponse: Codable {
    let message: String
    let data: MessageItem
}
