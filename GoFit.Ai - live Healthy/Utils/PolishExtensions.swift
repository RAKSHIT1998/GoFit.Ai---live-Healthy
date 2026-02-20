import SwiftUI

// MARK: - Button Style Extensions
struct PolishedButtonStyle: ButtonStyle {
    let isDestructive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .onTapGesture {
                HapticManager.shared.lightTap()
            }
    }
}

struct SmoothButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension Button {
    func polishedStyle() -> some View {
        self.buttonStyle(PolishedButtonStyle(isDestructive: false))
    }
}

// MARK: - View Transitions & Animations
extension View {
    func smoothFadeIn(delay: Double = 0) -> some View {
        self
            .opacity(0)
            .animation(.easeIn(duration: 0.3).delay(delay), value: UUID())
            .onAppear {
                withAnimation(.easeIn(duration: 0.3).delay(delay)) {
                    // No-op for animation trigger
                }
            }
    }
    
    func smoothScale(delay: Double = 0) -> some View {
        self
            .scaleEffect(0.95)
            .opacity(0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay)) {
                    // Animation triggered
                }
            }
    }
    
    func slideInFromBottom() -> some View {
        self
            .offset(y: 50)
            .opacity(0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    // Animation triggered
                }
            }
    }
    
    func slideInFromLeft() -> some View {
        self
            .offset(x: -50)
            .opacity(0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    // Animation triggered
                }
            }
    }
}

// MARK: - Loading Skeleton
struct SkeletonLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 20)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 16)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 16)
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Smooth Progress Indicator
struct SmoothProgressView: View {
    let progress: Double
    let height: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.blue.opacity(0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Smooth Transitions
struct SmoothDismissal: ViewModifier {
    @Environment(\.dismiss) var dismiss
    
    func body(content: Content) -> some View {
        content
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
    }
}

extension View {
    func smoothDismissal() -> some View {
        modifier(SmoothDismissal())
    }
}

// MARK: - Smooth List Modifier
struct SmoothListStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Design.Colors.background)
    }
}

extension View {
    func smoothListStyle() -> some View {
        modifier(SmoothListStyle())
    }
}

// MARK: - Card Animation
struct SmoothCardModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(
                color: isHovered ? Color.black.opacity(0.2) : Color.black.opacity(0.1),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func smoothCardStyle() -> some View {
        modifier(SmoothCardModifier())
    }
}

// MARK: - Delayed Animation
struct DelayedAppear: ViewModifier {
    let delay: Double
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func delayedAppear(_ delay: Double = 0.1) -> some View {
        modifier(DelayedAppear(delay: delay))
    }
}

// MARK: - Smooth Keyboard Dismissal
extension View {
    func dismissKeyboardOnSwipe() -> some View {
        self.gesture(
            DragGesture().onChanged { _ in
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        )
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .opacity(isLoading ? 0.5 : 1.0)
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

extension View {
    func loadingOverlay(_ isLoading: Bool) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading))
    }
}

// MARK: - Toast-like Notifications
struct ToastModifier: ViewModifier {
    @State private var showToast = false
    let message: String
    let isError: Bool
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            
            if showToast {
                VStack {
                    HStack {
                        Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(isError ? .red : .green)
                        Text(message)
                            .font(.caption)
                        Spacer()
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding()
                }
                .transition(.move(edge: .bottom))
            }
        }
    }
}

// MARK: - Smooth Refresh Control
struct SmoothRefreshControl: ViewModifier {
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                await action()
            }
    }
}

extension View {
    func smoothRefresh(_ action: @escaping () async -> Void) -> some View {
        modifier(SmoothRefreshControl(action: action))
    }
}

// MARK: - Tab Bar Polish
struct SmoothTabSelection: ViewModifier {
    @Binding var selection: Int
    
    func body(content: Content) -> some View {
        content
            .onChange(of: selection) { _ in
                HapticManager.shared.lightTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    // Animation
                }
            }
    }
}
