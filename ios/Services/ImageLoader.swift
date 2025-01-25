import Photos

final class ImageLoader: ImageLoaderProtocol {
  private var ongoingTasks: [URL: LoadTask] = [:]
  private let taskQueue = DispatchQueue(label: "com.imageloader.queue", attributes: .concurrent)

  struct LoadTask: Cancellable {
    let workItem: DispatchWorkItem
    let requestID: UUID

    func cancel() {
      workItem.cancel()
    }
  }

  func loadImage(url: URL, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) -> Cancellable {
    // Cancel any existing task for this URL
    taskQueue.async(flags: .barrier) {
      self.ongoingTasks[url]?.cancel()
      self.ongoingTasks.removeValue(forKey: url)
    }

    let requestID = UUID()
    let task = DispatchWorkItem { [weak self] in
      self?.handleImageLoad(url: url, targetSize: targetSize) { image in
        self?.taskQueue.async(flags: .barrier) {
          // Only complete if this is still the active task
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
    }

    // Request a slightly larger size to ensure quality
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
    ) { image, info in
      // Only deliver final image, not degraded ones
      if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
        isDegraded
      {
        return
      }

      DispatchQueue.main.async {
        completion(image)
      }
    }
  }
}
