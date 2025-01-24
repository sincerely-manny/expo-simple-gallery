import { requireNativeView } from 'expo';
import { memo } from 'react';
import { StyleSheet, View } from 'react-native';
import type {
  ExpoSimpleGalleryViewProps,
  ThumbnailOverlayComponent,
} from './ExpoSimpleGallery.types';

const NativeView: React.ComponentType<ExpoSimpleGalleryViewProps> =
  requireNativeView('ExpoSimpleGallery');

const MemoizedOverlayComponent = memo(
  function MemoizedOverlayComponent({
    OverlayComponent,
    uri,
    index,
  }: {
    OverlayComponent: ThumbnailOverlayComponent;
    uri: string;
    index: number;
  }) {
    return (
      <View style={style.overlay} nativeID="ExpoSimpleGalleryView">
        <OverlayComponent selected={false} uri={uri} index={index} />
      </View>
    );
  },
  (prevProps, nextProps) =>
    prevProps.uri === nextProps.uri && prevProps.index === nextProps.index
);

export default function ExpoSimpleGalleryView({
  thumbnailOverlayComponent: OverlayComponent,
  assets,
  ...props
}: ExpoSimpleGalleryViewProps) {
  return (
    <NativeView {...props} assets={assets}>
      {assets.map((uri, index) =>
        OverlayComponent ? (
          <View
            style={style.overlay}
            nativeID="ExpoSimpleGalleryView"
            key={uri}
          >
            <OverlayComponent selected={false} uri={uri} index={index} />
          </View>
        ) : null
      )}
    </NativeView>
  );
}

const style = StyleSheet.create({
  overlay: { borderWidth: 0, width: '100%', height: '100%' },
});
