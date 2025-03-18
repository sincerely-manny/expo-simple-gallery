// MARK: - UIGestureRecognizerDelegate
extension ImagePageViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer === panGesture {
      if scrollView.zoomScale > scrollView.minimumZoomScale {
        return false
      }

      let velocity = panGesture.velocity(in: view)
      let isScrolledToTop = scrollView.contentOffset.y <= 0
      let isMainlyVertical = abs(velocity.y) > abs(velocity.x) * 1.5

      return isScrolledToTop && velocity.y > 0 && isMainlyVertical
    }
    return true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    // Allow simultaneous recognition with scrollView's pan gesture
    if gestureRecognizer === panGesture && otherGestureRecognizer === scrollView.panGestureRecognizer {
      return true
    }

    if otherGestureRecognizer.view?.next is UIPageViewController {
      let velocity = panGesture.velocity(in: view)

      // If the gesture has a significant horizontal component, let the page view controller handle it
      if abs(velocity.x) > abs(velocity.y) * 0.8 {
        return false  // Don't recognize our gesture, let page controller take it
      }
    }

    return false
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    // Let page view controller's gesture recognizer take priority for horizontal swipes
    if gestureRecognizer === panGesture && otherGestureRecognizer.view?.next is UIPageViewController {
      let velocity = panGesture.velocity(in: view)
      return abs(velocity.x) > abs(velocity.y) * 0.8
    }
    return false
  }
}
