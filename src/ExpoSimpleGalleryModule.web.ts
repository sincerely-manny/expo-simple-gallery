import { registerWebModule, NativeModule } from 'expo';

import { ExpoSimpleGalleryModuleEvents } from './ExpoSimpleGallery.types';

class ExpoSimpleGalleryModule extends NativeModule<ExpoSimpleGalleryModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoSimpleGalleryModule);
