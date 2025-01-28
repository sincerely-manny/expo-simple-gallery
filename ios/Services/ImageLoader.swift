import Photos

final class ImageLoader: ImageLoaderProtocol {
  private var ongoingTasks: [URL: LoadTask] = [:]
  private let taskQueue = DispatchQueue(label: "com.imageloader.queue", attributes: .concurrent)

  private let previewCache = NSCache<NSURL, UIImage>()

  struct LoadTask: Cancellable {
    let workItem: DispatchWorkItem
    let requestID: UUID

    func cancel() {
      workItem.cancel()
    }
  }

  init() {
    // Configure cache
    previewCache.countLimit = 1000
    previewCache.totalCostLimit = 1024 * 1024 * 50
  }

  func loadImage(url: URL, targetSize: CGSize, completion: @escaping (UIImage?) -> Void)
    -> Cancellable
  {
    // Check preview cache first
    if let cachedPreview = previewCache.object(forKey: url as NSURL) {
      // Deliver cached preview immediately
      DispatchQueue.main.async {
        completion(cachedPreview)
      }
    }

    // Continue with full resolution load
    taskQueue.async(flags: .barrier) {
      self.ongoingTasks[url]?.cancel()
      self.ongoingTasks.removeValue(forKey: url)
    }

    let requestID = UUID()
    let task = DispatchWorkItem { [weak self] in
      self?.handleImageLoad(url: url, targetSize: targetSize) { image in
        self?.taskQueue.async(flags: .barrier) {
          if self?.ongoingTasks[url]?.requestID == requestID {
            DispatchQueue.main.async {
              completion(image)
            }
            self?.ongoingTasks.removeValue(forKey: url)
          }
        }
      }
    }

    let loadTask = LoadTask(workItem: task, requestID: requestID)

    taskQueue.async(flags: .barrier) {
      self.ongoingTasks[url] = loadTask
    }

    DispatchQueue.global(qos: .userInitiated).async(execute: task)
    return loadTask
  }

  private func handleImageLoad(
    url: URL, targetSize: CGSize, completion: @escaping (UIImage?) -> Void
  ) {
    switch url.scheme {
    case "file":
      handleFileImage(url: url, targetSize: targetSize, completion: completion)
    case "ph":
      handlePhotoLibraryImage(url: url, targetSize: targetSize, completion: completion)
    default:
      print("Unsupported URI scheme:", url.scheme ?? "none")
      completion(nil)
    }
  }

  private func handleFileImage(
    url: URL,
    targetSize: CGSize,
    completion: @escaping (UIImage?) -> Void
  ) {
    guard let originalImage = UIImage(contentsOfFile: url.path) else {
      completion(nil)
      return
    }

    // Calculate proper size including scale
    let scale = UIScreen.main.scale
    let scaledSize = CGSize(
      width: targetSize.width * scale,
      height: targetSize.height * scale
    )

    DispatchQueue.global(qos: .userInitiated).async {
      let resizedImage = ImageResizer.resize(
        image: originalImage,
        to: scaledSize
      )

      DispatchQueue.main.async {
        completion(resizedImage)
      }
    }
  }

  private func handlePhotoLibraryImage(
    url: URL,
    targetSize: CGSize,
    completion: @escaping (UIImage?) -> Void
  ) {
    let assetID = url.absoluteString.replacingOccurrences(of: "ph://", with: "")
    guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil).firstObject
    else {
      completion(nil)
      return
    }

    let options = PHImageRequestOptions()
    options.resizeMode = .fast
    options.deliveryMode = .opportunistic
    options.isNetworkAccessAllowed = true
    options.isSynchronous = false

    if #available(iOS 17, *) {
      options.allowSecondaryDegradedImage = true
      options.deliveryMode = .highQualityFormat
      //options.resizeMode = .exact
    }

    let scale = UIScreen.main.scale
    let scaledSize = CGSize(
      width: targetSize.width * scale,
      height: targetSize.height * scale
    )

    PHImageManager.default().requestImage(
      for: asset,
      targetSize: scaledSize,
      contentMode: .aspectFill,
      options: options
    ) { [weak self] image, info in
      if let image = image {
        // Cache degraded images as previews
        if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
          isDegraded
        {
          self?.previewCache.setObject(image, forKey: url as NSURL)
        }
        completion(image)
      }
    }
  }
}
