import SwiftUI

final class SwiftUIGalleryViewModel: ObservableObject {
  @Published var uris: [String] = []
  @Published var index: Int = 0
}

struct SwiftUIGalleryView: View {
  @ObservedObject var viewModel: SwiftUIGalleryViewModel

  var onPageChange: (Int, String) -> Void
  var onImageLoaded: (Int, String) -> Void
  var onDismissAttempt: () -> Void

  @State private var backgroundOpacity: Double = 1.0
  var body: some View {
    ZStack {
      Color.black
        .opacity(backgroundOpacity)
        .ignoresSafeArea()

      if viewModel.uris.isEmpty {
        Color.black.ignoresSafeArea()
      } else {
        TabView(selection: $viewModel.index) {
          ForEach(viewModel.uris.indices, id: \.self) { i in
            PageImageView(
              uri: viewModel.uris[i],
              index: i,
              onLoaded: onImageLoaded,
              onDismiss: onDismissAttempt,
              onDragProgress: { progress in
              }
            )
            .tag(i)
            .background(Color.black)
            .ignoresSafeArea()
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .onChange(of: viewModel.index) { newIndex in
          guard newIndex >= 0, newIndex < viewModel.uris.count else { return }
          onPageChange(newIndex, viewModel.uris[newIndex])
        }
      }
    }
    .contentShape(Rectangle())
  }
}
