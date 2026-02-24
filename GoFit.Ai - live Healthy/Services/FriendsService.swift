import Foundation

class FriendsService: NSObject, ObservableObject {
    static let shared = FriendsService()
    
    @Published var friends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var searchResults: [SearchResult] = []
    @Published var nearbyUsers: [NearbyUser] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseURL: String
    
    override init() {
        if let baseURL = UserDefaults.standard.string(forKey: "backendURL"), !baseURL.isEmpty {
            self.baseURL = baseURL
        } else {
            // Default to production Render backend
            self.baseURL = "https://gofit-ai-live-healthy-1.onrender.com"
        }
        super.init()
    }
    
    // MARK: - Friend Requests
    
    /// Send a friend request to another user
    func sendFriendRequest(to userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/friends/request/\(userId)"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    let error = NSError(domain: "No data", code: -1)
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(FriendResponse.self, from: data)
                    completion(.success(response.message))
                } catch {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Fetch pending friend requests
    func fetchFriendRequests(completion: @escaping (Result<[FriendRequest], Error>) -> Void) {
        let endpoint = "\(baseURL)/api/friends/requests"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    let error = NSError(domain: "No data", code: -1)
                    completion(.failure(error))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(FriendRequestsResponse.self, from: data)
                    self?.friendRequests = response.requests
                    completion(.success(response.requests))
                } catch {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Accept a friend request
    func acceptFriendRequest(from friendId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/friends/accept/\(friendId)"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                do {
                    if let data = data {
                        let response = try JSONDecoder().decode(FriendResponse.self, from: data)
                        self?.friendRequests.removeAll { $0.id == friendId }
                        completion(.success(response.message))
                    }
                } catch {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Reject a friend request
    func rejectFriendRequest(from friendId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/friends/reject/\(friendId)"
        
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
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                self?.friendRequests.removeAll { $0.id == friendId }
                completion(.success("Friend request rejected"))
            }
        }.resume()
    }
    
    // MARK: - Friends List
    
    /// Fetch all accepted friends
    func fetchFriends(completion: @escaping (Result<[Friend], Error>) -> Void) {
        let endpoint = "\(baseURL)/api/friends"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    let error = NSError(domain: "No data", code: -1)
                    completion(.failure(error))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(FriendsListResponse.self, from: data)
                    self?.friends = response.friends
                    completion(.success(response.friends))
                } catch {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
        
        isLoading = true
    }
    
    /// Remove a friend
    func removeFriend(friendId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/friends/\(friendId)"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                self?.friends.removeAll { $0.id == friendId }
                completion(.success("Friend removed"))
            }
        }.resume()
    }
    
    // MARK: - Search Users
    
    /// Search for users by username or email
    func searchUsers(query: String, completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        guard query.count >= 2 else {
            completion(.success([]))
            return
        }
        
        let endpoint = "\(baseURL)/api/friends/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&limit=20"
        
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
                    let error = NSError(domain: "No data", code: -1)
                    completion(.failure(error))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(SearchUsersResponse.self, from: data)
                    self?.searchResults = response.results
                    completion(.success(response.results))
                } catch {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Nearby People

    /// Update current user's location for nearby discovery
    func updateNearbyLocation(latitude: Double, longitude: Double, optIn: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/friends/location"
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

        let payload: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "optIn": optIn
        ]
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
                    let response = try JSONDecoder().decode(FriendResponse.self, from: data)
                    completion(.success(response.message))
                } catch {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    /// Fetch nearby users within a radius (km)
    func fetchNearby(radiusKm: Double = 5, ageMin: Int? = nil, ageMax: Int? = nil, goal: String? = nil, completion: @escaping (Result<[NearbyUser], Error>) -> Void) {
        var queryItems: [String] = ["radiusKm=\(radiusKm)", "limit=20"]
        if let ageMin = ageMin { queryItems.append("ageMin=\(ageMin)") }
        if let ageMax = ageMax { queryItems.append("ageMax=\(ageMax)") }
        if let goal = goal, goal != "any" { queryItems.append("goal=\(goal)") }
        let endpoint = "\(baseURL)/api/friends/nearby?\(queryItems.joined(separator: "&"))"
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
                    let response = try JSONDecoder().decode(NearbyUsersResponse.self, from: data)
                    self?.nearbyUsers = response.results
                    completion(.success(response.results))
                } catch {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Block/Unblock
    
    /// Block a user
    func blockUser(userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/friends/block/\(userId)"
        
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
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                completion(.success("User blocked"))
            }
        }.resume()
    }
    
    /// Get friend statistics
    func getFriendStats(friendId: String, completion: @escaping (Result<FriendStats, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/friends/\(friendId)/stats"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(FriendStatsResponse.self, from: data)
                    completion(.success(response.stats))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
