
import SwiftUI

struct AppTheme: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .tint(colorPrimario)
            .background(colorFondo)
    }

    private var colorPrimario: Color {
        colorScheme == .dark
            ? AppColors.primaryDark
            : AppColors.primaryLight
    }

    private var colorFondo: Color {
        colorScheme == .dark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight
    }
}

extension View {
    func aplicarTemaStudyHub() -> some View {
        modifier(AppTheme())
    }
}
