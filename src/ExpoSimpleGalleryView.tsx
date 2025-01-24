import { requireNativeView } from 'expo';
import { memo, useMemo } from 'react';
import { type ColorValue, StyleSheet, View, processColor } from 'react-native';
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
  }
  // (prevProps, nextProps) =>
  //   prevProps.uri === nextProps.uri && prevProps.index === nextProps.index
);

export default function ExpoSimpleGalleryView({
  thumbnailOverlayComponent: OverlayComponent,
  assets,
  thumbnailStyle,
  ...props
}: ExpoSimpleGalleryViewProps) {
  const thumbnailStyleProcessed = useMemo(() => {
    // return thumbnailStyle;
    if (!thumbnailStyle?.borderColor) return thumbnailStyle;
    const { borderColor } = thumbnailStyle;
    return {
      ...thumbnailStyle,
      borderColor: (processColor(borderColor) as ColorValue) ?? undefined,
    };
  }, [thumbnailStyle]);
  return (
    <NativeView
      {...props}
      thumbnailStyle={thumbnailStyleProcessed}
      assets={assets}
    >
      {/* @ts-expect-error type of children is intentionally set to never | undefined */}
      {assets.map((uri, index) =>
        OverlayComponent ? (
          <MemoizedOverlayComponent
            key={uri}
            OverlayComponent={OverlayComponent}
            uri={uri}
            index={index}
          />
        ) : null
      )}
    </NativeView>
  );
}

const style = StyleSheet.create({
  overlay: { borderWidth: 0, width: '100%', height: '100%' },
});
