import Cocoa

let windowList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] ?? []
let silimonWindows = windowList.filter { ($0["kCGWindowOwnerName"] as? String) == "silimon" }

for window in silimonWindows {
    let windowID = window["kCGWindowNumber"] as? Int ?? 0
    print("Window ID: \(windowID)")
}
