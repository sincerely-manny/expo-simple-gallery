import AVFoundation
import Photos
import PhotosUI
import UIKit

enum MediaType {
  case image
  case livePhoto
  case video
  case unknown
}

class ImageLoaderService {
  typealias ImageLoadCompletion = (UIImage?, Error?) -> Void
  typealias MediaLoadCompletion = (MediaLoadResult?, Error?) -> Void

  private let imageCache: NSCache<NSString, UIImage>
  private var highQualityRequestID: PHImageRequestID?
  private var lowQualityRequestID: PHImageRequestID?

  init(imageCache: NSCache<NSString, UIImage>) {
    self.imageCache = imageCache
  }

  func cancelRequests() {
    if let requestID = highQualityRequestID {
      PHImageManager.default().cancelImageRequest(requestID)
    }
    if let requestID = lowQualityRequestID {
      PHImageManager.default().cancelImageRequest(requestID)
    }
  }

  func loadMedia(from uri: String, completion: @escaping MediaLoadCompletion) {
    // First determine the media type
    determineMediaType(from: uri) { [weak self] mediaType, error in
      guard let self = self, let mediaType = mediaType else {
        completion(
          nil,
          error
            ?? NSError(
              domain: "MediaLoader", code: 100, userInfo: [NSLocalizedDescriptionKey: "Failed to determine media type"])
        )
        return
      }

      switch mediaType {
      case .image:
        self.loadImage(from: uri) { image, error in
          if let image = image {
            completion(MediaLoadResult(mediaType: .image, image: image), nil)
          } else {
            completion(nil, error)
          }
        }
      case .livePhoto:
        self.loadLivePhoto(from: uri) { livePhoto, image, error in
          if let livePhoto = livePhoto {
            completion(MediaLoadResult(mediaType: .livePhoto, image: image, livePhoto: livePhoto), nil)
          } else if let image = image {
            // Fall back to still image if live photo fails
            completion(MediaLoadResult(mediaType: .image, image: image), nil)
          } else {
            completion(nil, error)
          }
        }
      case .video:
        self.loadVideo(from: uri) { playerItem, thumbnailImage, error in
          if let playerItem = playerItem {
            completion(MediaLoadResult(mediaType: .video, image: thumbnailImage, playerItem: playerItem), nil)
          } else {
            completion(nil, error)
          }
        }
      case .unknown:
        completion(
          nil, NSError(domain: "MediaLoader", code: 101, userInfo: [NSLocalizedDescriptionKey: "Unknown media type"]))
      }
    }
  }

  func determineMediaType(from uri: String, completion: @escaping (MediaType?, Error?) -> Void) {
    // For file:// URLs, check the file extension
    if uri.hasPrefix("file://") {
      let fileExtension = URL(string: uri)?.pathExtension.lowercased() ?? ""

      if ["mov", "mp4", "m4v"].contains(fileExtension) {
        completion(.video, nil)
      } else if ["jpg", "jpeg", "png", "heic"].contains(fileExtension) {
        completion(.image, nil)
      } else {
        completion(.unknown, nil)
      }
      return
    }

    // For ph:// (Photos framework), fetch the asset and check its type
    if uri.hasPrefix("ph://") {
      let assetID = uri.replacingOccurrences(of: "ph://", with: "")
      let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)

      guard let asset = assetResults.firstObject else {
        completion(
          nil, NSError(domain: "MediaLoader", code: 2, userInfo: [NSLocalizedDescriptionKey: "Asset not found"]))
        return
      }

      switch asset.mediaType {
      case .image:
        // Check if it's a live photo
        if asset.mediaSubtypes.contains(.photoLive) {
          completion(.livePhoto, nil)
        } else {
          completion(.image, nil)
        }
      case .video:
        completion(.video, nil)
      default:
        completion(.unknown, nil)
      }
      return
    }

