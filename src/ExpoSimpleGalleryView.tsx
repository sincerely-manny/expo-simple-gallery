import { requireNativeView } from 'expo';
import { memo, useCallback, useMemo, useState } from 'react';
import {
  type ColorValue,
  type NativeSyntheticEvent,
  Text,
  View,
  processColor,
  useWindowDimensions,
} from 'react-native';
import type {
  ExpoSimpleGalleryViewProps,
  ThumbnailOverlayComponent,
} from './ExpoSimpleGallery.types';

const NativeView: React.ComponentType<ExpoSimpleGalleryViewProps> =
  requireNativeView('ExpoSimpleGallery');

const NativeViewMemoized = memo(NativeView);

const MemoizedOverlayComponent = memo(
  function MemoizedOverlayComponent({
    OverlayComponent,
    uri,
    index,
    width,
    height,
    selected,
    isNull,
  }: {
    OverlayComponent: ThumbnailOverlayComponent;
    uri: string;
    index: number;
    width: number;
    height: number;
    selected: boolean;
    isNull: boolean;
  }) {
    const style = useMemo(
      () => ({ position: 'absolute', width, height }) as const,
      [width, height]
    );
    if (isNull) return null;

    return (
      <View
        style={style}
        nativeID="ExpoSimpleGalleryView"
        collapsable={false}
        accessibilityLabel={`GalleryViewOverlay_${index}`}
      >
        <Text style={{ backgroundColor: 'red', textAlign: 'center' }}>
          {index}
        </Text>
        <OverlayComponent selected={selected} uri={uri} index={index} />
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
  onSelectionChange,
  onOverlayPreloadRequested,
  ...props
}: ExpoSimpleGalleryViewProps) {
  const thumbnailStyleProcessed = useMemo(() => {
    if (!thumbnailStyle?.borderColor) return thumbnailStyle;
    const { borderColor } = thumbnailStyle;
    return {
      ...thumbnailStyle,
      borderColor: (processColor(borderColor) as ColorValue) ?? undefined,
    };
  }, [thumbnailStyle]);

  const { width } = useWindowDimensions();
  const { thumbnailWidth, thumbnailHeight } = useMemo(() => {
    const thumbnailAspectRatio =
      Number.parseFloat(
        (thumbnailStyleProcessed?.aspectRatio as string) ?? ''
      ) || 1;
    const columnsCount = props.columnsCount ?? 2;
    const thumbnailsSpacing = props.thumbnailsSpacing ?? 0;
    const paddingLeft =
      props.contentContainerStyle?.paddingLeft ??
      props.contentContainerStyle?.paddingHorizontal ??
      props.contentContainerStyle?.padding ??
      0;
    const paddingRight =
      props.contentContainerStyle?.paddingRight ??
      props.contentContainerStyle?.paddingHorizontal ??
      props.contentContainerStyle?.padding ??
      0;
    const padding =
      Number.parseFloat(paddingLeft as string) +
      Number.parseFloat(paddingRight as string);
    const thumbnailWidth =
      (width - padding - (columnsCount - 1) * thumbnailsSpacing) / columnsCount;
    const thumbnailHeight = thumbnailWidth / thumbnailAspectRatio;
    return { thumbnailWidth, thumbnailHeight };
  }, [
    width,
    thumbnailStyleProcessed,
    props.columnsCount,
    props.thumbnailsSpacing,
    props.contentContainerStyle,
  ]);

  const [selectedUris, setSelectedUris] = useState<Set<string>>(new Set());
  const [visibleRange, setVisibleRange] = useState<[number, number]>([0, 0]);
  const visibleRangeMin = useMemo(() => visibleRange[0], [visibleRange]);
  const visibleRangeMax = useMemo(() => visibleRange[1], [visibleRange]);

  const handleSelectionChange = useCallback(
    (event: NativeSyntheticEvent<{ selected: string[] }>) => {
      setSelectedUris(new Set(event.nativeEvent.selected));
      onSelectionChange?.(event);
    },
    [onSelectionChange]
  );

  const handleOverlayPreloadRequest = useCallback(
    (event: NativeSyntheticEvent<{ range: [number, number] }>) => {
      console.log('handleOverlayPreloadRequest', event.nativeEvent.range);
      const [start, end] = event.nativeEvent.range;
      setVisibleRange([start, end]);
      onOverlayPreloadRequested?.(event);
    },
    [onOverlayPreloadRequested]
  );

  // return null;
  return (
    <NativeViewMemoized
      {...props}
      thumbnailStyle={thumbnailStyleProcessed}
      assets={assets}
      onSelectionChange={handleSelectionChange}
      onOverlayPreloadRequested={handleOverlayPreloadRequest}
    >
      {/* {overlaysToRender} */}
      {/* @ts-expect-error type of children is intentionally set to never | undefined */}
      {assets.map((uri, index) =>
        OverlayComponent ? (
          <MemoizedOverlayComponent
            key={uri}
            OverlayComponent={OverlayComponent}
            uri={uri}
            index={index}
            width={thumbnailWidth}
            height={thumbnailHeight}
            selected={selectedUris.has(uri)}
            isNull={
              !(index >= visibleRangeMin - 30 && index <= visibleRangeMax + 30)
            }
            // isNull={false}
          />
        ) : null
      )}
    </NativeViewMemoized>
  );
}
