protocol ImagePageViewControllerDelegate: MediaViewControllerDelegate {
  func imagePageViewController(_ controller: ImagePageViewController, didLoadHighQualityImage uri: String)
}
