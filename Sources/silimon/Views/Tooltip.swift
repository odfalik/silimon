import SwiftUI
import AppKit

/// A view modifier that adds a native macOS tooltip using NSView
struct TooltipModifier: ViewModifier {
    let tooltip: String

    func body(content: Content) -> some View {
        content
            .background(TooltipView(tooltip: tooltip))
    }
}

/// NSViewRepresentable that sets the tooltip on the underlying NSView
private struct TooltipView: NSViewRepresentable {
    let tooltip: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.toolTip = tooltip
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.toolTip = tooltip
    }
}

extension View {
    /// Adds a native macOS tooltip that works in popovers
    func tooltip(_ text: String) -> some View {
        modifier(TooltipModifier(tooltip: text))
    }
}
