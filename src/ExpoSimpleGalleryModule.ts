import { NativeModule, requireNativeModule } from 'expo';
import type { ExpoSimpleGalleryModuleEvents } from './ExpoSimpleGallery.types';

declare class ExpoSimpleGalleryModule extends NativeModule<ExpoSimpleGalleryModuleEvents> {}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoSimpleGalleryModule>(
  'ExpoSimpleGallery'
);
