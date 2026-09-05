import SwiftUI

public struct AppTheme {
    public static let feltGreen = Color(red: 13/255.0, green: 61/255.0, blue: 40/255.0)
    public static let feltLight = Color(red: 20/255.0, green: 89/255.0, blue: 58/255.0)
    public static let gold = Color(red: 212/255.0, green: 175/255.0, blue: 55/255.0)
    public static let goldDim = Color(red: 168/255.0, green: 137/255.0, blue: 44/255.0)
    public static let text = Color(red: 242/255.0, green: 234/255.0, blue: 212/255.0)
    public static let textDim = Color(red: 185/255.0, green: 201/255.0, blue: 189/255.0)
    public static let danger = Color(red: 224/255.0, green: 82/255.0, blue: 82/255.0)
    public static let success = Color(red: 63/255.0, green: 191/255.0, blue: 106/255.0)
    public static let cardBg = Color(red: 18/255.0, green: 58/255.0, blue: 41/255.0)
    public static let border = Color(red: 42/255.0, green: 92/255.0, blue: 66/255.0)
    public static let inputBg = Color(red: 15/255.0, green: 46/255.0, blue: 32/255.0)
}

public struct FeltBackgroundModifier: ViewModifier {
    public func body(content: Content) -> some View {
        ZStack {
            AppTheme.feltGreen
                .ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
    }
}

public extension View {
    func feltBackground() -> some View {
        self.modifier(FeltBackgroundModifier())
    }
}

public struct FeltCardView<Content: View>: View {
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(14)
        .background(AppTheme.cardBg)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

public struct PrimaryGoldButton: View {
    let title: String
    let iconName: String?
    let action: () -> Void
    
    public init(title: String, iconName: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.iconName = iconName
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(Color(red: 18/255.0, green: 51/255.0, blue: 31/255.0))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(AppTheme.gold)
            .cornerRadius(12)
            .shadow(color: AppTheme.gold.opacity(0.3), radius: 6, x: 0, y: 3)
        }
    }
}

public struct SecondaryFeltButton: View {
    let title: String
    let iconName: String?
    let action: () -> Void
    
    public init(title: String, iconName: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.iconName = iconName
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(AppTheme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(AppTheme.feltLight)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
    }
}

public struct DangerButton: View {
    let title: String
    let action: () -> Void
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .background(AppTheme.danger)
                .cornerRadius(12)
        }
    }
}
