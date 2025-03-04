import {
  getAssetsAsync,
  MediaType,
  requestPermissionsAsync,
} from 'expo-media-library';
import { ExpoSimpleGalleryView } from 'expo-simple-gallery';
import { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  SafeAreaView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

type CheckboxProps = {
  checked: boolean;
};
function Checkbox({ checked }: CheckboxProps) {
  return (
    <View
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
    </View>
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

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.header}>Module API Example</Text>
      {assets.length !== 0 ? (
        <ExpoSimpleGalleryView
          assets={assets}
          style={styles.view}
          columnsCount={3}
          thumbnailOverlayComponent={({ selected }) => (
            <Checkbox checked={selected} />
          )}
          thumbnailStyle={{
            borderRadius: 20,
            aspectRatio: 1,
          }}
          contentContainerStyle={{
            padding: 20,
            gap: 10,
          }}
          thumbnailPressAction="open"
          thumbnailLongPressAction="preview"
          thumbnailPanAction="select"
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
});
