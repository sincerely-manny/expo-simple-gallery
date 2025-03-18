import Foundation

protocol MediaViewControllerDelegate: AnyObject {
  func mediaViewControllerDidRequestDismiss(_ controller: UIViewController)
}

