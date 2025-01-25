import { requireNativeView } from 'expo';
import { memo, useCallback, useMemo, useState } from 'react';
import {
  type ColorValue,
  type NativeSyntheticEvent,
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
    // selectedUris,
    selected,
  }: {
    OverlayComponent: ThumbnailOverlayComponent;
    uri: string;
    index: number;
    width: number;
    height: number;
    selected: boolean;
  }) {
    const style = useMemo(
      () => ({ position: 'absolute', width, height }) as const,
      [width, height]
    );
    return (
      <View style={style} nativeID="ExpoSimpleGalleryView" collapsable={false}>
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

  const handleSelectionChange = useCallback(
    (event: NativeSyntheticEvent<{ selected: string[] }>) => {
      setSelectedUris(new Set(event.nativeEvent.selected));
      onSelectionChange?.(event);
    },
    [onSelectionChange]
  );

  return (
    <NativeViewMemoized
      {...props}
      thumbnailStyle={thumbnailStyleProcessed}
      assets={assets}
      onSelectionChange={handleSelectionChange}
    >
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
          />
        ) : null
      )}
    </NativeViewMemoized>
  );
}
