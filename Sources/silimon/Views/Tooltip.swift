import SwiftUI
import AppKit

/// A wrapper view that adds a native macOS tooltip
struct TooltipWrapper<Content: View>: NSViewRepresentable {
    let content: Content
    let tooltip: String

    init(_ tooltip: String, @ViewBuilder content: () -> Content) {
        self.tooltip = tooltip
        self.content = content()
    }

    func makeNSView(context: Context) -> NSHostingView<Content> {
        let hostingView = NSHostingView(rootView: content)
        hostingView.toolTip = tooltip
        return hostingView
    }

    func updateNSView(_ nsView: NSHostingView<Content>, context: Context) {
        nsView.rootView = content
        nsView.toolTip = tooltip
    }
}

extension View {
    /// Adds a native macOS tooltip that works in popovers
    func tooltip(_ text: String) -> some View {
        TooltipWrapper(text) { self }
    }
}
