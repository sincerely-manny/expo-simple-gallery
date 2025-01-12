import { NativeModule, requireNativeModule } from 'expo';

import { ExpoSimpleGalleryModuleEvents } from './ExpoSimpleGallery.types';

declare class ExpoSimpleGalleryModule extends NativeModule<ExpoSimpleGalleryModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoSimpleGalleryModule>('ExpoSimpleGallery');
