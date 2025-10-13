import PhotosUI
import SwiftUI

struct LivePhotoView: UIViewRepresentable {
  var livePhoto: PHLivePhoto?
  var isMuted: Bool = true
  var play: Bool = true

  func makeUIView(context: Context) -> PHLivePhotoView {
    let v = PHLivePhotoView()
    v.contentMode = .scaleAspectFit
    v.clipsToBounds = true
    v.isMuted = isMuted
    v.livePhoto = livePhoto
    if play, livePhoto != nil {
      v.startPlayback(with: .full)
    }
    return v
  }

  func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
    uiView.isMuted = isMuted
    if uiView.livePhoto !== livePhoto {
      uiView.livePhoto = livePhoto
      if play, livePhoto != nil {
        uiView.startPlayback(with: .full)
      }
    }
  }
}
