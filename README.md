## Overview

ExpoSimpleGallery is a high-performance image gallery module for iOS Expo applications. It provides a native implementation of image grid views with various customization options and interactive features.

## Motivation

ExpoSimpleGallery addresses common challenges in displaying image collections in React Native iOS applications. Standard React Native image components can struggle with performance when rendering multiple high-resolution images, especially in grid layouts with scrolling and selection capabilities. This module bridges this gap by providing a native iOS implementation that leverages UICollectionView and the Photos framework, offering better memory management and more responsive user interactions. By handling image loading, caching, and rendering on the native side rather than through the JavaScript bridge, ExpoSimpleGallery helps reduce common performance bottlenecks in image-heavy applications. The module supports practical features like image selection, context menus, and customizable layouts while maintaining excellent scroll performance.

## Implementation
React components are dynamically mounted to native cell containers only when they become visible. The library passes information about visible ranges to JavaScript, allowing React to prepare components only for items in or near the viewport. For grouped layouts, additional section header mounting logic ensures that headers appear and disappear appropriately during scrolling. This implementation minimizes the number of simultaneously mounted React components while maintaining a responsive user experience, even with large image collections.

## Requirements

- ⚠️ iOS 15.1+ only
- ⚠️ New architecture (Fabric) only
- ⚠️ Expo SDK 52+

## Installation

```bash
npm install expo-simple-gallery
npx pod-install
```

## URI Formats

The gallery supports multiple URI formats:

- **Local Files**: `file:///path/to/image.jpg`
- **Photo Library Assets**: `ph://asset-id` (iOS Photos framework)

## Image Loading and Caching

ExpoSimpleGallery implements efficient image loading and caching mechanisms:

1. **Automatic Thumbnail Generation**: For photos library assets, the module automatically generates thumbnails for faster loading.
2. **Progressive Loading**: Images first load as lower-quality thumbnails then upgrade to high-quality versions when available.
3. **Memory Management**: Images are loaded and unloaded as the user scrolls to maintain smooth performance.
4. **Error Handling**: Built-in error handling for missing or unloadable images.

## Fullscreen Image Viewer

The gallery includes a built-in fullscreen image viewer with these features:

- **Pinch to zoom**: Double tap or pinch to zoom in/out on images
- **Swipe to navigate**: Horizontal swipe to navigate between images
- **Pull to dismiss**: Pull down to dismiss the viewer
- **High-quality loading**: Seamless transition to high-quality images

The viewer can be programmatically controlled using `ref.openImageViewer(index)` and `ref.closeImageViewer()`.

## Basic Usage

```jsx
import { ExpoSimpleGalleryView } from 'expo-simple-gallery';

export default function App() {
  return (
    <ExpoSimpleGalleryView
      assets={['file:///path/to/image1.jpg', 'ph://asset-id-2']}
      columnsCount={3}
    />
  );
}
```

## Component

### ExpoSimpleGalleryView

The main component for rendering an image gallery grid.

#### Props

| Prop | Type | Description |
|------|------|-------------|
| `assets` | `string[]` or `string[][]` | Array of image URIs to display. Can be nested arrays for grouped sections. |
| `columnsCount` | `number` | Number of columns to display in the grid. |
| `thumbnailPressAction` | `'select'` \| `'open'` \| `'none'` | Action to perform when a thumbnail is pressed. |
| `thumbnailLongPressAction` | `'select'` \| `'open'` \| `'preview'` \| `'none'` | Action to perform when a thumbnail is long pressed. |
| `thumbnailPanAction` | `'select'` \| `'none'` | Action to perform when panning across thumbnails. |
| `contextMenuOptions` | `array` (`UIAction[]`) | Options for the context menu that appears on long press. |
| `initiallySelected` | `string[]` | URIs of items to be marked as selected on initial render. |
| `style` | `object` (`ViewStyle`) | Style object for the gallery container. |
| `thumbnailStyle` | `object` | Style object for thumbnail items. Available properties: `aspectRatio`, `borderRadius`, `borderWidth`, `borderColor' |
| `contentContainerStyle` | `object` | Style object for the content container. Available properties: `padding`, `paddingHorizontal`, `paddingVertical`, `paddingTop`, `paddingBottom`, `paddingLeft`, `paddingRight`, `gap` |
| `sectionHeaderStyle` | `object` | Style object for section headers when using grouped assets. Available properties: `height` |
| `fullscreenViewOverlayStyle` | `object` (`ViewStyle`) | Style object for the fullscreen view overlay. |
| `thumbnailOverlayComponent` | `({uri: string, index: number, selected: boolean }) => Component`  | React component to render as overlay on thumbnails. |
| `fullscreenViewOverlayComponent` | `({uri: string, index: number, selected: boolean, toggleSelection: (selected?: boolean) => void }) => Component` | React component to render as overlay in fullscreen view. `toggleSelection` toggles the selection state of the item if param is undefined, otherwise sets the selection state to the provided value. |
| `sectionHeaderComponent` | `({index: number}) => Component` | React component to render as section header. |
| `showMediaTypeIcon` | `boolean` | Whether to show the media type icon on thumbnails (for videos and live photos). Default: `true` |

#### Gesture Actions Reference

- **select**: Adds/removes the item to/from the selection and fires the `onSelectionChange` event.
- **open**: Opens the fullscreen viewer with the selected image.
- **preview**: Opens a preview with context menu with additional options (if provided).
- **none**: No action is performed, still fires the corresponding event (`onThumbnailPress`, `onThumbnailLongPress`).

#### Events

```jsx
<ExpoSimpleGalleryView
  assets={['file:///path/to/image1.jpg', 'ph://asset-id-2']}
  onThumbnailPress={({nativeEvent}) => console.log(nativeEvent.uri)}
