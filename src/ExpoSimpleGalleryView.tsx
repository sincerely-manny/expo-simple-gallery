import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoSimpleGalleryViewProps } from './ExpoSimpleGallery.types';

const NativeView: React.ComponentType<ExpoSimpleGalleryViewProps> =
  requireNativeView('ExpoSimpleGallery');

export default function ExpoSimpleGalleryView(props: ExpoSimpleGalleryViewProps) {
  return <NativeView {...props} />;
}
