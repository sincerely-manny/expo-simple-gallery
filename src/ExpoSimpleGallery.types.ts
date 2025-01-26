import type { ComponentType } from 'react';
import type { NativeSyntheticEvent, ViewProps, ViewStyle } from 'react-native';

type PressedCell = {
  uri: string;
  index: number;
};

export type ExpoSimpleGalleryModuleEvents = {
  onSelectionChange?: (
    event: NativeSyntheticEvent<{ selected: string[] }>
  ) => void;
  onThumbnailPress?: (event: NativeSyntheticEvent<PressedCell>) => void;
  onThumbnailLongPress?: (event: NativeSyntheticEvent<PressedCell>) => void;
  onOverlayPreloadRequested?: (
    event: NativeSyntheticEvent<{ range: [number, number] }>
  ) => void;
};

export type ThumbnailOverlayComponentProps = {
  uri: string;
  selected: boolean;
  index: number;
};
export type ThumbnailOverlayComponent =
  ComponentType<ThumbnailOverlayComponentProps>;

export type ThumbnailPressAction = 'select' | 'open' | 'preview' | 'none';

export type ExpoSimpleGalleryViewProps = ViewProps & {
  assets: string[];
  columnsCount?: number;

  thumbnailsSpacing?: number;
  thumbnailStyle?: Pick<
    ViewStyle,
    'aspectRatio' | 'borderRadius' | 'borderWidth' | 'borderColor'
  >;
  thumbnailOverlayComponent?: ThumbnailOverlayComponent;

  thumbnailPressAction?: ThumbnailPressAction;
  thumbnailLongPressAction?: ThumbnailPressAction;

  contentContainerStyle?: Pick<
    ViewStyle,
    | 'padding'
    | 'paddingHorizontal'
    | 'paddingVertical'
    | 'paddingTop'
    | 'paddingBottom'
    | 'paddingLeft'
    | 'paddingRight'
  >;

  children?: never;
} & ExpoSimpleGalleryModuleEvents;
