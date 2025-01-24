import { type Asset, getAssetsAsync, MediaType } from 'expo-media-library';
import { ExpoSimpleGalleryView } from 'expo-simple-gallery';
import { useEffect, useState } from 'react';
import { SafeAreaView, StyleSheet, Text } from 'react-native';

export default function App() {
  const [assets, setAssets] = useState<Asset[]>([]);

  useEffect(() => {
    (async () => {
      const { assets } = await getAssetsAsync({
        first: 999999,
        mediaType: [MediaType.photo, MediaType.video],
        sortBy: 'creationTime',
      });
      setAssets(assets);
    })();
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.header}>Module API Example</Text>
      <ExpoSimpleGalleryView
        columnsCount={2}
        thumbnailsSpacing={20}
        thumbnailStyle={{
          borderRadius: 20,
          // borderWidth: 4,
          // borderColor: 'teal',
          aspectRatio: 4 / 3,
        }}
        assets={assets.map(({ uri }) => uri)}
        style={styles.view}
        thumbnailOverlayComponent={({ selected, uri, index }) => (
          <Text style={{ fontSize: 32 }}>{index === 6 ? 'six' : index}</Text>
          // <View
          //   style={{
          //     backgroundColor: 'green',
          //     opacity: 0.3,
          //     // borderWidth: 10,
          //     flex: 1,
          //     padding: 20,
          //   }}
          // >
          // </View>
        )}
        contentContainerStyle={{
          padding: 20,
        }}
      />
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
});
