import SwiftUI

public struct AppTheme {
    // Canvas & Surface Colors (Light white base with blue tints)
    public static let feltGreen = Color(red: 246/255.0, green: 248/255.0, blue: 252/255.0) // Soft white canvas (#F6F8FC)
    public static let feltLight = Color(red: 238/255.0, green: 242/255.0, blue: 255/255.0) // Light royal tint surface (#EEF2FF)
    public static let cardBg = Color(red: 255/255.0, green: 255/255.0, blue: 255/255.0)    // Pure White cards (#FFFFFF)
    public static let inputBg = Color(red: 241/255.0, green: 245/255.0, blue: 249/255.0)   // Light slate input (#F1F5F9)
    public static let border = Color(red: 226/255.0, green: 232/255.0, blue: 240/255.0)    // Crisp light border (#E2E8F0)
    
    // Primary & Secondary Accents (Vibrant Royal & Indigo Blue, Mango Yellow)
    public static let gold = Color(red: 37/255.0, green: 99/255.0, blue: 235/255.0)       // Vibrant Royal Blue (#2563EB)
    public static let goldDim = Color(red: 29/255.0, green: 78/255.0, blue: 216/255.0)    // Deep Cobalt Blue (#1D4ED8)
    public static let mangoYellow = Color(red: 245/255.0, green: 158/255.0, blue: 11/255.0) // Warm Mango Yellow (#F59E0B)
    
    // Typography Colors (Crisp high-contrast day & night)
    public static let text = Color(red: 15/255.0, green: 23/255.0, blue: 42/255.0)       // Deep Slate / Navy (#0F172A)
    public static let textDim = Color(red: 71/255.0, green: 85/255.0, blue: 105/255.0)   // Slate Gray (#475569)
    
    // Status Indicators
    public static let danger = Color(red: 220/255.0, green: 38/255.0, blue: 38/255.0)    // Vibrant Red (#DC2626)
    public static let success = Color(red: 16/255.0, green: 185/255.0, blue: 129/255.0)  // Emerald Green (#10B981)
}

public struct FeltBackgroundModifier: ViewModifier {
    public func body(content: Content) -> some View {
        ZStack {
            AppTheme.feltGreen
                .ignoresSafeArea()
            content
        }
        .preferredColorScheme(.light)
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
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(AppTheme.gold)
            .cornerRadius(12)
            .shadow(color: AppTheme.gold.opacity(0.25), radius: 6, x: 0, y: 3)
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
            .foregroundColor(AppTheme.gold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(AppTheme.feltLight)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.gold.opacity(0.3), lineWidth: 1)
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