    completion(
      .unknown,
      NSError(domain: "MediaLoader", code: 102, userInfo: [NSLocalizedDescriptionKey: "Unsupported URI format"]))
  }

  func loadImage(from uri: String, loadThumbnailFirst: Bool = true, completion: @escaping ImageLoadCompletion) {
    if uri.hasPrefix("file://"), let url = URL(string: uri) {
      loadFileImage(from: url, uri: uri, completion: completion)
    } else if uri.hasPrefix("ph://") {
      loadPHAsset(uri: uri, loadThumbnailFirst: loadThumbnailFirst, completion: completion)
    } else {
      completion(
        nil, NSError(domain: "ImageLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unsupported URI format"]))
    }
  }

  func loadHighQualityVersion(for uri: String, completion: @escaping ImageLoadCompletion) {
    guard uri.hasPrefix("ph://") else {
      // File images are already high quality
      completion(nil, nil)
      return
    }

    let assetID = uri.replacingOccurrences(of: "ph://", with: "")
    let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)

    guard let asset = assetResults.firstObject else {
      completion(nil, NSError(domain: "ImageLoader", code: 2, userInfo: [NSLocalizedDescriptionKey: "Asset not found"]))
      return
    }

    fetchHighQualityImage(for: asset, uri: uri, completion: completion)
  }

  // MARK: - Private Methods

  private func loadFileImage(from url: URL, uri: String, completion: @escaping ImageLoadCompletion) {
    let cacheKey = (uri as NSString)
    if let cachedImage = imageCache.object(forKey: cacheKey) {
      completion(cachedImage, nil)
    } else {
      if let image = UIImage(contentsOfFile: url.path) {
        imageCache.setObject(image, forKey: cacheKey)
        completion(image, nil)
      } else {
        completion(
          nil,
          NSError(domain: "ImageLoader", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to load file image"]))
      }
    }
  }

  private func loadPHAsset(uri: String, loadThumbnailFirst: Bool, completion: @escaping ImageLoadCompletion) {
    let thumbnailCacheKey = (uri + "_thumbnail" as NSString)
    let highQualityCacheKey = (uri as NSString)

    // Check if high quality version exists in cache
    if let highQualityImage = imageCache.object(forKey: highQualityCacheKey) {
      completion(highQualityImage, nil)
      return
    }

    // Check if thumbnail exists in cache
    if loadThumbnailFirst, let thumbnailImage = imageCache.object(forKey: thumbnailCacheKey) {
      completion(thumbnailImage, nil)
      return
    }

    // Load from Photos framework
    let assetID = uri.replacingOccurrences(of: "ph://", with: "")
    let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)

    guard let asset = assetResults.firstObject else {
      completion(nil, NSError(domain: "ImageLoader", code: 2, userInfo: [NSLocalizedDescriptionKey: "Asset not found"]))
      return
    }

    if loadThumbnailFirst {
      fetchThumbnailImage(for: asset, uri: uri, completion: completion)
    } else {
      fetchHighQualityImage(for: asset, uri: uri, completion: completion)
    }
  }

  private func fetchThumbnailImage(for asset: PHAsset, uri: String, completion: @escaping ImageLoadCompletion) {
    let thumbnailOptions = PHImageRequestOptions()
    thumbnailOptions.isNetworkAccessAllowed = true
    thumbnailOptions.resizeMode = .fast
    thumbnailOptions.isSynchronous = false
    thumbnailOptions.version = .current
    thumbnailOptions.deliveryMode = .opportunistic

    // Cancel any pending thumbnail request
    if let previousRequestID = lowQualityRequestID {
      PHImageManager.default().cancelImageRequest(previousRequestID)
    }

    lowQualityRequestID = PHImageManager.default().requestImage(
      for: asset,
      targetSize: CGSize(width: 300, height: 300),
      contentMode: .aspectFit,
      options: thumbnailOptions
    ) { [weak self] image, info in
      guard let self = self else { return }

      if let error = info?[PHImageErrorKey] {
        completion(nil, error as? Error)
        return
      }

      if let image = image {
        let thumbnailCacheKey = (uri + "_thumbnail" as NSString)
        self.imageCache.setObject(image, forKey: thumbnailCacheKey)
        completion(image, nil)
      }
    }
  }

  private func fetchHighQualityImage(for asset: PHAsset, uri: String, completion: @escaping ImageLoadCompletion) {
    let options = PHImageRequestOptions()

    #if targetEnvironment(simulator)
      options.deliveryMode = .opportunistic
    #else
      options.deliveryMode = .highQualityFormat
    #endif

    options.isNetworkAccessAllowed = true
    options.isSynchronous = false

    // Cancel any previous high-quality request
    if let previousRequestID = highQualityRequestID {
      PHImageManager.default().cancelImageRequest(previousRequestID)
    }

    highQualityRequestID = PHImageManager.default().requestImage(
      for: asset,
      targetSize: PHImageManagerMaximumSize,
      contentMode: .aspectFit,
      options: options
    ) { [weak self] image, info in
      guard let self = self, let image = image else {
        return
      }

      // Only proceed if this is the final image (not a placeholder)
      if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
        return
      }

      // Cache the high quality image
      let highQualityCacheKey = (uri as NSString)
      self.imageCache.setObject(image, forKey: highQualityCacheKey)

      completion(image, nil)
    }
  }
}

extension ImageLoaderService {
  private func loadLivePhoto(from uri: String, completion: @escaping (PHLivePhoto?, UIImage?, Error?) -> Void) {
    guard uri.hasPrefix("ph://") else {
      completion(
        nil, nil,
        NSError(
          domain: "MediaLoader", code: 103,
          userInfo: [NSLocalizedDescriptionKey: "Only Photos framework supports Live Photos"]))
      return
    }

    let assetID = uri.replacingOccurrences(of: "ph://", with: "")
    let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)

