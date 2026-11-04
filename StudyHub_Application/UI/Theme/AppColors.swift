
import SwiftUI

enum AppColors {
    static let primaryLight = Color(hex: 0x435E91)
    static let onPrimaryLight = Color(hex: 0xFFFFFF)
    static let primaryContainerLight = Color(hex: 0xD8E2FF)
    static let onPrimaryContainerLight = Color(hex: 0x2B4678)

    static let secondaryLight = Color(hex: 0x4C5C92)
    static let onSecondaryLight = Color(hex: 0xFFFFFF)
    static let secondaryContainerLight = Color(hex: 0xDCE1FF)
    static let onSecondaryContainerLight = Color(hex: 0x344479)

    static let tertiaryLight = Color(hex: 0x715574)
    static let onTertiaryLight = Color(hex: 0xFFFFFF)
    static let tertiaryContainerLight = Color(hex: 0xFBD7FC)
    static let onTertiaryContainerLight = Color(hex: 0x583E5B)

    static let errorLight = Color(hex: 0xBA1A1A)
    static let onErrorLight = Color(hex: 0xFFFFFF)
    static let errorContainerLight = Color(hex: 0xFFDAD6)
    static let onErrorContainerLight = Color(hex: 0x93000A)

    static let backgroundLight = Color(hex: 0xF9F9FF)
    static let onBackgroundLight = Color(hex: 0x1A1B20)
    static let surfaceLight = Color(hex: 0xF5FAFB)
    static let onSurfaceLight = Color(hex: 0x171D1E)
    static let surfaceVariantLight = Color(hex: 0xDBE4E6)
    static let onSurfaceVariantLight = Color(hex: 0x3F484A)

    static let outlineLight = Color(hex: 0x6F797A)
    static let outlineVariantLight = Color(hex: 0xBFC8CA)
    static let scrimLight = Color(hex: 0x000000)

    static let inverseSurfaceLight = Color(hex: 0x2B3133)
    static let inverseOnSurfaceLight = Color(hex: 0xECF2F3)
    static let inversePrimaryLight = Color(hex: 0xADC6FF)

    static let surfaceDimLight = Color(hex: 0xD5DBDC)
    static let surfaceBrightLight = Color(hex: 0xF5FAFB)
    static let surfaceContainerLowestLight = Color(hex: 0xFFFFFF)
    static let surfaceContainerLowLight = Color(hex: 0xEFF5F6)
    static let surfaceContainerLight = Color(hex: 0xE9EFF0)
    static let surfaceContainerHighLight = Color(hex: 0xE3E9EA)
    static let surfaceContainerHighestLight = Color(hex: 0xDEE3E5)

    static let primaryDark = Color(hex: 0xADC6FF)
    static let onPrimaryDark = Color(hex: 0x102F60)
    static let primaryContainerDark = Color(hex: 0x2B4678)
    static let onPrimaryContainerDark = Color(hex: 0xD8E2FF)

    static let secondaryDark = Color(hex: 0xB6C4FF)
    static let onSecondaryDark = Color(hex: 0x1D2D61)
    static let secondaryContainerDark = Color(hex: 0x344479)
    static let onSecondaryContainerDark = Color(hex: 0xDCE1FF)

    static let tertiaryDark = Color(hex: 0xDEBCDF)
    static let onTertiaryDark = Color(hex: 0x402843)
    static let tertiaryContainerDark = Color(hex: 0x583E5B)
    static let onTertiaryContainerDark = Color(hex: 0xFBD7FC)

    static let errorDark = Color(hex: 0xFFB4AB)
    static let onErrorDark = Color(hex: 0x690005)
    static let errorContainerDark = Color(hex: 0x93000A)
    static let onErrorContainerDark = Color(hex: 0xFFDAD6)

    static let backgroundDark = Color(hex: 0x111318)
    static let onBackgroundDark = Color(hex: 0xE2E2E9)
    static let surfaceDark = Color(hex: 0x0E1415)
    static let onSurfaceDark = Color(hex: 0xDEE3E5)
    static let surfaceVariantDark = Color(hex: 0x3F484A)
    static let onSurfaceVariantDark = Color(hex: 0xBFC8CA)

    static let outlineDark = Color(hex: 0x899294)
    static let outlineVariantDark = Color(hex: 0x3F484A)
    static let scrimDark = Color(hex: 0x000000)

    static let inverseSurfaceDark = Color(hex: 0xDEE3E5)
    static let inverseOnSurfaceDark = Color(hex: 0x2B3133)
    static let inversePrimaryDark = Color(hex: 0x435E91)

    static let surfaceDimDark = Color(hex: 0x0E1415)
    static let surfaceBrightDark = Color(hex: 0x343A3B)
    static let surfaceContainerLowestDark = Color(hex: 0x090F10)
    static let surfaceContainerLowDark = Color(hex: 0x171D1E)
    static let surfaceContainerDark = Color(hex: 0x1B2122)
    static let surfaceContainerHighDark = Color(hex: 0x252B2C)
    static let surfaceContainerHighestDark = Color(hex: 0x303637)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}
