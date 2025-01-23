protocol ImageLoaderProtocol {
  func loadImage(url: URL, targetSize: CGSize, completion: @escaping (UIImage?) -> Void)
    -> Cancellable
}
