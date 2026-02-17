import SwiftUI

struct FriendsView: View {
    @StateObject private var friendsService = FriendsService()
    @State private var searchText = ""
    @State private var selectedTab: FriendsTab = .friends
    @State private var showAddFriend = false
    @State private var showFriendDetails = false
    @State private var selectedFriend: Friend?
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum FriendsTab {
        case friends
        case requests
        case search
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Friends Tab", selection: $selectedTab) {
                    Text("Friends (\(friendsService.friends.count))").tag(FriendsTab.friends)
                    Text("Requests (\(friendsService.friendRequests.count))").tag(FriendsTab.requests)
                    Text("Search").tag(FriendsTab.search)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case .friends:
                    FriendsListView(
                        friends: friendsService.friends,
                        selectedFriend: $selectedFriend,
                        showFriendDetails: $showFriendDetails,
                        onRemove: removeFriend
                    )
                    .onAppear {
                        friendsService.fetchFriends()
                    }
                    
                case .requests:
                    FriendRequestsView(
                        requests: friendsService.friendRequests,
                        onAccept: acceptFriendRequest,
                        onReject: rejectFriendRequest
                    )
                    .onAppear {
                        friendsService.fetchFriendRequests()
                    }
                    
                case .search:
                    SearchFriendsView(
                        searchText: $searchText,
                        searchResults: friendsService.searchResults,
                        isLoading: friendsService.isLoading,
                        onSearch: searchUsers,
                        onAddFriend: sendFriendRequest
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Friends & Social")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddFriend = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(item: $selectedFriend) { friend in
                FriendDetailsView(friend: friend)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            friendsService.fetchFriends()
        }
    }
    
    private func sendFriendRequest(userId: String) {
        friendsService.sendFriendRequest(to: userId) { result in
            switch result {
            case .success(let message):
                DispatchQueue.main.async {
                    errorMessage = message
                    showError = true
                    friendsService.searchResults.removeAll { $0.id == userId }
                    searchText = ""
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    errorMessage = "Failed to send request: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func acceptFriendRequest(friendId: String) {
        friendsService.acceptFriendRequest(from: friendId) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    friendsService.fetchFriendRequests()
                    friendsService.fetchFriends()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    errorMessage = "Failed to accept request: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func rejectFriendRequest(friendId: String) {
        // TODO: Implement reject endpoint
        DispatchQueue.main.async {
            errorMessage = "Reject functionality coming soon"
            showError = true
        }
    }
    
    private func removeFriend(friendId: String) {
        friendsService.removeFriend(friendId: friendId) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    friendsService.fetchFriends()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    errorMessage = "Failed to remove friend: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func searchUsers(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            friendsService.searchResults = []
            return
        }
        
        friendsService.searchUsers(query: query) { result in
            switch result {
            case .success:
                break // Results already updated in service
            case .failure(let error):
                DispatchQueue.main.async {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Friends List View
struct FriendsListView: View {
    let friends: [Friend]
    @Binding var selectedFriend: Friend?
    @Binding var showFriendDetails: Bool
    let onRemove: (String) -> Void
    
    var body: some View {
        if friends.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "person.2.slash")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("No Friends Yet")
                    .font(.headline)
                
                Text("Add friends to compete and share your fitness journey!")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding()
        } else {
            List {
                ForEach(friends, id: \.id) { friend in
                    NavigationLink(destination: FriendDetailsView(friend: friend)) {
                        FriendRowView(friend: friend)
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        onRemove(friends[index].id)
                    }
                }
            }
        }
    }
}

// MARK: - Friend Row View
struct FriendRowView: View {
    let friend: Friend
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(friend.displayName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            // Friend Info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.headline)
                
                Text(friend.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status
            HStack(spacing: 8) {
                if friend.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Friend Requests View
struct FriendRequestsView: View {
    let requests: [FriendRequest]
    let onAccept: (String) -> Void
    let onReject: (String) -> Void
    
    var body: some View {
        if requests.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "envelope.open")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("No Pending Requests")
                    .font(.headline)
                
                Text("You'll see friend requests here")
                    .foregroundColor(.secondary)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding()
        } else {
            List {
                ForEach(requests, id: \.id) { request in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(String(request.fromUser.displayName.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(request.fromUser.displayName)
                                    .font(.headline)
                                
                                Text(request.fromUser.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: { onReject(request.fromUserId) }) {
                                Text("Decline")
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                            
                            Button(action: { onAccept(request.fromUserId) }) {
                                Text("Accept")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
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
            SearchBar(text: $searchText, placeholder: "Search users...", onSearch: onSearch)
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
                    
                    Text(searchText.isEmpty ? "Search for users" : "No results found")
                        .font(.headline)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .padding()
            } else {
                List {
                    ForEach(searchResults, id: \.id) { result in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(String(result.displayName.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.displayName)
                                    .font(.headline)
                                
                                Text(result.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if result.isFriend {
                                Text("Friend")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Button(action: { onAddFriend(result.id) }) {
                                    Image(systemName: "person.badge.plus")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
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
                        Text(String(friend.displayName.prefix(1)))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Text(friend.displayName)
                    .font(.headline)
                
                Text(friend.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if friend.isOnline {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Stats
            if let stats = friendStats {
                VStack(spacing: 12) {
                    StatRow(label: "Workouts", value: "\(stats.totalWorkouts)")
                    StatRow(label: "Meals Logged", value: "\(stats.totalMealsLogged)")
                    StatRow(label: "Streak", value: "\(stats.currentStreak) days")
                    StatRow(label: "Joined", value: formatDate(stats.joinedDate))
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct StatRow: View {
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

#Preview {
    FriendsView()
}
