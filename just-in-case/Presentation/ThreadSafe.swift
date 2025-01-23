@propertyWrapper
struct ThreadSafe<Value> {
  private var value: Value
  private let lock = NSLock()

  init(wrappedValue: Value) {
    self.value = wrappedValue
  }

  var wrappedValue: Value {
    get { lock.withLock { value } }
    set { lock.withLock { value = newValue } }
  }
}

extension NSLock {
  func withLock<T>(_ block: () -> T) -> T {
    lock()
    defer { unlock() }
    return block()
  }
}
