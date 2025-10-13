import {
  MediaType,
  getAssetsAsync,
  requestPermissionsAsync,
} from 'expo-media-library';
import {
  type ExpoSimpleGalleryMethods,
  ExpoSimpleGalleryView,
} from 'expo-simple-gallery';
import { useEffect, useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Button,
  Pressable,
  SafeAreaView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

type CheckboxProps = {
  checked: boolean;
  onPress?: () => void;
};
function Checkbox({ checked, onPress }: CheckboxProps) {
  return (
    <Pressable
      onPress={onPress}
      style={{
        width: 20,
        height: 20,
        borderRadius: 10,
        borderWidth: 2,
        borderColor: '#000000AA',
        backgroundColor: '#FFFFFFAA',
        alignSelf: 'flex-end',
        margin: 10,
      }}
    >
      <Text>{checked ? '✔️' : ''}</Text>
    </Pressable>
  );
}

export default function App() {
  const [assets, setAssets] = useState<string[]>([]);
  useEffect(() => {
    (async () => {
      const { status } = await requestPermissionsAsync();
      if (status !== 'granted') {
        return;
      }
      const { assets } = await getAssetsAsync({
        first: 999999,
        mediaType: [MediaType.photo, MediaType.video],
        sortBy: 'creationTime',
      });
      setAssets(assets.map(({ uri }) => uri));
    })();
  }, []);

  const [isFiltered, setIsFiltered] = useState(false);
  const assetsFiltered = useMemo(() => {
    if (isFiltered) {
      return assets.filter((_, index) => index % 2 === 0);
    }
    return assets;
  }, [assets, isFiltered]);

  const galleryRef = useRef<ExpoSimpleGalleryMethods>(null);

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.header}>Module API Example</Text>
      <View style={styles.buttonContainer}>
        <Button
          title="Select all"
          onPress={() => galleryRef.current?.setSelected(assets)}
        />
        <Button
          title="Deselect all"
          onPress={() => galleryRef.current?.setSelected([])}
        />
        <Button
          title="Toggle filter even"
          onPress={() => setIsFiltered((prev) => !prev)}
        />
      </View>
      {assets.length !== 0 ? (
        <ExpoSimpleGalleryView
          ref={galleryRef}
          assets={assetsFiltered}
          style={styles.view}
          columnsCount={4}
          thumbnailOverlayComponent={({ selected }) => (
            <Checkbox checked={selected} />
          )}
          fullscreenViewOverlayComponent={({ selected, toggleSelection }) => (
            <View style={{ position: 'absolute', top: 80, right: 20 }}>
              <Checkbox checked={selected} onPress={() => toggleSelection()} />
            </View>
          )}
          thumbnailStyle={{
            borderRadius: 20,
            aspectRatio: 1,
          }}
          contentContainerStyle={{
            padding: 20,
            gap: 10,
          }}
          onSelectionChange={({ nativeEvent }) => {
            console.log(nativeEvent.selected);
          }}
          thumbnailPressAction="open"
          thumbnailLongPressAction="preview"
          thumbnailPanAction="select"
          showMediaTypeIcon={false}
        />
      ) : (
        <View style={styles.preloaderContainer}>
          <ActivityIndicator size="large" color="#0000ff" />
        </View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  header: {
    fontSize: 30,
    margin: 20,
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 20,
  },
  group: {
    margin: 20,
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 20,
  },
  container: {
    flex: 1,
    backgroundColor: '#eee',
  },
  view: {
    flex: 1,
  },
  preloaderContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
});
