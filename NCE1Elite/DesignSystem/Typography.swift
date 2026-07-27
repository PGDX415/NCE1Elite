//
//  Typography.swift
//  NCE1Elite
//
//  NCE1 Elite Design System — Typography
//

import SwiftUI

/// Centralized typography for the app.
/// All font styles are referenced through this enum to maintain consistency.
enum NCE1Typography {
    /// Brand title — used for app header "NCE1 Elite"
    static func brandTitle() -> Font {
        .custom("Georgia", size: 22, relativeTo: .title2)
            .weight(.bold)
    }

    /// Player title — large lesson title in the player overlay
    static func playerTitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    /// Lesson title — used in list rows
    static func lessonTitle() -> Font {
        .system(.body, design: .serif)
    }

    /// List header — section headers in lists
    static func listHeader() -> Font {
        .system(.subheadline, design: .serif).weight(.semibold)
    }

    /// Body text — lesson content
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, design: .serif)
    }

    /// Caption — small metadata text (duration, labels)
    static func caption() -> Font {
        .system(.caption, design: .rounded)
    }

    /// Monospaced digit — for time displays, counters
    static func monoDigit(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}
