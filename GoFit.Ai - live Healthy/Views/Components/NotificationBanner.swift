//
//  NotificationBanner.swift
//  GoFit.Ai - live Healthy
//
//  Real-time notification banner for WebSocket events
//

import SwiftUI

struct NotificationBanner: View {
    let title: String
    let message: String
    let icon: String
    let action: (() -> Void)?
    
    @State private var offset: CGFloat = -200
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, message: String, icon: String = "bell.fill", action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.blue.gradient)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Action button
                if action != nil {
                    Button(action: {
                        action?()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
            )
            .padding(.horizontal, 16)
            .padding(.top, 50) // Below status bar
        }
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                offset = 0
            }
            
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    offset = -200
                }
            }
        }
    }
}

// MARK: - Banner Manager

class NotificationBannerManager: ObservableObject {
    static let shared = NotificationBannerManager()
    
    @Published var currentBanner: BannerData?
    
    private init() {}
    
    func show(title: String, message: String, icon: String = "bell.fill", action: (() -> Void)? = nil) {
        currentBanner = BannerData(title: title, message: message, icon: icon, action: action)
        
        // Auto-hide after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if self.currentBanner?.id == self.currentBanner?.id {
                self.currentBanner = nil
            }
        }
    }
    
    func hide() {
        currentBanner = nil
    }
    
    struct BannerData: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let icon: String
        let action: (() -> Void)?
    }
}

// MARK: - View Modifier

struct NotificationBannerModifier: ViewModifier {
    @ObservedObject var bannerManager = NotificationBannerManager.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let banner = bannerManager.currentBanner {
                NotificationBanner(
                    title: banner.title,
                    message: banner.message,
                    icon: banner.icon,
                    action: banner.action
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
    }
}

extension View {
    func notificationBanner() -> some View {
        modifier(NotificationBannerModifier())
    }
}

// MARK: - Preview

struct NotificationBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            
            NotificationBanner(
                title: "New Friend Request",
                message: "John Doe wants to connect with you",
                icon: "person.badge.plus.fill"
            )
            
            Spacer()
        }
        .background(Color.gray.opacity(0.1))
    }
}
