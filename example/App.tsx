import { type Asset, getAssetsAsync, MediaType } from 'expo-media-library';
import { ExpoSimpleGalleryView } from 'expo-simple-gallery';
import { useEffect, useState } from 'react';
import { SafeAreaView, StyleSheet, Text, View } from 'react-native';

type CheckboxProps = {
  checked: boolean;
};
function Checkbox({ checked }: CheckboxProps) {
  return (
    <View
      style={{
        width: 30,
        height: 30,
        borderRadius: 10,
        borderWidth: 2,
        borderColor: 'black',
        backgroundColor: checked ? 'blue' : 'white',
        alignSelf: 'flex-end',
        margin: 10,
      }}
    />
  );
}

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
        thumbnailsSpacing={10}
        thumbnailStyle={{
          borderRadius: 20,
          // borderWidth: 4,
          // borderColor: 'teal',
          aspectRatio: 1,
        }}
        assets={assets.map(({ uri }) => uri)}
        style={styles.view}
        thumbnailOverlayComponent={({ selected, uri, index }) => (
          <Checkbox checked={selected} />
        )}
        contentContainerStyle={{
          padding: 20,
        }}
        onSelectionChange={(event) => {
          console.log('onSelectionChange', event.nativeEvent.selected);
        }}
        onThumbnailPress={(event) => {
          console.log('onThumbnailPress', event.nativeEvent);
        }}
        onThumbnailLongPress={(event) => {
          console.log('onThumbnailLongPress', event.nativeEvent);
        }}
        thumbnailPressAction="select"
        thumbnailPanAction="select"
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
