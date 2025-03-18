import { requireNativeView } from 'expo';
import {
  type ComponentType,
  forwardRef,
  memo,
  type RefAttributes,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from 'react';
import {
  type ColorValue,
  type NativeSyntheticEvent,
  processColor,
  useWindowDimensions,
} from 'react-native';
import {
  type ExpoSimpleGalleryMethods,
  type ExpoSimpleGalleryViewProps,
  type GalleryItem,
  isNestedArray,
  isNotNullOrUndefined,
  type OnPreviewMenuOptionSelectedPayload,
  type UIAction,
} from './ExpoSimpleGallery.types';
import { GalleryModal } from './ExpoSimpleGalleryModal';
import { MemoizedSectionHeader } from './components/MemoizedSectionHeader';
import { MemoizedThumbnailOverlayComponent } from './components/MemoizedThumbnailOverlayComponent';

const NativeView: ComponentType<
  ExpoSimpleGalleryViewProps & RefAttributes<ExpoSimpleGalleryMethods>
> = requireNativeView('ExpoSimpleGallery');

const NativeViewMemoized = memo(NativeView);

const OVERLAYS_BUFFER = 10;

export default forwardRef<ExpoSimpleGalleryMethods, ExpoSimpleGalleryViewProps>(
  function ExpoSimpleGalleryView(
    {
      thumbnailOverlayComponent: ThumbnailOverlayComponent,
      fullscreenViewOverlayComponent: FullscreenOverlayComponent = () => null,
      sectionHeaderComponent: SectionHeaderComponent,
      sectionHeaderStyle,
      assets,
      thumbnailStyle,
      onSelectionChange,
      onOverlayPreloadRequested,
      onSectionHeadersVisible,
      debugLabels = false,
      onThumbnailPress,
      fullscreenViewOverlayStyle,
      onPreviewMenuOptionSelected,
      contextMenuOptions,
      initiallySelected,
      ...props
    }: ExpoSimpleGalleryViewProps,
    forwardedRef
  ) {
    const { width } = useWindowDimensions();
    const { thumbnailWidth, thumbnailHeight, thumbnailStyleProcessed } =
      useThumbnailDimensions({
        thumbnailStyle,
        contentContainerStyle: props.contentContainerStyle,
        columnsCount: props.columnsCount,
      });

    const openImageViewer = useCallback((index: number) => {
      setInitialIndex(index);
      setModalVisible(true);
    }, []);

    const thumbnailPressActionRef = useRef(props.thumbnailPressAction);
    useEffect(() => {
      thumbnailPressActionRef.current = props.thumbnailPressAction;
    }, [props.thumbnailPressAction]);

    const internalRef = useRef<ExpoSimpleGalleryMethods>(null);
    useImperativeHandle(forwardedRef, () => ({
      centerOnIndex: async (index: number) => {
        internalRef.current?.centerOnIndex(index);
      },
      setSelected: async (uris: string[]) => {
        internalRef.current?.setSelected(uris);
      },
      setThumbnailPressAction: async (
        action: ExpoSimpleGalleryViewProps['thumbnailPressAction']
      ) => {
        thumbnailPressActionRef.current = action;
        internalRef.current?.setThumbnailPressAction(action);
      },
      setThumbnailLongPressAction: async (
        action: ExpoSimpleGalleryViewProps['thumbnailLongPressAction']
      ) => {
        internalRef.current?.setThumbnailLongPressAction(action);
      },
      setThumbnailPanAction: async (
        action: ExpoSimpleGalleryViewProps['thumbnailPanAction']
      ) => {
        internalRef.current?.setThumbnailPanAction(action);
      },
      setContextMenuOptions: async (options: UIAction[]) => {
        internalRef.current?.setContextMenuOptions(options);
      },
      openImageViewer,
      closeImageViewer: () => {
        setModalVisible(false);
      },
    }));

    const [modalVisible, setModalVisible] = useState(false);
    const [initialIndex, setInitialIndex] = useState(0);

    const [selectedUris, setSelectedUris] = useState<Set<string>>(new Set());

    const [visibleRange, setVisibleRange] = useState<[number, number]>([0, 0]);
    const visibleRangeMin = useMemo(() => visibleRange[0], [visibleRange]);
    const visibleRangeMax = useMemo(() => visibleRange[1], [visibleRange]);

    const [visibleHeaders, setVisibleHeaders] = useState<number[]>([0]);
    const visibleHeadersRangeMin = useMemo(
      () => Math.min(...visibleHeaders),
      [visibleHeaders]
    );
    const visibleHeadersRangeMax = useMemo(
      () => Math.max(...visibleHeaders),
      [visibleHeaders]
    );

    const handleSelectionChange = useCallback(
      (event: NativeSyntheticEvent<{ selected: string[] }>) => {
        setSelectedUris(new Set(event.nativeEvent.selected));
        onSelectionChange?.(event);
      },
      [onSelectionChange]
    );

    const handleOverlayPreloadRequest = useCallback(
      (event: NativeSyntheticEvent<{ range: [number, number] }>) => {
        const [start, end] = event.nativeEvent.range;
        setVisibleRange([start, end]);
        onOverlayPreloadRequested?.(event);
      },
      [onOverlayPreloadRequested]
    );

    const handleSectionHeadersVisible = useCallback(
      (event: NativeSyntheticEvent<{ sections: number[] }>) => {
        setVisibleHeaders(event.nativeEvent.sections);
        onSectionHeadersVisible?.(event);
      },
      [onSectionHeadersVisible]
    );

    const handleThumbnailPress = useCallback(
      (event: NativeSyntheticEvent<GalleryItem>) => {
        if (thumbnailPressActionRef.current === 'open') {
          openImageViewer(event.nativeEvent.index);
        }
        onThumbnailPress?.(event);
      },
      [onThumbnailPress, openImageViewer]
    );

    const handleModalClose = useCallback(
      (event: NativeSyntheticEvent<GalleryItem>) => {
        internalRef.current?.centerOnIndex(event.nativeEvent.index);
        setModalVisible(false);
      },
      []
    );

    const thumbnailOverlays = useMemo(
      () =>
        assets.flat().map((uri, index) =>
          ThumbnailOverlayComponent ? (
            <MemoizedThumbnailOverlayComponent
              key={uri}
              OverlayComponent={ThumbnailOverlayComponent}
              uri={uri}
              index={index}
              width={thumbnailWidth}
              height={thumbnailHeight}
              selected={selectedUris.has(uri)}
              debugLabels={debugLabels}
              isNull={
                !(
                  index >= visibleRangeMin - OVERLAYS_BUFFER &&
                  index <= visibleRangeMax + OVERLAYS_BUFFER
                )
              }
              // isNull={false}
            />
          ) : null
        ),
      [
        assets,
        ThumbnailOverlayComponent,
        thumbnailWidth,
        thumbnailHeight,
        selectedUris,
        visibleRangeMin,
        visibleRangeMax,
        debugLabels,
      ]
    );

    const sectionHeaders = useMemo(() => {
      if (!SectionHeaderComponent || !isNestedArray(assets)) return null;
      return assets.map((group, index) => (
        <MemoizedSectionHeader
          key={JSON.stringify(group)}
          SectionHeader={SectionHeaderComponent}
          index={index}
          width={width}
          height={Number.parseFloat(
            (sectionHeaderStyle?.height ?? 0).toString()
          )}
          debugLabels={debugLabels}
          isNull={
            !(
              index >= visibleHeadersRangeMin - OVERLAYS_BUFFER &&
              index <= visibleHeadersRangeMax + OVERLAYS_BUFFER
            )
          }
        />
      ));
    }, [
      SectionHeaderComponent,
      assets,
      sectionHeaderStyle?.height,
      debugLabels,
      width,
      visibleHeadersRangeMin,
      visibleHeadersRangeMax,
    ]);

    const children = useMemo(
      () => [sectionHeaders, thumbnailOverlays],
      [sectionHeaders, thumbnailOverlays]
    );

    const handlePreviewMenuOptionSelected = useCallback(
      (event: NativeSyntheticEvent<OnPreviewMenuOptionSelectedPayload>) => {
        const action =
          contextMenuOptions?.[event.nativeEvent.optionIndex]?.action;
        action?.({
          uri: event.nativeEvent.uri,
          index: event.nativeEvent.index,
        });
      },
      [contextMenuOptions]
    );

    const handleToggleSelection = useCallback(
      (uri: string, selected?: boolean) => {
        const shouldSetSelected =
          selected === undefined ? !selectedUris.has(uri) : selected;
        const newSet = new Set(selectedUris);
        if (shouldSetSelected) {
          newSet.add(uri);
        } else {
          newSet.delete(uri);
        }
        internalRef.current?.setSelected([...newSet]);
      },
      [selectedUris]
    );

    return (
      <>
        <NativeViewMemoized
          {...props}
          thumbnailStyle={thumbnailStyleProcessed}
          sectionHeaderStyle={sectionHeaderStyle}
          assets={assets}
          onSelectionChange={handleSelectionChange}
          onOverlayPreloadRequested={handleOverlayPreloadRequest}
          onSectionHeadersVisible={handleSectionHeadersVisible}
          onThumbnailPress={handleThumbnailPress}
          onPreviewMenuOptionSelected={handlePreviewMenuOptionSelected}
          contextMenuOptions={contextMenuOptions}
          onLayout={() => {
            if (initiallySelected) {
              internalRef.current?.setSelected(
                initiallySelected?.filter(isNotNullOrUndefined)
              );
            }
          }}
          ref={internalRef}
        >
          {/* @ts-expect-error type of children is intentionally set to never | undefined */}
          {children}
        </NativeViewMemoized>
        <GalleryModal
          visible={modalVisible}
          uris={assets.flat()}
          initialIndex={initialIndex}
          onClose={handleModalClose}
          selectedUris={selectedUris}
          overlayComponent={FullscreenOverlayComponent}
          style={fullscreenViewOverlayStyle}
          toggleSelection={handleToggleSelection}
        />
      </>
    );
  }
);

function useThumbnailDimensions({
  thumbnailStyle,
  contentContainerStyle,
  columnsCount = 2,
}: {
  thumbnailStyle: ExpoSimpleGalleryViewProps['thumbnailStyle'];
  contentContainerStyle: ExpoSimpleGalleryViewProps['contentContainerStyle'];
  columnsCount?: number;
}) {
  const { width } = useWindowDimensions();
  const thumbnailStyleProcessed = useMemo(() => {
    if (!thumbnailStyle?.borderColor) return thumbnailStyle;
    const { borderColor } = thumbnailStyle;
    return {
      ...thumbnailStyle,
      borderColor: (processColor(borderColor) as ColorValue) ?? undefined,
    };
  }, [thumbnailStyle]);
  const { thumbnailWidth, thumbnailHeight } = useMemo(() => {
    const thumbnailAspectRatio =
      Number.parseFloat(
        (thumbnailStyleProcessed?.aspectRatio as string) ?? ''
      ) || 1;

    const thumbnailsSpacing = contentContainerStyle?.gap
      ? Number.parseInt(contentContainerStyle?.gap.toString())
      : 0;
    const paddingLeft =
      contentContainerStyle?.paddingLeft ??
      contentContainerStyle?.paddingHorizontal ??
      contentContainerStyle?.padding ??
      0;
    const paddingRight =
      contentContainerStyle?.paddingRight ??
      contentContainerStyle?.paddingHorizontal ??
      contentContainerStyle?.padding ??
      0;
    const padding =
      Number.parseFloat(paddingLeft as string) +
      Number.parseFloat(paddingRight as string);
    const thumbnailWidth =
      (width - padding - (columnsCount - 1) * thumbnailsSpacing) / columnsCount;
    const thumbnailHeight = thumbnailWidth / thumbnailAspectRatio;
    return { thumbnailWidth, thumbnailHeight };
  }, [width, thumbnailStyleProcessed, columnsCount, contentContainerStyle]);
  return { thumbnailWidth, thumbnailHeight, thumbnailStyleProcessed };
}
