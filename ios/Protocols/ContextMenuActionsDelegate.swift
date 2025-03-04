import ExpoModulesCore

protocol ContextMenuActionsDelegate: AnyObject {
  var onPreviewMenuOptionSelected: EventDispatcher { get }
}
