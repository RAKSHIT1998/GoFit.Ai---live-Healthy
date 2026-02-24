import SwiftUI

struct ConversationsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var messagesService = MessagesService.shared
    @ObservedObject private var webSocketService = WebSocketService.shared

    @State private var conversations: [ConversationSummary] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 12) {
            if isLoading {
                ProgressView("Loading conversations...")
                    .padding(.top, 20)
            } else if conversations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundColor(Design.Colors.primary.opacity(0.3))
                    Text("No conversations")
                        .font(Design.Typography.headline)
                    Text("Start a chat with a friend to see it here.")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(conversations) { convo in
                        NavigationLink {
                            ChatView(friend: Friend(id: convo.friendId, username: convo.friendName, email: "", fullName: convo.friendName, profileImageUrl: convo.friendImage), currentUserId: auth.userId ?? "")
                        } label: {
                            conversationRow(convo)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, Design.Spacing.md)
        .onAppear {
            loadConversations()
        }
        .onChange(of: webSocketService.latestMessage) { _, _ in
            loadConversations()
        }
    }

    private func loadConversations() {
        messagesService.fetchConversations { result in
            DispatchQueue.main.async {
                isLoading = false
                if case .success(let items) = result {
                    conversations = items
                }
            }
        }
    }

    private func conversationRow(_ convo: ConversationSummary) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Design.Colors.primary.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(convo.friendName.prefix(1)).uppercased())
                        .foregroundColor(Design.Colors.primary)
                        .font(.headline)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(convo.friendName)
                    .font(Design.Typography.subheadline)
                if let last = convo.lastMessage {
                    Text(last)
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if convo.unreadCount > 0 {
                Text("\(convo.unreadCount)")
                    .font(.caption)
                    .padding(6)
                    .background(Design.Colors.primary)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(Design.Colors.cardBackground)
        .cornerRadius(12)
    }
}
