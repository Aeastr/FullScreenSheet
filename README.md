<div align="center">
  <h1><b>FullScreenSheet</b></h1>
  <p>
    Full-screen sheet presentation with pull-to-dismiss gesture support for SwiftUI.
  </p>
</div>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0+-F05138?logo=swift&logoColor=white" alt="Swift 6.0+"></a>
  <a href="https://developer.apple.com"><img src="https://img.shields.io/badge/iOS-18+-000000?logo=apple" alt="iOS 18+"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"></a>
</p>

https://github.com/user-attachments/assets/73627b5d-e0e0-495c-b263-6ea05b626102


## Overview

SwiftUI's `.fullScreenCover` doesn't support interactive dismissal, and `.sheet` isn't truly full-screen. FullScreenSheet provides two options:

| Target | API | App Store Safe | Features |
|--------|-----|----------------|----------|
| `FullScreenSheet` | Public | Yes | Pull-to-dismiss, scroll integration, custom backgrounds |
| `FullScreenSheetPrivate` | Private | No | Apple Music-style presentation with dimming effect |


## Installation

```swift
dependencies: [
    .package(url: "https://github.com/aeastr/FullScreenSheet.git", from: "1.0.0")
]
```

Add the target you need:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FullScreenSheet", package: "FullScreenSheet"),
        // OR
        .product(name: "FullScreenSheetPrivate", package: "FullScreenSheet")
    ]
)
```


## Usage

### FullScreenSheet (Public API)

```swift
import FullScreenSheet

struct ContentView: View {
    @State private var showSheet = false

    var body: some View {
        Button("Show Sheet") {
            showSheet = true
        }
        .fullScreenSheet(isPresented: $showSheet) {
            ScrollView {
                // Your content
            }
        }
    }
}
```

**API variants:**
```swift
.fullScreenSheet(isPresented: $showSheet) { }
.fullScreenSheet(isPresented: $showSheet, onDismiss: { }) { }
.fullScreenSheet(item: $selectedItem) { item in }
.fullScreenSheet(item: $selectedItem, onDismiss: { }) { item in }
```

### FullScreenSheetPrivate (Private API)

> [!WARNING]
> Uses private APIs. May be rejected by App Store review. Use at your own risk.

```swift
import FullScreenSheetPrivate

struct ContentView: View {
    @State private var showSheet = false

    var body: some View {
        Button("Show Sheet") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            ScrollView {
                // Your content
            }
            .presentationFullScreen(.enabled)
        }
    }
}
```


## Customization

### Custom Backgrounds (FullScreenSheet only)

Use `presentationFullScreenBackground` instead of `.presentationBackground`—the background needs to move in sync with the dismiss gesture.

```swift
.fullScreenSheet(isPresented: $showSheet) {
    Text("Hello!")
        .presentationFullScreenBackground(.purple.gradient)
}

// Or with a custom view
.fullScreenSheet(isPresented: $showSheet) {
    Text("Hello!")
        .presentationFullScreenBackground {
            LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
}
```

### Navigation Transitions

When using `.navigationTransition` with matched geometry effects, pull-to-dismiss is automatically disabled to prevent conflicts:

```swift
@Namespace var namespace

.fullScreenSheet(isPresented: $showSheet) {
    Circle()
        .navigationTransition(.zoom(sourceID: "circle", in: namespace))
    // Pull-to-dismiss automatically disabled
}
```


## How It Works

### FullScreenSheet (Public API)

**Gesture Coordination:**
- Custom UIKit pan gesture recognizer integrates with SwiftUI
- Works alongside scroll gestures via `UIGestureRecognizerDelegate`
- Only activates when scroll view is at top and pulling downward

**Dismissal Logic:**
- Combines translation distance and velocity (scaled and clamped)
- If `(translation + velocity) > halfHeight`, sheet dismisses; otherwise snaps back

**Background Sync:**
- Uses SwiftUI preference keys to propagate background up the hierarchy
- Both content and background apply the same offset during drag

### FullScreenSheetPrivate (Private API)

Uses obfuscated private APIs on `UISheetPresentationController`:
- `_wantsFullScreen` – enables full-screen with dimming
- `_allowsInteractiveDismissWhenFullScreen` – allows swipe-to-dismiss

Private API strings are obfuscated at compile-time using [Obfuscate](https://github.com/Aeastr/Obfuscate).


## Contributing

Contributions welcome. Please feel free to submit a Pull Request.


## License

MIT. See [LICENSE](LICENSE) for details.
