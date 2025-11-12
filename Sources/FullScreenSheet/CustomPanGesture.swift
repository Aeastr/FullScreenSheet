import SwiftUI

// MARK: - Constants

/// Configuration values for gesture recognition behavior.
private enum GestureConstants {
    /// Maximum scroll offset (in points) at which the pull-to-dismiss gesture activates.
    /// The gesture only works when the scroll view is within this distance from the top.
    static let scrollOffsetThreshold: CGFloat = 1
}

// MARK: - Custom Pan Gesture

/// A custom pan gesture that works alongside scroll views to enable pull-to-dismiss functionality.
///
/// This gesture recognizer integrates with SwiftUI's gesture system and coordinates with scroll views
/// to only activate when the scroll view is at the top and the user is pulling downward.
struct CustomPanGesture: UIGestureRecognizerRepresentable {
    /// Callback that receives the pan gesture recognizer for custom handling.
    var handle: (UIPanGestureRecognizer) -> ()

    /// Creates the coordinator that manages gesture recognition delegate methods.
    /// - Parameter converter: The coordinate space converter (not used in this implementation).
    /// - Returns: A new coordinator instance.
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    /// Creates the underlying UIKit pan gesture recognizer.
    /// - Parameter context: The context containing the coordinator.
    /// - Returns: A configured pan gesture recognizer with the coordinator set as its delegate.
    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        return gesture
    }

    /// Updates the gesture recognizer when SwiftUI state changes.
    ///
    /// This implementation doesn't need to perform any updates, but the method
    /// is required by the protocol.
    func updateUIGestureRecognizer(_ recognizer: UIGestureRecognizerType, context: Context) {

    }

    /// Handles gesture recognizer actions by forwarding them to the callback.
    /// - Parameters:
    ///   - recognizer: The gesture recognizer that triggered the action.
    ///   - context: The context containing the coordinator.
    func handleUIGestureRecognizerAction(_ recognizer: UIGestureRecognizerType, context: Context) {
            handle(recognizer)
    }

    /// Coordinator that implements the gesture delegate to control when the pan gesture should activate.
    ///
    /// The coordinator ensures that the pan gesture only works when:
    /// 1. The associated scroll view is scrolled to the top (within 1 point of the top edge)
    /// 2. The user is dragging downward (positive velocity)
    ///
    /// This prevents conflicts between scrolling content and the dismissal gesture.
    class Coordinator: NSObject, UIGestureRecognizerDelegate{
        /// Determines whether this gesture can work simultaneously with other gestures (like scroll views).
        ///
        /// The gesture is allowed to work alongside scroll gestures only when the scroll view
        /// is at the top and the user is pulling down.
        ///
        /// - Parameters:
        ///   - gestureRecognizer: This pan gesture recognizer.
        ///   - otherGestureRecognizer: The other gesture (typically a scroll view's pan gesture).
        /// - Returns: `true` if the scroll view is at the top and dragging down, `false` otherwise.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Ensure we're working with a pan gesture
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
                return false
            }

            // If the other gesture is a pan gesture but NOT attached to a scroll/collection view,
            // block the dismiss gesture (for other custom drag gestures in the content)
            if otherGestureRecognizer is UIPanGestureRecognizer {
                let isScrollViewGesture = otherGestureRecognizer.view is UIScrollView ||
                                         otherGestureRecognizer.view is UICollectionView
                if !isScrollViewGesture {
                    return false
                }
            }

            // Get the vertical velocity of the pan gesture
            let velocity = panGesture.velocity(in: panGesture.view).y
            var verticalOffset: CGFloat = 0
            var horizontalOffset: CGFloat = 0

            // Check if the other gesture belongs to a collection view
            if let collectionView = otherGestureRecognizer.view as? UICollectionView{
                // Calculate the scroll position accounting for content insets
                verticalOffset = collectionView.contentOffset.y + collectionView.adjustedContentInset.top
                horizontalOffset = collectionView.contentOffset.x + collectionView.adjustedContentInset.left
            }

            // Check if the other gesture belongs to a scroll view
            if let scrollView = otherGestureRecognizer.view as? UIScrollView{
                // Calculate the scroll position accounting for content insets
                verticalOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
                horizontalOffset = scrollView.contentOffset.x + scrollView.adjustedContentInset.left
            }

            // Only allow simultaneous recognition when:
            // - The scroll view is at or very near the top (vertically)
            // - The scroll view is at or very near the left edge (horizontally)
            // - The user is dragging downward (velocity > 0)
            let isElligible = verticalOffset <= GestureConstants.scrollOffsetThreshold &&
                              horizontalOffset <= GestureConstants.scrollOffsetThreshold &&
                              velocity > 0
            return isElligible
        }

        /// Determines whether the gesture should begin based on the presence of navigation transitions.
        ///
        /// This prevents the pull-to-dismiss gesture from interfering with matched geometry effects
        /// like `.navigationTransition(.zoom(...))`. When a zoom gesture is detected, the custom
        /// pan gesture is disabled to allow the navigation transition to work properly.
        ///
        /// - Parameter gestureRecognizer: The gesture recognizer being evaluated.
        /// - Returns: `false` if a zoom transition is active, `true` otherwise.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            let status = (gestureRecognizer.view?.gestureRecognizers?.contains(where: {
                ($0.name ?? "").localizedStandardContains("zoom")
            })) ?? false

            return !status
        }

        /// Makes the dismiss gesture wait for other pan gestures to fail first.
        ///
        /// This ensures that custom drag gestures in the content have priority
        /// over the dismiss gesture. The dismiss gesture will only activate if the other
        /// pan gesture fails to recognize.
        ///
        /// - Parameters:
        ///   - gestureRecognizer: The dismiss gesture recognizer.
        ///   - otherGestureRecognizer: Another gesture recognizer in the view hierarchy.
        /// - Returns: `true` if dismiss gesture should wait for the other pan gesture to fail.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // If the other gesture is a pan gesture but NOT a scroll view gesture,
            // require it to fail before the dismiss gesture can begin
            // (gives priority to custom drag gestures in the content)
            if otherGestureRecognizer is UIPanGestureRecognizer {
                let isScrollViewGesture = otherGestureRecognizer.view is UIScrollView ||
                                         otherGestureRecognizer.view is UICollectionView
                return !isScrollViewGesture
            }

            return false
        }
    }
}
