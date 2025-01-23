import type { ComponentType } from 'react';
import type { ViewProps, ViewStyle } from 'react-native';

export type ExpoSimpleGalleryModuleEvents = {};

export type ThumbnailOverlayComponentProps = {
  uri: string;
  selected: boolean;
  index: number;
};
export type ThumbnailOverlayComponent =
  ComponentType<ThumbnailOverlayComponentProps>;

export type ExpoSimpleGalleryViewProps = ViewProps & {
  assets: string[];
  columnsCount?: number;
  thumbnailsSpacing?: number;
  thumbnailStyle?: Pick<
    ViewStyle,
    'aspectRatio' | 'borderRadius' | 'borderWidth' | 'borderColor'
  >;
  thumbnailOverlayComponent?: ThumbnailOverlayComponent;
};
