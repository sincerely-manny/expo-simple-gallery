import Photos

final class ImageLoader: ImageLoaderProtocol {
  struct LoadTask: Cancellable {
    let workItem: DispatchWorkItem

    func cancel() {
      workItem.cancel()
    }
  }

  func loadImage(url: URL, targetSize: CGSize, completion: @escaping (UIImage?) -> Void)
    -> Cancellable
  {
    let task = DispatchWorkItem { [weak self] in
      self?.handleImageLoad(url: url, targetSize: targetSize, completion: completion)
    }

    DispatchQueue.global(qos: .userInitiated).async(execute: task)
    return LoadTask(workItem: task)
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
    url: URL, targetSize: CGSize, completion: @escaping (UIImage?) -> Void
  ) {
    guard let originalImage = UIImage(contentsOfFile: url.path) else {
      completion(nil)
      return
    }

    let resizedImage = ImageResizer.resize(image: originalImage, to: targetSize)
    DispatchQueue.main.async {
      completion(resizedImage)
    }
  }

  private func handlePhotoLibraryImage(
    url: URL, targetSize: CGSize, completion: @escaping (UIImage?) -> Void
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

    PHImageManager.default().requestImage(
      for: asset,
      targetSize: targetSize,
      contentMode: .aspectFill,
      options: options
    ) { image, _ in
      DispatchQueue.main.async {
        completion(image)
      }
    }
  }
}
