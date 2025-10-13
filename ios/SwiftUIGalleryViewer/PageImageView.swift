import Photos
import SwiftUI

struct PageImageView: View {
  let uri: String
  let index: Int
  var onLoaded: (Int, String) -> Void

  var onDismiss: () -> Void
  var onDragProgress: (CGFloat) -> Void

  @State private var image: UIImage?
  @State private var didSendLoad = false

  @State private var isDegraded = false

  @State private var dragY: CGFloat = 0
  @State private var lastReportedProgress: CGFloat = 0

  var body: some View {
    GeometryReader { proxy in
      let height = max(proxy.size.height, 1)
      let progress = min(1, max(0, dragY / height))
      let maxScaleDrop: CGFloat = 0.5
      let scale = 1.0 - maxScaleDrop * progress

      ZStack {
        if let uiImage = image {
          Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .blur(radius: isDegraded ? 5 : 0)  // no implicit animation
        } else {
          Color.black
        }
      }
      .scaleEffect(scale)
      .offset(y: max(0, dragY))
      .overlay(
        VerticalPanOverlay(
          onChanged: { translationY, translation in
            // Pan is direction-locked vertically by recognizer; if we get here, we can trust Y.
            let newY = max(0, translationY)
            dragY = newY

            let p = min(1, max(0, newY / height))
            // Throttle background updates to avoid frame drops
            if abs(p - lastReportedProgress) > 0.01 {  // ~1% change
              lastReportedProgress = p
              onDragProgress(p)
            }
          },
          onEnded: { translationY, velocityY, translation in
            let p = min(1, max(0, translationY / height))
            // Thresholds
            let distanceThreshold: CGFloat = 0.25  // 25% height
            let velocityThreshold: CGFloat = 900  // pts/sec

            let shouldDismiss =
              translationY > 0 && (p > distanceThreshold || velocityY > velocityThreshold)

            if shouldDismiss {
              // Snap background to fully dimmed and dismiss
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
        // Start each load un-blurred without animation
        await MainActor.run {
          withAnimation(nil) {
            isDegraded = false
          }
        }

        // Capture main-only values up-front.
        let screenScale = UIScreen.main.scale

        // Run image loading off the main thread and inherit cancellation.
        let finalImage = await Task(priority: .userInitiated) {
          await loadImage(
            uri: uri,
            size: proxy.size,
            screenScale: screenScale,
            onLoadDegraded: { degraded in
              // Hop to main for state updates.
              await MainActor.run {
                // Show degraded immediately without animating blur-in
                withAnimation(nil) {
                  isDegraded = true
                }
                self.image = degraded
              }
            }
          )
        }.value

        // Apply final result on main.
        await MainActor.run {
          if let img = finalImage {
            // Swap to hi-res, then animate un-blur only
            self.image = img
            withAnimation(.easeInOut(duration: 0.2)) {
              isDegraded = false
            }
            if !didSendLoad {
              onLoaded(index, uri)
              didSendLoad = true
            }
          }
        }
      }
    }
  }

  private func taskID(uri: String, size: CGSize) -> String {
    "\(uri)-\(Int(size.width))x\(Int(size.height))"
  }

  private func loadImage(
    uri: String,
    size: CGSize,
    screenScale: CGFloat,
    onLoadDegraded: @escaping @Sendable (UIImage) async -> Void
  ) async -> UIImage? {
    if Task.isCancelled { return nil }

    // Local file:// — decode efficiently off-main using ImageIO thumbnailing.
    if uri.hasPrefix("file://") {
      guard let url = URL(string: uri) else { return nil }

      // Use the larger dimension for maxPixelSize to maintain aspect fit at display size.
      let maxPixelSize = Int(max(size.width, size.height) * screenScale)

      if let src = CGImageSourceCreateWithURL(url as CFURL, nil) {
        let opts: [CFString: Any] = [
          kCGImageSourceShouldCache: false,
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
          kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        if let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) {
          if Task.isCancelled { return nil }
          return UIImage(cgImage: cg)
        }
      }

      // Fallback if thumbnailing fails.
      if Task.isCancelled { return nil }
      return UIImage(contentsOfFile: url.path)
    }

    // Photos ph:// — request resized image; handle degraded then full quality.
    if uri.hasPrefix("ph://") {
      let assetID = uri.replacingOccurrences(of: "ph://", with: "")
      let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)

      if let asset = assetResults.firstObject {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        options.version = .current
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        // PHImageManager expects pixel sizes; convert from points
        let targetSize = CGSize(width: size.width * screenScale, height: size.height * screenScale)

        let uiImage: UIImage? = await withCheckedContinuation { continuation in
          var didResume = false
          let _ = imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
          ) { image, info in
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
            let isCancelled = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false
            let error = info?[PHImageErrorKey] as? NSError

            if isCancelled || error != nil {
              if !didResume {
                didResume = true
                continuation.resume(returning: nil)
              }
              return
            }

            if let img = image {
              if isDegraded {
                Task {
                  await onLoadDegraded(img)  // show low-res first on main
                }
              } else if !didResume {
                didResume = true
                continuation.resume(returning: img)  // then complete with hi-res
              }
            } else if !isDegraded && !didResume {
              didResume = true
              continuation.resume(returning: nil)
            }
          }
        }
        if Task.isCancelled { return nil }
        return uiImage
      }
    }

    return nil
  }

}
