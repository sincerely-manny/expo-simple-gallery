import type { ComponentType } from 'react';
import type { NativeSyntheticEvent, ViewProps, ViewStyle } from 'react-native';
import type { SFSymbol } from './SfSymbol.types';

export type GalleryItem = {
  uri: string;
  index: number;
};

export type OnPreviewMenuOptionSelectedPayload = {
  uri: string;
  index: number;
  optionIndex: number;
};

export type ExpoSimpleGalleryModuleEvents = {
  onSelectionChange?: (
    event: NativeSyntheticEvent<{ selected: string[] }>
  ) => void;
  onThumbnailPress?: (event: NativeSyntheticEvent<GalleryItem>) => void;
  onThumbnailLongPress?: (event: NativeSyntheticEvent<GalleryItem>) => void;
  onOverlayPreloadRequested?: (
    event: NativeSyntheticEvent<{ range: [number, number] }>
  ) => void;
  onSectionHeadersVisible?: (
    event: NativeSyntheticEvent<{ sections: number[] }>
  ) => void;
  onPreviewMenuOptionSelected?: (
    event: NativeSyntheticEvent<OnPreviewMenuOptionSelectedPayload>
  ) => void;
};

export type ThumbnailOverlayComponentProps = {
  uri: string;
  index: number;
  selected: boolean;
};
export type ThumbnailOverlayComponent =
  ComponentType<ThumbnailOverlayComponentProps>;

export type SectionHeaderComponentProps = {
  index: number;
};
export type SectionHeaderComponent = ComponentType<SectionHeaderComponentProps>;

export type ThumbnailPressAction = 'select' | 'open' | 'preview' | 'none';

export type FullscreenViewOverlayComponentProps = {
  uri: string;
  index: number;
  selected: boolean;
  toggleSelection: (selected?: boolean) => void;
};
export type FullscreenViewOverlayComponent =
  ComponentType<FullscreenViewOverlayComponentProps>;

export type ExpoSimpleGalleryViewProps = ViewProps & {
  assets: string[] | string[][];
  columnsCount?: number;

  thumbnailStyle?: Pick<
    ViewStyle,
    'aspectRatio' | 'borderRadius' | 'borderWidth' | 'borderColor'
  >;
  thumbnailOverlayComponent?: ThumbnailOverlayComponent;

  thumbnailPressAction?: 'select' | 'open' | 'none';
  thumbnailLongPressAction?: 'select' | 'open' | 'preview' | 'none';
  thumbnailPanAction?: 'select' | 'none';

  fullscreenViewOverlayComponent?: FullscreenViewOverlayComponent;
  fullscreenViewOverlayStyle?: ViewStyle;

  sectionHeaderComponent?: SectionHeaderComponent;
  sectionHeaderStyle?: Pick<ViewStyle, 'height'>;

  contentContainerStyle?: Pick<
    ViewStyle,
    | 'padding'
    | 'paddingHorizontal'
    | 'paddingVertical'
    | 'paddingTop'
    | 'paddingBottom'
    | 'paddingLeft'
    | 'paddingRight'
    | 'gap'
  >;

  children?: never;

  contextMenuOptions?: UIAction[];

  initiallySelected?: (string | undefined)[];

  showMediaTypeIcon?: boolean;

  debugLabels?: boolean;
} & ExpoSimpleGalleryModuleEvents;

export interface ExpoSimpleGalleryMethods {
  centerOnIndex: (index: number) => Promise<void>;
  setSelected: (uris: string[]) => Promise<void>;
  setThumbnailPressAction: (
    action: ExpoSimpleGalleryViewProps['thumbnailPressAction']
  ) => Promise<void>;
  setThumbnailLongPressAction: (
    action: ExpoSimpleGalleryViewProps['thumbnailLongPressAction']
  ) => Promise<void>;
  setThumbnailPanAction: (
    action: ExpoSimpleGalleryViewProps['thumbnailPanAction']
  ) => Promise<void>;
  setContextMenuOptions: (options: UIAction[]) => void;
  openImageViewer: (index: number) => void;
  closeImageViewer: () => void;
}

type UIMenuElementAttribute = 'disabled' | 'destructive' | 'hidden';
type UIMenuElementState = 'on' | 'off' | 'mixed';

export type UIAction = {
  title: string;
  /**
   * @see https://developer.apple.com/sf-symbols/
   */
  sfSymbol?: SFSymbol;
  action?: (item: GalleryItem) => void;
  attributes?: UIMenuElementAttribute[];
  state?: UIMenuElementState;
};

export function isNestedArray<T>(value: unknown): value is T[][] {
  return Array.isArray(value) && Array.isArray(value[0]);
}

export function isNotNullOrUndefined<T>(value: T): value is NonNullable<T> {
  return value !== null && value !== undefined;
}
