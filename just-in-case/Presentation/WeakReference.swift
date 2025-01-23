final class WeakReference<T: AnyObject> {
  weak var value: T?

  init(_ value: T) {
    self.value = value
  }
}
