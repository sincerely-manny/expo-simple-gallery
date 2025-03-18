// MARK: - UIScrollViewDelegate
extension ImagePageViewController: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }

  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    // Center the image in the scroll view when zooming
    centerScrollViewContents()
  }

  func centerScrollViewContents() {
    let boundsSize = scrollView.bounds.size
    var contentFrame = imageView.frame

    // Center horizontally
    if contentFrame.size.width < boundsSize.width {
      contentFrame.origin.x = (boundsSize.width - contentFrame.size.width) / 2.0
    } else {
      contentFrame.origin.x = 0
    }

    // Center vertically
    if contentFrame.size.height < boundsSize.height {
      contentFrame.origin.y = (boundsSize.height - contentFrame.size.height) / 2.0
    } else {
      contentFrame.origin.y = 0
    }

    imageView.frame = contentFrame
  }
}
