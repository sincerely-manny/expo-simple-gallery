import { memo, useMemo } from 'react';
import { Text, View } from 'react-native';
import type { ThumbnailOverlayComponent } from '../ExpoSimpleGallery.types';

export const MemoizedThumbnailOverlayComponent = memo(function MemoizedThumbnailOverlayComponent({
  OverlayComponent,
  uri,
  index,
  width,
  height,
  selected,
  isNull,
  debugLabels,
}: {
  OverlayComponent: ThumbnailOverlayComponent;
  uri: string;
  index: number;
  width: number;
  height: number;
  selected: boolean;
  isNull: boolean;
  debugLabels: boolean;
}) {
  const style = useMemo(() => ({ position: 'absolute', width, height }) as const, [width, height]);
  if (isNull) return null;

  return (
    <View
      style={style}
      nativeID={`GalleryViewOverlay_${index}`}
      collapsable={false}
      accessibilityLabel={`GalleryViewOverlay_${index}`}
    >
      {debugLabels && <Text style={{ backgroundColor: 'red', textAlign: 'center' }}>{index}</Text>}
      <OverlayComponent selected={selected} uri={uri} index={index} />
    </View>
  );
});
