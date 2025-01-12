import * as React from 'react';

import { ExpoSimpleGalleryViewProps } from './ExpoSimpleGallery.types';

export default function ExpoSimpleGalleryView(props: ExpoSimpleGalleryViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
