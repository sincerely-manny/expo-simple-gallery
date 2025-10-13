import AVFoundation
import ImageIO
import MobileCoreServices
import Photos
import PhotosUI
import SwiftUI

private enum LoadedMedia {
  case image(UIImage, isDegraded: Bool)
  case livePhoto(PHLivePhoto)
  case video(AVPlayer)
}

struct PageMediaView: View {
  let uri: String
  let index: Int
  var onLoaded: (Int, String) -> Void

  var onDismiss: () -> Void
  var onDragProgress: (CGFloat) -> Void

  @State private var media: LoadedMedia?
  @State private var didSendLoad = false

  // Image-only state
  @State private var isDegraded = false

  // Drag state
  @State private var dragY: CGFloat = 0
  @State private var lastReportedProgress: CGFloat = 0

  var body: some View {
    GeometryReader { proxy in
      let height = max(proxy.size.height, 1)
      let progress = min(1, max(0, dragY / height))
      let maxScaleDrop: CGFloat = 0.5
      let scale = 1.0 - maxScaleDrop * progress

      ZStack {
        switch media {
        case .image(let img, _):
          Image(uiImage: img)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .blur(radius: isDegraded ? 5 : 0)  // explicit animate only on un-blur
        case .livePhoto(let live):
          LivePhotoView(livePhoto: live, isMuted: true, play: true)
            .frame(width: proxy.size.width, height: proxy.size.height)
        case .video(let player):
          PlayerView(player: player)
            .frame(width: proxy.size.width, height: proxy.size.height)
        case .none:
          Color.black
        }
      }
      .scaleEffect(scale)
      .offset(y: max(0, dragY))
      .overlay(
        VerticalPanOverlay(
          onChanged: { translationY, _ in
            let newY = max(0, translationY)
            dragY = newY
            let p = min(1, max(0, newY / height))
            if abs(p - lastReportedProgress) > 0.01 {
              lastReportedProgress = p
              onDragProgress(p)
            }
          },
          onEnded: { translationY, velocityY, _ in
            let p = min(1, max(0, translationY / height))
            let distanceThreshold: CGFloat = 0.25
            let velocityThreshold: CGFloat = 900
            let shouldDismiss =
              translationY > 0 && (p > distanceThreshold || velocityY > velocityThreshold)

            if shouldDismiss {
              onDragProgress(1)
              onDismiss()
            } else {
              withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                dragY = 0
              }
              withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                onDragProgress(0)
                lastReportedProgress = 0
              }
            }
          }
        )
      )
      .task(id: taskID(uri: uri, size: proxy.size)) {
        // Reset state for new load
        await MainActor.run {
          media = nil
          isDegraded = false
        }

        let screenScale = UIScreen.main.scale
        let sizePoints = proxy.size
        let sizePixels = CGSize(
          width: sizePoints.width * screenScale, height: sizePoints.height * screenScale)

        // Load off-main, inherit cancellation
        let result = await Task(priority: .userInitiated) {
          await loadMedia(uri: uri, targetSizePixels: sizePixels) { degraded in
            await MainActor.run {
              // Set degraded image without animating blur-in
              isDegraded = true
              media = .image(degraded, isDegraded: true)
            }
          }
        }.value

        await MainActor.run {
          switch result {
          case .image(let finalImage):
            // Swap to hi-res, then animate un-blur only if we were degraded
            let wasDegraded = isDegraded
            media = .image(finalImage, isDegraded: false)
            if wasDegraded {
              withAnimation(.easeInOut(duration: 0.2)) {
                isDegraded = false
              }
            } else {
              isDegraded = false
            }
            if !didSendLoad {
              onLoaded(index, uri)
              didSendLoad = true
            }
          case .livePhoto(let live):
            media = .livePhoto(live)
            if !didSendLoad {
              onLoaded(index, uri)
              didSendLoad = true
            }
          case .video(let player):
            media = .video(player)
            if !didSendLoad {
              onLoaded(index, uri)
              didSendLoad = true
            }
          case .none:
            break
          }
        }
      }
    }
  }

  private func taskID(uri: String, size: CGSize) -> String {
    "\(uri)-\(Int(size.width))x\(Int(size.height))"
  }

  private enum LoadResult {
    case image(UIImage)
    case livePhoto(PHLivePhoto)
    case video(AVPlayer)
    case none
  }

  private func loadMedia(
    uri: String,
    targetSizePixels: CGSize,
    onLoadDegraded: @escaping @Sendable (UIImage) async -> Void
  ) async -> LoadResult {
    if Task.isCancelled { return .none }

    if uri.hasPrefix("file://") {
      guard let url = URL(string: uri) else { return .none }
      // Decide by extension/pairing
      let ext = url.pathExtension.lowercased()
      if isVideoExtension(ext) {
        let player = AVPlayer(url: url)
        return .video(player)
      }

      if let (imageURL, videoURL) = findLivePhotoPair(for: url) {
        // Create PHLivePhoto from resource file URLs
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        let livePhoto = await withCheckedContinuation {
          (cont: CheckedContinuation<PHLivePhoto?, Never>) in
          PHLivePhoto.request(
            withResourceFileURLs: [imageURL, videoURL],
            placeholderImage: nil,
            targetSize: targetSizePixels,
            contentMode: .aspectFit
          ) { live, _ in
            cont.resume(returning: live)
          }
        }
        if Task.isCancelled { return .none }
        if let live = livePhoto {
          return .livePhoto(live)
        }
        // fallthrough to image if live failed
      }

      // Decode image efficiently via ImageIO thumbnailing
      let maxPixelSize = Int(max(targetSizePixels.width, targetSizePixels.height))
      if let src = CGImageSourceCreateWithURL(url as CFURL, nil) {
        let opts: [CFString: Any] = [
          kCGImageSourceShouldCache: false,
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
          kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        if let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) {
          if Task.isCancelled { return .none }
          return .image(UIImage(cgImage: cg))
        }
      }
      if Task.isCancelled { return .none }
      if let img = UIImage(contentsOfFile: url.path) {
        return .image(img)
      }
      return .none
    }

    if uri.hasPrefix("ph://") {
      let assetID = uri.replacingOccurrences(of: "ph://", with: "")
      let results = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
      guard let asset = results.firstObject else { return .none }

      switch asset.mediaType {
      case .video:
        let vopts = PHVideoRequestOptions()
        vopts.deliveryMode = .automatic
        vopts.isNetworkAccessAllowed = true
        let playerItem: AVPlayerItem? = await withCheckedContinuation { cont in
          PHImageManager.default().requestPlayerItem(forVideo: asset, options: vopts) { item, _ in
            cont.resume(returning: item)
          }
        }
        if Task.isCancelled { return .none }
        if let item = playerItem {
          let player = AVPlayer(playerItem: item)
          return .video(player)
        }
        return .none
      case .image:
        if asset.mediaSubtypes.contains(.photoLive) {
          let lopts = PHLivePhotoRequestOptions()
          lopts.deliveryMode = .highQualityFormat
          lopts.isNetworkAccessAllowed = true
          let live: PHLivePhoto? = await withCheckedContinuation { cont in
            PHImageManager.default().requestLivePhoto(
              for: asset,
              targetSize: targetSizePixels,
              contentMode: .aspectFit,
              options: lopts
            ) { live, _ in
              cont.resume(returning: live)
            }
          }
          if Task.isCancelled { return .none }
          if let live = live {
            return .livePhoto(live)
          }
          // fallthrough to still if live failed
        }

        // Opportunistic degraded->final image flow
        let iopts = PHImageRequestOptions()
        iopts.deliveryMode = .opportunistic
        iopts.resizeMode = .exact
        iopts.version = .current
        iopts.isNetworkAccessAllowed = true
        iopts.isSynchronous = false

        let uiImage: UIImage? = await withCheckedContinuation { continuation in
          var didResume = false
          let _ = PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSizePixels,
            contentMode: .aspectFit,
            options: iopts
          ) { image, info in
            let degraded = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
            let cancelled = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false
            let error = info?[PHImageErrorKey] as? NSError

            if cancelled || error != nil {
              if !didResume {
                didResume = true
                continuation.resume(returning: nil)
              }
              return
            }

            if let img = image {
              if degraded {
                Task { await onLoadDegraded(img) }
              } else if !didResume {
                didResume = true
                continuation.resume(returning: img)
              }
            } else if !degraded && !didResume {
              didResume = true
              continuation.resume(returning: nil)
            }
          }
        }
        if Task.isCancelled { return .none }
        if let img = uiImage {
          return .image(img)
        }
        return .none

      default:
        return .none
      }
    }

    return .none
  }

  private func isVideoExtension(_ ext: String) -> Bool {
    ["mov", "mp4", "m4v", "mkv"].contains(ext)
  }

  private func isImageExtension(_ ext: String) -> Bool {
    ["jpg", "jpeg", "png", "heic", "heif", "gif", "tiff", "bmp"].contains(ext)
  }

  // Attempt to find a live photo pair for a given URL:
  // - If URL is image, look for sibling .mov
  // - If URL is video, look for sibling image
  private func findLivePhotoPair(for url: URL) -> (image: URL, video: URL)? {
    let fm = FileManager.default
    let ext = url.pathExtension.lowercased()
    let base = url.deletingPathExtension()

    if isImageExtension(ext) {
      let candidates = ["mov", "mp4"].map { base.appendingPathExtension($0) }
      if let mov = candidates.first(where: { fm.fileExists(atPath: $0.path) }) {
        return (image: url, video: mov)
      }
    } else if isVideoExtension(ext) {
      let candidates = ["heic", "heif", "jpg", "jpeg", "png"].map {
        base.appendingPathExtension($0)
      }
      if let img = candidates.first(where: { fm.fileExists(atPath: $0.path) }) {
        return (image: img, video: url)
      }
    }
    return nil
  }
}