/>
```

| Event | Type | Description |
|-------|------|-------------|
| `onThumbnailPress` | `(event: NativeSyntheticEvent<{ uri: string, index: number }>) => void` | Fired when a thumbnail is pressed. Returns the URI and index of the pressed thumbnail. |
| `onThumbnailLongPress` | `(event: NativeSyntheticEvent<{ uri: string, index: number }>) => void` | Fired when a thumbnail is long pressed. Returns the URI and index of the long pressed thumbnail. |
| `onSelectionChange` | `(event: NativeSyntheticEvent<{ selected: string[] }>) => void` | Fired when selected items change. Returns the array of selected URIs. |
| `onOverlayPreloadRequested` | `(event: NativeSyntheticEvent<{ range: [number, number] }>) => void` | Fired when overlays need to be preloaded for optimization. Returns the range of indices to preload. |
| `onSectionHeadersVisible` | `(event: NativeSyntheticEvent<{ sections: number[] }>) => void` | Fired when section headers become visible. Returns the array of visible section indices. |
| `onPreviewMenuOptionSelected` | `(event: NativeSyntheticEvent<{ uri: string, index: number, optionIndex: number }>) => void` | Fired when an option is selected from the context menu. Returns the URI, index of the item, and index of the selected option. |

#### Methods (available via `ref`)

```typescript
import { type ExpoSimpleGalleryMethods } from 'expo-simple-gallery';
...
const galleryRef = useRef<ExpoSimpleGalleryMethods>(null)
useEffect(() => {
  galleryRef.current?.centerOnIndex(0);
  galleryRef.current?.setSelected(['file:///path/to/image1.jpg', 'ph://asset-id-2']);
  galleryRef.current?.setThumbnailPressAction('open');
}, []);
```

| Method | Description |
|--------|-------------|
| `centerOnIndex(index: number)` | Scrolls to center the item at the specified index. |
| `setSelected(uris: string[])` | Sets the selected items by their URIs.  Useful is you want to manage selection state externally. Triggers `onSelectionChanged` event. |
| `setThumbnailPressAction(action: string)` | Sets the action performed when a thumbnail is pressed. Preferred over prop if dynamic changes are needed and you don't want to re-render the component. |
| `setThumbnailLongPressAction(action: string)` | Sets the action performed when a thumbnail is long pressed. Preferred over prop if dynamic changes are needed and you don't want to re-render the component. |
| `setThumbnailPanAction(action: string)` | Sets the action performed when panning across thumbnails. Preferred over prop if dynamic changes are needed and you don't want to re-render the component. |
| `setContextMenuOptions(options: array)` | Sets the context menu options. Preferred over prop if dynamic changes are needed and you don't want to re-render the component. |
| `openImageViewer(index: number)` | Opens the fullscreen image viewer with inmage at the specified index. |
| `closeImageViewer()` | Closes the fullscreen image viewer. |

## Advanced Usage

### Grouped Gallery with Sections

If you have multiple groups of images, you can pass nested arrays as `assets` to create sections. Each nested array will be displayed as a separate section with a header. Headers can be set using the `sectionHeaderComponent` prop.

```jsx
import { ExpoSimpleGalleryView } from 'expo-simple-gallery';

