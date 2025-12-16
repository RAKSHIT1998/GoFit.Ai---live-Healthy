import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var purchases: PurchaseManager
    @State private var selectedTab = 0
    @State private var previousTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeDashboardView()
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            MealHistoryView()
                .tabItem {
                    Label("Meals", systemImage: selectedTab == 1 ? "fork.knife.circle.fill" : "fork.knife.circle")
                }
                .tag(1)
            
            WorkoutSuggestionsView()
                .tabItem {
                    Label("Workouts", systemImage: selectedTab == 2 ? "figure.walk.circle.fill" : "figure.walk.circle")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 3 ? "person.circle.fill" : "person.circle")
                }
                .tag(3)
        }
        .accentColor(Design.Colors.primary)
        .onChange(of: selectedTab) { oldValue, newValue in
            withAnimation(Design.Animation.springFast) {
                previousTab = newValue
            }
        }
    }
}
