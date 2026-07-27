//
//  Colors.swift
//  NCE1Elite
//
//  NCE1 Elite Design System — Color Tokens
//

import SwiftUI

/// Centralized color palette with light/dark mode support.
enum NCE1Colors {
    // MARK: - Background
    static let background = Color(light: UIColor(red: 0.9647, green: 0.9451, blue: 0.9059, alpha: 1),
                                  dark: UIColor(red: 0.0549, green: 0.1020, blue: 0.1686, alpha: 1))
    static let card = Color(light: UIColor(red: 0.9882, green: 0.9804, blue: 0.9608, alpha: 1),
                            dark: UIColor(red: 0.1020, green: 0.1333, blue: 0.2000, alpha: 1))

    // MARK: - Brand
    static let oxfordBlue = Color(light: UIColor(red: 0.1020, green: 0.2275, blue: 0.4196, alpha: 1),
                                   dark: UIColor(red: 0.2902, green: 0.5608, blue: 0.9059, alpha: 1))
    static let antiqueGold = Color(light: UIColor(red: 0.7216, green: 0.5922, blue: 0.2471, alpha: 1),
                                   dark: UIColor(red: 0.8314, green: 0.6588, blue: 0.2627, alpha: 1))
    static let bordeaux = Color(light: UIColor(red: 0.4314, green: 0.0588, blue: 0.1020, alpha: 1),
                                dark: UIColor(red: 0.4314, green: 0.0588, blue: 0.1020, alpha: 1))

    // MARK: - Text
    static let text = Color(light: UIColor(red: 0.1098, green: 0.1098, blue: 0.1176, alpha: 1),
                            dark: UIColor(red: 0.8980, green: 0.8784, blue: 0.8471, alpha: 1))
    static let textSecondary = Color(light: UIColor(red: 0.3569, green: 0.3922, blue: 0.4471, alpha: 1),
                                     dark: UIColor(red: 0.6118, green: 0.6392, blue: 0.6863, alpha: 1))

    // MARK: - Separator
    static let separator = Color(light: UIColor(red: 0.8510, green: 0.8235, blue: 0.7608, alpha: 1),
                                 dark: UIColor(red: 0.1647, green: 0.2000, blue: 0.2549, alpha: 1))
}

// MARK: - Adaptive Color Extension

extension Color {
    /// Creates a color that adapts to light and dark color schemes.
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
}
