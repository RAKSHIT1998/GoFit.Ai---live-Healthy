import SwiftUI

struct FriendsView: View {
    @StateObject private var friendsService = FriendsService()
    @State private var searchText = ""
    @State private var selectedTab: FriendsTab = .friends
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum FriendsTab {
        case friends
        case activity
        case requests
        case search
    }
    
    var body: some View {
        ZStack {
            Design.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with stats
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Friends & Social")
                                .font(Design.Typography.headline)
                                .foregroundColor(.primary)
                            Text("\(friendsService.friends.count) friends connected")
                                .font(Design.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .center, spacing: 4) {
                                Text("\(friendsService.friendRequests.count)")
                                    .font(.headline)
                                    .foregroundColor(Design.Colors.primary)
                                Text("Requests")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Design.Colors.cardBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, Design.Spacing.md)
                    .padding(.vertical, Design.Spacing.md)
                    
                    // Tab Picker with modern style
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([FriendsTab.friends, .activity, .requests, .search], id: \.self) { tab in
                                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: tabIcon(tab))
                                        Text(tabName(tab))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(selectedTab == tab ? .white : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedTab == tab ? Design.Colors.primary : Design.Colors.cardBackground)
                                    .cornerRadius(10)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, Design.Spacing.md)
                    }
                }
                .background(Design.Colors.background)
                
                Divider()
                    .padding(.vertical, 8)
            
                // Content based on selected tab
                ScrollView {
                    VStack(spacing: 0) {
                        switch selectedTab {
                        case .friends:
                            FriendsListView(friends: friendsService.friends)
                                .onAppear {
                                    friendsService.fetchFriends { _ in }
                                }
                            
                        case .activity:
                            ActivityFeedView()
                            
                        case .requests:
                            FriendRequestsView(
                                requests: friendsService.friendRequests,
                                onAccept: { friendId in
                                    friendsService.acceptFriendRequest(from: friendId) { _ in
                                        friendsService.fetchFriendRequests { _ in }
                                        friendsService.fetchFriends { _ in }
                                    }
                                }
                            )
                            .onAppear {
                                friendsService.fetchFriendRequests { _ in }
                            }
                            
                        case .search:
                            SearchFriendsView(
                                searchText: $searchText,
                                searchResults: friendsService.searchResults,
                                isLoading: friendsService.isLoading,
                                onSearch: { query in
                                    guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
                                        friendsService.searchResults = []
                                        return
                                    }
                                    friendsService.searchUsers(query: query) { _ in }
                                },
                                onAddFriend: { userId in
                                    friendsService.sendFriendRequest(to: userId) { result in
                                        DispatchQueue.main.async {
                                            if case .success(let message) = result {
                                                errorMessage = message
                                                showError = true
                                                friendsService.searchResults.removeAll { $0.id == userId }
                                                searchText = ""
                                            } else {
                                                errorMessage = "Failed to send request"
                                                showError = true
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, Design.Spacing.md)
                }
                
                Spacer()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            friendsService.fetchFriends { _ in }
        }
    }
    
    private func tabName(_ tab: FriendsTab) -> String {
        switch tab {
        case .friends: return "Friends"
        case .activity: return "Activity"
        case .requests: return "Requests"
        case .search: return "Search"
        }
    }
    
    private func tabIcon(_ tab: FriendsTab) -> String {
        switch tab {
        case .friends: return "person.2"
        case .activity: return "bolt.fill"
        case .requests: return "envelope"
        case .search: return "magnifyingglass"
        }
    }
}

// MARK: - Friends List View (Enhanced)
struct FriendsListView: View {
    let friends: [Friend]
    
    var body: some View {
        if friends.isEmpty {
            VStack(spacing: 24) {
                Image(systemName: "person.2.slash")
                    .font(.system(size: 64))
                    .foregroundColor(Design.Colors.primary.opacity(0.3))
                
                VStack(spacing: 8) {
                    Text("No Friends Yet")
                        .font(Design.Typography.headline)
                        .foregroundColor(.primary)
                    
                    Text("Add friends to share your fitness journey and compete together!")
                        .font(Design.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, Design.Spacing.lg)
        } else {
            VStack(spacing: Design.Spacing.md) {
                ForEach(friends, id: \.id) { friend in
                    NavigationLink(destination: FriendDetailsView(friend: friend)) {
                        FriendCardView(friend: friend)
                    }
                }
            }
            .padding(.horizontal, Design.Spacing.md)
        }
    }
}

// MARK: - Friend Card View
struct FriendCardView: View {
    let friend: Friend
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Avatar with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Design.Colors.primary.opacity(0.7),
                                Design.Colors.primary.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(friend.username.prefix(1)).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(friend.fullName ?? friend.username)
                        .font(Design.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("@\(friend.username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Label("5 workouts", systemImage: "figure.strengthtraining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Label("8 day streak", systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(Design.Colors.primary)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Quick action buttons
            HStack(spacing: 12) {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                        Text("Cheer")
                    }
                    .font(.caption)
                    .foregroundColor(Design.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Design.Colors.primary.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                        Text("Message")
                    }
                    .font(.caption)
                    .foregroundColor(Design.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Design.Colors.primary.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(Design.Spacing.md)
        .background(Design.Colors.cardBackground)
        .cornerRadius(Design.Radius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Friend Requests View (Enhanced)
struct FriendRequestsView: View {
    let requests: [FriendRequest]
    let onAccept: (String) -> Void
    
    var body: some View {
        if requests.isEmpty {
            VStack(spacing: 24) {
                Image(systemName: "envelope.open")
                    .font(.system(size: 64))
                    .foregroundColor(Design.Colors.primary.opacity(0.3))
                
                VStack(spacing: 8) {
                    Text("All Caught Up!")
                        .font(Design.Typography.headline)
                        .foregroundColor(.primary)
                    
                    Text("You don't have any pending friend requests")
                        .font(Design.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, Design.Spacing.lg)
        } else {
            VStack(spacing: Design.Spacing.md) {
                ForEach(requests, id: \.id) { request in
                    FriendRequestCardView(request: request, onAccept: { onAccept(request.requesterId) })
                }
            }
            .padding(.horizontal, Design.Spacing.md)
        }
    }
}

// MARK: - Friend Request Card View
struct FriendRequestCardView: View {
    let request: FriendRequest
    let onAccept: () -> Void
    @State private var showDeclineConfirm = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.orange.opacity(0.7),
                                Color.yellow.opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(request.requesterUsername.prefix(1)).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(request.requesterUsername)
                        .font(Design.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(request.requesterEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                            .font(.caption2)
                            .foregroundColor(Design.Colors.primary)
                        Text("Wants to connect")
                            .font(.caption2)
                            .foregroundColor(Design.Colors.primary)
                    }
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: { showDeclineConfirm = true }) {
                    Text("Decline")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: onAccept) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Accept")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Design.Colors.primary)
                    .cornerRadius(8)
                }
            }
        }
        .padding(Design.Spacing.md)
        .background(Design.Colors.cardBackground)
        .cornerRadius(Design.Radius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .confirmationDialog("Decline Request", isPresented: $showDeclineConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Decline", role: .destructive) { }
        } message: {
            Text("Are you sure you want to decline this friend request?")
        }
    }
}

// MARK: - Search Friends View
struct SearchFriendsView: View {
    @Binding var searchText: String
    let searchResults: [SearchResult]
    let isLoading: Bool
    let onSearch: (String) -> Void
    let onAddFriend: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                SearchBar(text: $searchText, placeholder: "Search by email, name, or username", onSearch: onSearch)
                
                // Help text
                if searchText.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Type an email, username, or name to find and add friends")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
            }
            .padding()
            
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Searching...")
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            } else if searchResults.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text(searchText.isEmpty ? "Find Friends" : "No results found")
                            .font(.headline)
                        
                        if !searchText.isEmpty {
                            Text("Try searching by email or full name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .padding()
            } else {
                List {
                    ForEach(searchResults, id: \.id) { result in
                        HStack(spacing: 12) {
                            // Avatar
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(String(result.username.prefix(1)).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 6) {
                                // Name
                                HStack(spacing: 6) {
                                    Text(result.fullName ?? result.username)
                                        .font(.headline)
                                    
                                    // Badge showing match type
                                    HStack(spacing: 2) {
                                        Image(systemName: getMatchTypeIcon(for: result))
                                            .font(.caption2)
                                        Text(getMatchType(for: result))
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                                }
                                
                                // Contact info
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("@\(result.username)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Action button
                            if result.friendStatus == "friends" {
                                Label("Friend", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else if result.friendStatus == "request_sent" {
                                Label("Sent", systemImage: "clock.badge")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Button(action: { onAddFriend(result.id) }) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                        .padding(8)
                                        .contentShape(Rectangle())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMatchType(for result: SearchResult) -> String {
        // Determine what field was matched in the search
        // This would ideally come from the backend, but we can infer from the search text
        return "match"
    }
    
    private func getMatchTypeIcon(for result: SearchResult) -> String {
        // Return appropriate icon based on match type
        return "checkmark.circle"
    }
}

// MARK: - Friend Details View
struct FriendDetailsView: View {
    let friend: Friend
    @StateObject private var friendsService = FriendsService()
    @State private var friendStats: FriendStats?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Header
            VStack(spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(String(friend.username.prefix(1)))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Text(friend.fullName ?? friend.username)
                    .font(.headline)
                
                Text(friend.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Stats
            if let stats = friendStats {
                VStack(spacing: 12) {
                    StatRowItem(label: "Workouts", value: "\(stats.totalWorkoutsCompleted)")
                    StatRowItem(label: "Meals Logged", value: "\(stats.totalMealsLogged)")
                    StatRowItem(label: "Calories Burned", value: "\(stats.totalCaloriesBurned)")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else if isLoading {
                HStack {
                    ProgressView()
                    Text("Loading stats...")
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Friend Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            friendsService.getFriendStats(friendId: friend.id) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    if case .success(let stats) = result {
                        friendStats = stats
                    }
                }
            }
        }
    }
}

struct StatRowItem: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.headline)
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearch: (String) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text, onEditingChanged: { _ in
                onSearch(text)
            })
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Activity Feed View (NEW)
struct ActivityFeedView: View {
    @State private var activities: [ActivityItem] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading your feed...")
                        .font(Design.Typography.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .onAppear {
                    loadActivities()
                }
            } else if activities.isEmpty {
                VStack(spacing: 24) {
                    Image(systemName: "bolt.slash")
                        .font(.system(size: 64))
                        .foregroundColor(Design.Colors.primary.opacity(0.3))
                    
                    VStack(spacing: 8) {
                        Text("Your Feed is Empty")
                            .font(Design.Typography.headline)
                            .foregroundColor(.primary)
                        
                        Text("When your friends log workouts and meals, they'll show up here!")
                            .font(Design.Typography.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, Design.Spacing.lg)
            } else {
                VStack(spacing: Design.Spacing.md) {
                    ForEach(activities) { activity in
                        ActivityCardView(activity: activity)
                    }
                }
                .padding(.horizontal, Design.Spacing.md)
            }
        }
        .onAppear {
            if isLoading {
                loadActivities()
            }
        }
    }
    
    private func loadActivities() {
        // Mock data for activity feed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            activities = [
                ActivityItem(
                    id: "1",
                    userName: "Sarah Johnson",
                    userInitial: "S",
                    activityType: "workout",
                    title: "Morning HIIT Session",
                    description: "Completed 45-minute high intensity workout",
                    details: "350 calories burned • Upper body focused",
                    timestamp: "2 minutes ago",
                    reactions: ["🔥", "💪", "🔥"]
                ),
                ActivityItem(
                    id: "2",
                    userName: "Mike Chen",
                    userInitial: "M",
                    activityType: "meal",
                    title: "Protein Power Bowl",
                    description: "Logged healthy breakfast",
                    details: "520 calories • 45g protein • 35g carbs",
                    timestamp: "15 minutes ago",
                    reactions: ["❤️", "😋"]
                ),
                ActivityItem(
                    id: "3",
                    userName: "Emma Davis",
                    userInitial: "E",
                    activityType: "achievement",
                    title: "7-Day Streak! 🎉",
                    description: "Maintained 7 consecutive days of workouts",
                    details: "Keep it up! You're crushing your goals!",
                    timestamp: "1 hour ago",
                    reactions: ["🔥", "💪", "🎉", "❤️"]
                )
            ]
            isLoading = false
        }
    }
}

// MARK: - Activity Card View
struct ActivityCardView: View {
    let activity: ActivityItem
    @State private var reactionSelection: String?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Design.Colors.primary.opacity(0.7),
                                Design.Colors.primary.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(activity.userInitial)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.userName)
                        .font(Design.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(activity.timestamp)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: activity.activityTypeIcon)
                    .font(.headline)
                    .foregroundColor(activity.activityTypeColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.title)
                    .font(Design.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(activity.details)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Reactions and action buttons
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(Array(activity.reactions.enumerated()), id: \.offset) { index, reaction in
                        Text(reaction)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Menu {
                    ForEach(Array(["🔥", "❤️", "👍", "🎉", "💪"].enumerated()), id: \.offset) { index, emoji in
                        Button(emoji) {
                            reactionSelection = emoji
                        }
                    }
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.caption)
                        .foregroundColor(Design.Colors.primary)
                }
            }
        }
        .padding(Design.Spacing.md)
        .background(Design.Colors.cardBackground)
        .cornerRadius(Design.Radius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Activity Item Model
struct ActivityItem: Identifiable {
    let id: String
    let userName: String
    let userInitial: String
    let activityType: String // "workout", "meal", "achievement"
    let title: String
    let description: String
    let details: String
    let timestamp: String
    let reactions: [String]
    
    var activityTypeIcon: String {
        switch activityType {
        case "workout": return "figure.run.circle.fill"
        case "meal": return "fork.knife.circle.fill"
        case "achievement": return "star.circle.fill"
        default: return "bolt.circle.fill"
        }
    }
    
    var activityTypeColor: Color {
        switch activityType {
        case "workout": return .blue
        case "meal": return .green
        case "achievement": return .yellow
        default: return Design.Colors.primary
        }
    }
}

#Preview {
    FriendsView()
}
