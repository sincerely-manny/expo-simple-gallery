import ExpoModulesCore

public class GalleryImageViewerModule: Module {
  public func definition() -> ModuleDefinition {
    Name("GalleryImageViewer")

    View(GalleryViewerContainer.self) {
      Events("onPageChange", "onImageLoaded", "onDismissAttempt")

      Prop("imageData") { (view: GalleryViewerContainer, assets: [String: Any]) in
        let uris = assets["uris"] as? [String] ?? []
        let startIndex = assets["startIndex"] as? Int ?? 0
        view.setImageData(uris: uris, startIndex: startIndex)
      }

      Prop("goToPage") { (view: GalleryViewerContainer, index: Int?) in
        if let index = index {
          view.goToPage(index)
        }
      }

      Prop("viewer") { (view: GalleryViewerContainer, viewerType: String?) in
        if let viewerType = viewerType {
          view.setViewerType(viewerType)
        }
      }
    }
  }
}

protocol ViewerProtocol: UIView {
  func setImageData(uris: [String], startIndex: Int)
  func goToPage(_ index: Int)
  var onPageChange: EventDispatcher { get set }
  var onImageLoaded: EventDispatcher { get set }
  var onDismissAttempt: EventDispatcher { get set }
}

enum ViewerType: Equatable {
  case uikit
  case swiftui

  static func from(string: String) -> ViewerType {
    switch string.lowercased() {
    case "swiftui":
      return .swiftui
    case "uikit":
      return .uikit
    default:
      return .uikit
    }
  }

  func createViewer() -> ViewerProtocol {
    switch self {
    case .uikit:
      return GalleryImageViewerView()
    case .swiftui:
      return SwiftUIGalleryHostView()
    }
  }
}

/// Container view that can switch between UIKit and SwiftUI gallery viewers
final class GalleryViewerContainer: ExpoView {
  // Events exposed to JS
  let onPageChange = EventDispatcher()
  let onImageLoaded = EventDispatcher()
  let onDismissAttempt = EventDispatcher()

  private var currentViewer: ViewerProtocol?
  private var viewerType: ViewerType = .uikit

  // Store the data to reapply when switching viewers
  private var currentUris: [String] = []
  private var currentStartIndex: Int = 0

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    setupViewer()
  }

  func setViewerType(_ viewerTypeString: String) {
    // print("Setting viewer type to \(viewerTypeString)")
    let newViewerType = ViewerType.from(string: viewerTypeString)
    // print("New viewer type: \(newViewerType)")

    // Only switch if the type is different
    guard newViewerType != viewerType else { return }

    viewerType = newViewerType

    // Remove old viewer
    if let oldViewer = currentViewer {
      oldViewer.removeFromSuperview()
    }

    // Create and setup new viewer
    setupViewer()

    // Reapply current data if any
    if !currentUris.isEmpty {
      currentViewer?.setImageData(uris: currentUris, startIndex: currentStartIndex)
    }
  }

  private func setupViewer() {
    let newViewer = viewerType.createViewer()

    // Add as subview
    addSubview(newViewer)
    newViewer.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      newViewer.topAnchor.constraint(equalTo: topAnchor),
      newViewer.bottomAnchor.constraint(equalTo: bottomAnchor),
      newViewer.leadingAnchor.constraint(equalTo: leadingAnchor),
      newViewer.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])

    currentViewer = newViewer
    currentViewer?.onPageChange = onPageChange
    currentViewer?.onImageLoaded = onImageLoaded
    currentViewer?.onDismissAttempt = onDismissAttempt
  }

  func setImageData(uris: [String], startIndex: Int) {
    currentUris = uris
    currentStartIndex = startIndex
    currentViewer?.setImageData(uris: uris, startIndex: startIndex)
  }

  func goToPage(_ index: Int) {
    currentViewer?.goToPage(index)
  }
}
