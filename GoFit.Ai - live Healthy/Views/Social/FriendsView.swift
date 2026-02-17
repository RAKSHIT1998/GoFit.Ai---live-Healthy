import SwiftUI

struct FriendsView: View {
    @StateObject private var friendsService = FriendsService()
    @State private var searchText = ""
    @State private var selectedTab: FriendsTab = .friends
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
                    FriendsListView(friends: friendsService.friends)
                        .onAppear {
                            friendsService.fetchFriends { _ in }
                        }
                    
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
                
                Spacer()
            }
            .navigationTitle("Friends & Social")
            .navigationBarTitleDisplayMode(.inline)
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
}

// MARK: - Friends List View
struct FriendsListView: View {
    let friends: [Friend]
    
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
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(String(friend.username.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(friend.fullName ?? friend.username)
                                    .font(.headline)
                                
                                Text(friend.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// MARK: - Friend Requests View
struct FriendRequestsView: View {
    let requests: [FriendRequest]
    let onAccept: (String) -> Void
    
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
                                    Text(String(request.requesterUsername.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(request.requesterUsername)
                                    .font(.headline)
                                
                                Text(request.requesterEmail)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: { }) {
                                Text("Decline")
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                            
                            Button(action: { onAccept(request.requesterId) }) {
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
                                    Text(String(result.username.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.fullName ?? result.username)
                                    .font(.headline)
                                
                                Text(result.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if result.friendStatus == "friends" {
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

#Preview {
    FriendsView()
}
