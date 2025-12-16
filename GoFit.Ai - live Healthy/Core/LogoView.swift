import SwiftUI

// MARK: - GoFit.Ai Logo Component
struct LogoView: View {
    var size: LogoSize = .large
    var showText: Bool = true
    var color: Color = Color(red: 0.1, green: 0.2, blue: 0.4) // Dark blue
    
    enum LogoSize {
        case small
        case medium
        case large
        case xlarge
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 60
            case .large: return 80
            case .xlarge: return 120
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            case .xlarge: return 42
            }
        }
    }
    
    var body: some View {
        VStack(spacing: size == .small ? 4 : 12) {
            // Running Person Icon
            ZStack {
                // Outer circle background (optional, for contrast)
                if size == .large || size == .xlarge {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: size.iconSize + 20, height: size.iconSize + 20)
                }
                
                // Running person icon
                RunningPersonIcon(size: size.iconSize, color: color)
            }
            
            // Logo Text
            if showText {
                Text("GoFit.Ai")
                    .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
        }
    }
}

// MARK: - Running Person Icon
struct RunningPersonIcon: View {
    let size: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            // Head
            Circle()
                .stroke(color, lineWidth: size * 0.08)
                .frame(width: size * 0.25, height: size * 0.25)
                .offset(y: -size * 0.35)
            
            // Body (torso)
            RoundedRectangle(cornerRadius: size * 0.05)
                .stroke(color, lineWidth: size * 0.08)
                .frame(width: size * 0.2, height: size * 0.3)
                .offset(y: -size * 0.05)
            
            // Left arm (raised)
            Path { path in
                path.move(to: CGPoint(x: -size * 0.1, y: -size * 0.15))
                path.addLine(to: CGPoint(x: -size * 0.25, y: -size * 0.35))
            }
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
            
            // Right arm (back)
            Path { path in
                path.move(to: CGPoint(x: size * 0.1, y: -size * 0.15))
                path.addLine(to: CGPoint(x: size * 0.25, y: -size * 0.25))
            }
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
            
            // Left leg (forward)
            Path { path in
                path.move(to: CGPoint(x: -size * 0.05, y: size * 0.1))
                path.addLine(to: CGPoint(x: -size * 0.2, y: size * 0.35))
            }
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
            
            // Right leg (back)
            Path { path in
                path.move(to: CGPoint(x: size * 0.05, y: size * 0.1))
                path.addLine(to: CGPoint(x: size * 0.15, y: size * 0.3))
            }
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Logo View for White Backgrounds
struct LogoViewWhite: View {
    var size: LogoView.LogoSize = .large
    var showText: Bool = true
    
    var body: some View {
        LogoView(size: size, showText: showText, color: Color(red: 0.1, green: 0.2, blue: 0.4))
    }
}

// MARK: - Logo View for Gradient/Colored Backgrounds
struct LogoViewLight: View {
    var size: LogoView.LogoSize = .large
    var showText: Bool = true
    
    var body: some View {
        LogoView(size: size, showText: showText, color: .white)
    }
}

// MARK: - Preview
struct LogoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            LogoViewWhite(size: .large)
            LogoViewLight(size: .large)
            LogoView(size: .medium, color: Design.Colors.primary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

