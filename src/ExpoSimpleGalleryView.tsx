import { requireNativeView } from 'expo';
import type { ExpoSimpleGalleryViewProps } from './ExpoSimpleGallery.types';

const NativeView: React.ComponentType<ExpoSimpleGalleryViewProps> =
  requireNativeView('ExpoSimpleGallery');

export default function ExpoSimpleGalleryView({
  thumbnailOverlayComponent: OverlayComponent,
  assets,
  ...props
}: ExpoSimpleGalleryViewProps) {
  return (
    <NativeView {...props} assets={assets}>
      {assets.map((uri, index) =>
        OverlayComponent ? (
          // <View
          //   style={{ borderWidth: 0, width: '100%', height: '100%' }}
          //   key={uri}
          //   nativeID="nativeID"
          // >
          <OverlayComponent
            selected={false}
            uri={uri}
            index={index}
            key={uri}
          />
          // </View>
        ) : null
      )}
    </NativeView>
  );
}
