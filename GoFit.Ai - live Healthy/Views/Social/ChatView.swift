import SwiftUI

struct ChatView: View {
    let friend: Friend
    let currentUserId: String

    @StateObject private var messagesService = MessagesService.shared
    @ObservedObject private var cache = UserDataCache.shared

    @State private var messages: [MessageItem] = []
    @State private var messageText = ""
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                Button {
                    sendTodaySummary()
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Design.Colors.primary)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Share today's summary")

                TextField("Message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : Design.Colors.primary)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding(12)
        }
        .navigationTitle(friend.fullName ?? friend.username)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
        }
    }

    private func messageBubble(_ msg: MessageItem) -> some View {
        let isMine = msg.senderId == currentUserId
        return HStack {
            if isMine { Spacer() }
            VStack(alignment: .leading, spacing: 4) {
                Text(msg.message)
                    .font(Design.Typography.body)
                    .foregroundColor(isMine ? .white : .primary)
                Text(formatDate(msg.createdAt))
                    .font(.caption2)
                    .foregroundColor(isMine ? .white.opacity(0.7) : .secondary)
            }
            .padding(10)
            .background(isMine ? Design.Colors.primary : Color(.systemGray5))
            .cornerRadius(12)
            if !isMine { Spacer() }
        }
        .padding(.horizontal, 12)
    }

    private func loadMessages() {
        messagesService.fetchConversation(friendId: friend.id) { result in
            if case .success(let msgs) = result {
                self.messages = msgs
            }
        }
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSending = true
        messagesService.sendMessage(friendId: friend.id, message: trimmed) { result in
            DispatchQueue.main.async {
                isSending = false
                if case .success(let msg) = result {
                    messages.append(msg)
                    messageText = ""
                }
            }
        }
    }

    private func sendTodaySummary() {
        let stats = cache.calculateTodaysStats()
        let summary = "Today: \(Int(stats.totalCaloriesConsumed)) kcal, P \(Int(stats.protein))g, C \(Int(stats.carbs))g, F \(Int(stats.fat))g, Workouts \(stats.workoutsCompleted), Meals \(stats.mealsLogged), Water \(String(format: \"%.1f\", stats.waterIntake))L, Steps \(stats.steps)"
        isSending = true
        messagesService.sendMessage(friendId: friend.id, message: summary) { result in
            DispatchQueue.main.async {
                isSending = false
                if case .success(let msg) = result {
                    messages.append(msg)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
