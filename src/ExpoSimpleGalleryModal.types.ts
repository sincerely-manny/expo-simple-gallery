import type { NativeSyntheticEvent, StyleProp, ViewStyle } from 'react-native';
import type {
  FullscreenViewOverlayComponent,
  GalleryItem,
} from './ExpoSimpleGallery.types';

export type GalleryViewerProps = {
  imageData: {
    uris: string[];
    startIndex: number;
  };
  onPageChange?: (event: NativeSyntheticEvent<GalleryItem>) => void;
  onImageLoaded?: (event: NativeSyntheticEvent<GalleryItem>) => void;
  onDismissAttempt?: (event: NativeSyntheticEvent<GalleryItem>) => void;
  style?: StyleProp<ViewStyle>;
};

export type GalleryModalProps = {
  visible: boolean;
  uris: string[];
  initialIndex: number;
  onClose: (event: NativeSyntheticEvent<GalleryItem>) => void;
  overlayComponent?: FullscreenViewOverlayComponent;
  selectedUris: Set<string>;
  style?: StyleProp<ViewStyle>;
};
