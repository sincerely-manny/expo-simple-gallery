struct ImageLoadTask: Cancellable {
  let workItem: DispatchWorkItem

  func cancel() {
    workItem.cancel()
  }
}
