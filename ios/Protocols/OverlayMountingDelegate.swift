import ExpoModulesCore
import ExpoModulesCore

/// Protocol for any view that can contain a React component overlay
protocol OverlayContainer: UIView {
    var overlayContainer: ExpoView { get }
    var containerIdentifier: Int? { get }
}

/// Protocol for mounting React components as overlays to various container types
protocol OverlayMountingDelegate: AnyObject {
    /// Mount an existing overlay to a container
    func mount<T: OverlayContainer>(to container: T)
    
    /// Mount a specific overlay component to a container
    func mount<T: OverlayContainer>(to container: T, overlay: ReactMountingComponent)
    
    /// Unmount all overlays from a container
    func unmount<T: OverlayContainer>(from container: T)
    
    /// Unmount a specific overlay component
    func unmount(overlay: ReactMountingComponent)
    
    /// Get the currently mounted overlay component for a container
    func getMountedOverlayComponent<T: OverlayContainer>(for container: T) -> ReactMountingComponent?
}
