import ExpoModulesCore

public class ExpoSimpleGalleryModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoSimpleGallery")
    View(ExpoSimpleGalleryView.self) {

    }
  }
}
