import SwiftUI


enum DesignSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum DesignRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 14
    static let xl: CGFloat = 20
}

enum DesignFont {
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 13, weight: .regular, design: .default)
    static let callout = Font.system(size: 12, weight: .regular, design: .default)
    static let caption = Font.system(size: 11, weight: .regular, design: .default)
    static let mono = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let tag = Font.system(size: 9, weight: .bold, design: .rounded)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSpacing.lg)
            .background(Color.dsSurfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: DesignRadius.lg)
                    .strokeBorder(Color.dsBorder, lineWidth: 1)
            }
    }
}

struct TagStyle: ViewModifier {
    let color: Color
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(DesignFont.tag)
            .foregroundStyle(color)
            .padding(.horizontal, DesignSpacing.sm)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func tagStyle(color: Color, background: Color) -> some View {
        modifier(TagStyle(color: color, backgroundColor: background))
    }
}
