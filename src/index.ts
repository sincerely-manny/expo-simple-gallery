// Reexport the native module. On web, it will be resolved to ExpoSimpleGalleryModule.web.ts
// and on native platforms to ExpoSimpleGalleryModule.ts
export { default } from './ExpoSimpleGalleryModule';
export { default as ExpoSimpleGalleryView } from './ExpoSimpleGalleryView';
export * from  './ExpoSimpleGallery.types';
