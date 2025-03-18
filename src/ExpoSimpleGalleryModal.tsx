import { requireNativeView } from 'expo';
import { type ComponentType, useCallback, useMemo, useState } from 'react';
import {
  Modal,
  type NativeSyntheticEvent,
  StyleSheet,
  View,
} from 'react-native';
import type { GalleryItem } from './ExpoSimpleGallery.types';
import type {
  GalleryModalProps,
  GalleryViewerProps,
} from './ExpoSimpleGalleryModal.types';

const GalleryViewer: ComponentType<GalleryViewerProps> =
  requireNativeView('GalleryImageViewer');

export function GalleryModal({
  visible,
  uris,
  initialIndex = 0,
  onClose,
  overlayComponent: OverlayComponent,
  selectedUris,
  style,
  toggleSelection,
}: GalleryModalProps) {
  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const [currentUri, setCurrentUri] = useState(uris[initialIndex] || '');
  const selected = useMemo(
    () => selectedUris.has(currentUri),
    [selectedUris, currentUri]
  );

  const handlePageChange = useCallback(
    (event: NativeSyntheticEvent<{ index: number; uri: string }>) => {
      const { index, uri } = event.nativeEvent;
      setCurrentIndex(index);
      setCurrentUri(uri);
    },
    []
  );

  const handleDismissAttempt = useCallback(
    (event: NativeSyntheticEvent<GalleryItem>) => {
      onClose(event);
    },
    [onClose]
  );

  const handleSelectionToggle = useCallback(
    (selected?: boolean) => {
      toggleSelection(currentUri, selected);
    },
    [currentUri, toggleSelection]
  );

  return (
    <Modal
      visible={visible}
      transparent={true}
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={[styles.container, style]}>
        <GalleryViewer
          style={styles.viewer}
          imageData={{ uris, startIndex: initialIndex }}
          onPageChange={handlePageChange}
          onDismissAttempt={handleDismissAttempt}
        />

        {OverlayComponent && (
          <View style={styles.overlayContainer} pointerEvents="box-none">
            <OverlayComponent
              index={currentIndex}
              uri={currentUri}
              selected={selected}
              toggleSelection={handleSelectionToggle}
            />
          </View>
        )}
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'black',
  },
  viewer: {
    flex: 1,
  },
  overlayContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
});