export default function GroupedGallery() {
  // Images grouped by date or category
  const groups = [
    ['file:///path/to/group1/image1.jpg', 'file:///path/to/group1/image2.jpg'],
    ['file:///path/to/group2/image1.jpg', 'file:///path/to/group2/image2.jpg'],
  ];

  return (
    <ExpoSimpleGalleryView
      assets={groups}
      columnsCount={3}
      sectionHeaderStyle={{ height: 40 }}
      sectionHeaderComponent={({ index }) => (
        <View style={{ height: 40, justifyContent: 'center', paddingLeft: 10 }}>
          <Text style={{ fontWeight: 'bold' }}>Section {index + 1}</Text>
        </View>
      )}
    />
  );
}
```

### Customizing Selection Behavior

```jsx
import { useRef } from 'react';
import { ExpoSimpleGalleryView, ExpoSimpleGalleryMethods } from 'expo-simple-gallery';

export default function SelectionExample() {
  const galleryRef = useRef<ExpoSimpleGalleryMethods>(null);
  const assets = ['file:///path/to/image1.jpg', 'ph://asset-id-2'];
  const [selectedUris, setSelectedUris] = useState<string[]>(['file:///path/to/image1.jpg']);

  const selectAll = useCallback(() => {
    galleryRef.current?.setSelected(assets)
  }, [assets]);

  const clearSelection = useCallback(() => {
    galleryRef.current?.setSelected([]);
  }, []);

  return (
    <>
      <ExpoSimpleGalleryView
        ref={galleryRef}
        assets={assets}
        thumbnailPressAction="select"
        thumbnailLongPressAction="preview"
        thumbnailPanAction="select"
        initiallySelected={selectedUris}
        onSelectionChange={(e) => {
          setSelectedUris(e.nativeEvent.selected);
        }}
      />


      <Button
        title="Select All"
        onPress={selectAll}
      />
      <Button
        title="Clear Selection"
        onPress={clearSelection}
      />
    </>
  );
}
```

### Implementing Custom Context Menu

Context menus appear when using `thumbnailLongPressAction="preview"` and provide additional options for interacting with the image.

#### Type definitions

```typescript
type UIMenuElementAttribute = 'disabled' | 'destructive' | 'hidden';
type UIMenuElementState = 'on' | 'off' | 'mixed'; // For toggle actions: checked | unchecked (default) | partially checked

export type UIAction = {
  title: string;
  sfSymbol?: string; /** @see https://developer.apple.com/sf-symbols/ */
  action?: ({uri: string, index: number}) => void;
  attributes?: UIMenuElementAttribute[];
  state?: UIMenuElementState;
};
```

```jsx
<ExpoSimpleGalleryView
  assets={assets}
  contextMenuOptions={[
    {
      title: 'Share',
      sfSymbol: 'square.and.arrow.up', // iOS SF Symbol name
      action: (item) => {
        // Handle share action
        console.log('Share item:', item.uri);
      }
    },
    {
      title: 'Delete',
      sfSymbol: 'trash',
      attributes: ['destructive'], // Special styling
      action: (item) => {
        // Handle delete action
        console.log('Delete item:', item.uri);
      }
    }
  ]}
/>
```

## Custom Overlays

You can provide custom overlay components for thumbnails, section headers and the fullscreen viewer:

```jsx
<ExpoSimpleGalleryView
  assets={assets}
  thumbnailOverlayComponent={({ uri, index, selected }) => (
    <View style={{ position: 'absolute', top: 5, right: 5, opacity: selected ? 1 : 0.5 }}>
      <CheckboxIcon checked={selected} />
    </View>
  )}
  fullscreenViewOverlayComponent={({ uri, index }) => (
    /* Pay attention to not blocking touch events on the image view */
    <View style={{ position: 'absolute', top: 20, left: 0, right: 0 }}>
      <Text style={{ color: 'white', textAlign: 'center' }}>
        URI: {uri} | Index: {index}
      </Text>
    </View>
  )}
  sectionHeaderComponent={({ index }) => (
    <View style={{ height: 40, justifyContent: 'center', paddingLeft: 10 }}>
      <Text style={{ fontWeight: 'bold' }}>Section {index + 1}</Text>
    </View>
  )}
/>
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