    guard let asset = assetResults.firstObject else {
      completion(
        nil, nil, NSError(domain: "MediaLoader", code: 2, userInfo: [NSLocalizedDescriptionKey: "Asset not found"]))
      return
    }

    // First load a thumbnail image for immediate display
    let thumbnailOptions = PHImageRequestOptions()
    thumbnailOptions.isNetworkAccessAllowed = true
    thumbnailOptions.resizeMode = .fast
    thumbnailOptions.isSynchronous = false
    thumbnailOptions.deliveryMode = .opportunistic

    PHImageManager.default().requestImage(
      for: asset,
      targetSize: CGSize(width: 300, height: 300),
      contentMode: .aspectFit,
      options: thumbnailOptions
    ) { [weak self] thumbnailImage, _ in
      // Now request the live photo
      let livePhotoOptions = PHLivePhotoRequestOptions()
      livePhotoOptions.isNetworkAccessAllowed = true
      livePhotoOptions.deliveryMode = .highQualityFormat

      PHImageManager.default().requestLivePhoto(
        for: asset,
        targetSize: PHImageManagerMaximumSize,
        contentMode: .aspectFit,
        options: livePhotoOptions
      ) { livePhoto, info in
        if let error = info?[PHImageErrorKey] {
          completion(nil, thumbnailImage, error as? Error)
          return
        }

        completion(livePhoto, thumbnailImage, nil)
      }
    }
  }
}

extension ImageLoaderService {
  private func loadVideo(from uri: String, completion: @escaping (AVPlayerItem?, UIImage?, Error?) -> Void) {
    if uri.hasPrefix("file://"), let url = URL(string: uri) {
      // For local files, create an AVPlayerItem directly
      let playerItem = AVPlayerItem(url: url)

      // Generate a thumbnail
      generateThumbnail(from: url) { thumbnailImage in
        completion(playerItem, thumbnailImage, nil)
      }
      return
    }

    if uri.hasPrefix("ph://") {
      let assetID = uri.replacingOccurrences(of: "ph://", with: "")
      let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)

      guard let asset = assetResults.firstObject else {
        completion(
          nil, nil, NSError(domain: "MediaLoader", code: 2, userInfo: [NSLocalizedDescriptionKey: "Asset not found"]))
        return
      }

      // First get a thumbnail image
      let thumbnailOptions = PHImageRequestOptions()
      thumbnailOptions.isNetworkAccessAllowed = true
      thumbnailOptions.resizeMode = .fast
      thumbnailOptions.deliveryMode = .opportunistic

      PHImageManager.default().requestImage(
        for: asset,
        targetSize: CGSize(width: 300, height: 300),
        contentMode: .aspectFit,
        options: thumbnailOptions
      ) { thumbnailImage, _ in
        // Now request the video
        let videoOptions = PHVideoRequestOptions()
        videoOptions.isNetworkAccessAllowed = true
        videoOptions.deliveryMode = .highQualityFormat

        PHImageManager.default().requestPlayerItem(
          forVideo: asset,
          options: videoOptions
        ) { playerItem, info in
          if let error = info?[PHImageErrorKey] {
            completion(nil, thumbnailImage, error as? Error)
            return
          }

          completion(playerItem, thumbnailImage, nil)
        }
      }
      return
    }

    completion(
      nil, nil,
      NSError(
        domain: "MediaLoader", code: 104, userInfo: [NSLocalizedDescriptionKey: "Unsupported URI format for video"]))
  }

  private func generateThumbnail(from videoURL: URL, completion: @escaping (UIImage?) -> Void) {
    let asset = AVAsset(url: videoURL)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true

    // Try to get a frame from the middle of the video
    let time = CMTime(seconds: asset.duration.seconds / 2, preferredTimescale: 600)

    imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, _ in
      if let cgImage = cgImage {
        let thumbnail = UIImage(cgImage: cgImage)
        DispatchQueue.main.async {
          completion(thumbnail)
        }
      } else {
        DispatchQueue.main.async {
          completion(nil)
        }
      }
    }
  }
}

class MediaLoadResult {
  let mediaType: MediaType
  let image: UIImage?
  let livePhoto: PHLivePhoto?
  let videoURL: URL?
  let playerItem: AVPlayerItem?

  init(
    mediaType: MediaType, image: UIImage? = nil, livePhoto: PHLivePhoto? = nil, videoURL: URL? = nil,
    playerItem: AVPlayerItem? = nil
  ) {
    self.mediaType = mediaType
    self.image = image
    self.livePhoto = livePhoto
    self.videoURL = videoURL
    self.playerItem = playerItem
  }
}
