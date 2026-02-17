//
//  WebSocketService.swift
//  GoFit.Ai - live Healthy
//
//  Real-time WebSocket service using Socket.IO
//  Handles instant friend requests, challenges, and notifications
//

import Foundation
import UIKit
import Combine

/// WebSocket service for real-time communication
class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var latestFriendRequest: FriendRequestNotification?
    @Published var latestChallenge: ChallengeNotification?
    @Published var latestAchievement: AchievementNotification?
    @Published var onlineUsers: Set<String> = []
    
    // MARK: - Private Properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var shouldReconnect = true
    
    private let baseURL: String
    private var authToken: String? {
        UserDefaults.standard.string(forKey: "authToken")
    }
    
    // MARK: - Initialization
    private init() {
        if let baseURL = UserDefaults.standard.string(forKey: "backendURL"), !baseURL.isEmpty {
            // Convert http to ws
            self.baseURL = baseURL.replacingOccurrences(of: "http://", with: "ws://")
                                  .replacingOccurrences(of: "https://", with: "wss://")
        } else {
            self.baseURL = "ws://localhost:3000"
        }
        
        // Listen for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        disconnect()
    }
    
    // MARK: - Connection Management
    
    /// Connect to WebSocket server with authentication
    func connect() {
        guard let token = authToken, !token.isEmpty else {
            print("⚠️ WebSocket: No auth token available")
            connectionStatus = .failed(error: "No authentication token")
            return
        }
        
        guard webSocketTask == nil else {
            print("⚠️ WebSocket: Already connected")
            return
        }
        
        // Build WebSocket URL with Socket.IO path
        var urlString = "\(baseURL)/socket.io/?EIO=4&transport=websocket"
        
        guard var urlComponents = URLComponents(string: urlString) else {
            print("❌ WebSocket: Invalid URL")
            connectionStatus = .failed(error: "Invalid URL")
            return
        }
        
        // Add auth token as query parameter (Socket.IO style)
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: "auth", value: token))
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            print("❌ WebSocket: Failed to build URL")
            return
        }
        
        print("🔌 WebSocket: Connecting to \(baseURL)...")
        connectionStatus = .connecting
        
        // Create WebSocket task
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessage()
        
        // Start ping timer to keep connection alive
        startPingTimer()
        
        // Reset reconnect attempts on successful connection attempt
        reconnectAttempts = 0
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionStatus = .connected
        }
        
        print("✅ WebSocket: Connected successfully")
    }
    
    /// Disconnect from WebSocket server
    func disconnect() {
        shouldReconnect = false
        stopPingTimer()
        stopReconnectTimer()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = .disconnected
        }
        
        print("🔌 WebSocket: Disconnected")
    }
    
    /// Reconnect with exponential backoff
    private func reconnect() {
        guard shouldReconnect else { return }
        guard reconnectAttempts < maxReconnectAttempts else {
            print("❌ WebSocket: Max reconnect attempts reached")
            connectionStatus = .failed(error: "Max reconnection attempts exceeded")
            return
        }
        
        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0) // Max 30 seconds
        
        print("🔄 WebSocket: Reconnecting in \(delay) seconds (attempt \(reconnectAttempts))")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    // MARK: - Message Handling
    
    /// Receive messages from WebSocket
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessage() // Continue listening
                
            case .failure(let error):
                print("❌ WebSocket: Receive error - \(error.localizedDescription)")
                self.handleDisconnection()
            }
        }
    }
    
    /// Handle incoming WebSocket message
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleSocketIOMessage(text)
            
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                handleSocketIOMessage(text)
            }
            
        @unknown default:
            break
        }
    }
    
    /// Parse Socket.IO message format
    private func handleSocketIOMessage(_ message: String) {
        // Socket.IO message format: <packet type>[<namespace>,]<data>
        // Example: 42["friend_request:received",{"from":{...}}]
        
        guard message.hasPrefix("42") else {
            // Handle connection/ping messages (0, 2, 3, 40, 41)
            if message == "0" || message.hasPrefix("0{") {
                print("✅ WebSocket: Connection acknowledged")
            } else if message == "2" {
                sendPing()
            }
            return
        }
        
        // Extract JSON array from Socket.IO message
        let jsonStart = message.index(message.startIndex, offsetBy: 2)
        let jsonString = String(message[jsonStart...])
        
        guard let data = jsonString.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any],
              jsonArray.count >= 2,
              let eventName = jsonArray[0] as? String,
              let eventData = jsonArray[1] as? [String: Any] else {
            print("⚠️ WebSocket: Failed to parse message: \(message)")
            return
        }
        
        handleEvent(eventName, data: eventData)
    }
    
    /// Handle specific WebSocket events
    private func handleEvent(_ event: String, data: [String: Any]) {
        print("📡 WebSocket Event: \(event)")
        
        DispatchQueue.main.async {
            switch event {
            case "connected":
                print("✅ WebSocket: Server confirmed connection")
                self.connectionStatus = .connected
                
            case "friend_request:received":
                self.handleFriendRequestReceived(data)
                
            case "friend_request:accepted":
                self.handleFriendRequestAccepted(data)
                
            case "friend_request:rejected":
                self.handleFriendRequestRejected(data)
                
            case "challenge:invitation":
                self.handleChallengeInvitation(data)
                
            case "challenge:update":
                self.handleChallengeUpdate(data)
                
            case "achievement:unlocked":
                self.handleAchievementUnlocked(data)
                
            case "leaderboard:update":
                self.handleLeaderboardUpdate(data)
                
            case "friends:online_list":
                self.handleOnlineList(data)
                
            default:
                print("⚠️ WebSocket: Unknown event - \(event)")
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleFriendRequestReceived(_ data: [String: Any]) {
        guard let fromData = data["from"] as? [String: Any],
              let requestId = data["requestId"] as? String,
              let message = data["message"] as? String else {
            return
        }
        
        let notification = FriendRequestNotification(
            requestId: requestId,
            fromUserId: fromData["id"] as? String ?? "",
            fromUsername: fromData["username"] as? String ?? "",
            fromFullName: fromData["fullName"] as? String ?? "",
            fromProfileImage: fromData["profileImageUrl"] as? String,
            message: message,
            timestamp: Date()
        )
        
        self.latestFriendRequest = notification
        
        // Refresh friend requests list
        FriendsService.shared.fetchFriendRequests { _ in }
        
        // Show system notification
        Task { @MainActor in
            NotificationService.shared.showLocalNotification(
                title: "New Friend Request",
                body: message
            )
        }
        
        print("📬 Friend Request: \(message)")
    }
    
    private func handleFriendRequestAccepted(_ data: [String: Any]) {
        guard let message = data["message"] as? String else { return }
        
        // Refresh friends list
        FriendsService.shared.fetchFriends { _ in }
        
        // Show notification
        Task { @MainActor in
            NotificationService.shared.showLocalNotification(
                title: "Friend Request Accepted",
                body: message
            )
        }
        
        print("✅ Friend Request Accepted: \(message)")
    }
    
    private func handleFriendRequestRejected(_ data: [String: Any]) {
        guard let message = data["message"] as? String else { return }
        
        Task { @MainActor in
            NotificationService.shared.showLocalNotification(
                title: "Friend Request Declined",
                body: message
            )
        }
        
        print("❌ Friend Request Rejected: \(message)")
    }
    
    private func handleChallengeInvitation(_ data: [String: Any]) {
        guard let challengeId = data["challengeId"] as? String,
              let details = data["details"] as? [String: Any],
              let from = data["from"] as? [String: Any],
              let message = details["name"] as? String else {
            return
        }
        
        let notification = ChallengeNotification(
            challengeId: challengeId,
            fromUsername: from["username"] as? String ?? "",
            challengeName: message,
            timestamp: Date()
        )
        
        self.latestChallenge = notification
        
        Task { @MainActor in
            NotificationService.shared.showLocalNotification(
                title: "Challenge Invitation",
                body: "\(notification.fromUsername) invited you to: \(message)"
            )
        }
        
        print("🏆 Challenge Invitation: \(message)")
    }
    
    private func handleChallengeUpdate(_ data: [String: Any]) {
        // Refresh challenges list
        print("📊 Challenge Update received")
    }
    
    private func handleAchievementUnlocked(_ data: [String: Any]) {
        guard let name = data["name"] as? String,
              let description = data["description"] as? String else {
            return
        }
        
        let notification = AchievementNotification(
            achievementId: data["achievementId"] as? String ?? UUID().uuidString,
            name: name,
            description: description,
            timestamp: Date()
        )
        
        self.latestAchievement = notification
        
        Task { @MainActor in
            NotificationService.shared.showLocalNotification(
                title: "🏅 Achievement Unlocked!",
                body: "\(name): \(description)"
            )
        }
        
        print("🏅 Achievement: \(name)")
    }
    
    private func handleLeaderboardUpdate(_ data: [String: Any]) {
        print("🏆 Leaderboard updated")
    }
    
    private func handleOnlineList(_ data: [String: Any]) {
        if let userIds = data["users"] as? [String] {
            self.onlineUsers = Set(userIds)
            print("👥 Online users: \(userIds.count)")
        }
    }
    
    // MARK: - Connection Lifecycle
    
    private func handleDisconnection() {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = .disconnected
        }
        
        webSocketTask = nil
        stopPingTimer()
        
        if shouldReconnect {
            reconnect()
        }
    }
    
    @objc private func appDidBecomeActive() {
        if shouldReconnect && !isConnected {
            connect()
        }
    }
    
    @objc private func appWillResignActive() {
        // Keep connection alive in background if possible
    }
    
    // MARK: - Ping/Pong
    
    private func startPingTimer() {
        stopPingTimer()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("⚠️ WebSocket: Ping failed - \(error.localizedDescription)")
            }
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - Send Events
    
    /// Request list of online friends
    func getOnlineFriends() {
        sendEvent("friends:get_online", data: [:])
    }
    
    /// Send typing indicator
    func sendTypingIndicator(to userId: String, isTyping: Bool) {
        sendEvent("friends:typing", data: [
            "recipientId": userId,
            "isTyping": isTyping
        ])
    }
    
    private func sendEvent(_ event: String, data: [String: Any]) {
        guard isConnected else {
            print("⚠️ WebSocket: Not connected, cannot send event")
            return
        }
        
        // Socket.IO event format: 42["event_name",{data}]
        let eventArray: [Any] = [event, data]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: eventArray),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ WebSocket: Failed to serialize event")
            return
        }
        
        let message = "42\(jsonString)"
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        
        webSocketTask?.send(wsMessage) { error in
            if let error = error {
                print("❌ WebSocket: Send error - \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Supporting Types

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case failed(error: String)
    
    var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .failed(let error): return "Failed: \(error)"
        }
    }
}

struct FriendRequestNotification: Identifiable, Equatable {
    let id = UUID()
    let requestId: String
    let fromUserId: String
    let fromUsername: String
    let fromFullName: String
    let fromProfileImage: String?
    let message: String
    let timestamp: Date
    
    static func == (lhs: FriendRequestNotification, rhs: FriendRequestNotification) -> Bool {
        lhs.id == rhs.id
    }
}

struct ChallengeNotification: Identifiable, Equatable {
    let id = UUID()
    let challengeId: String
    let fromUsername: String
    let challengeName: String
    let timestamp: Date
    
    static func == (lhs: ChallengeNotification, rhs: ChallengeNotification) -> Bool {
        lhs.id == rhs.id
    }
}

struct AchievementNotification: Identifiable, Equatable {
    let id = UUID()
    let achievementId: String
    let name: String
    let description: String
    let timestamp: Date
    
    static func == (lhs: AchievementNotification, rhs: AchievementNotification) -> Bool {
        lhs.id == rhs.id
    }
}
