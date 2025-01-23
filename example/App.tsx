import { type Asset, getAssetsAsync } from 'expo-media-library';
import { ExpoSimpleGalleryView } from 'expo-simple-gallery';
import { useEffect, useState } from 'react';
import { SafeAreaView, Text, View } from 'react-native';

export default function App() {
  const [assets, setAssets] = useState<Asset[]>([]);

  useEffect(() => {
    (async () => {
      const { assets } = await getAssetsAsync({
        first: 999999,
      });
      setAssets(assets);
    })();
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.header}>Module API Example</Text>
      <ExpoSimpleGalleryView
        columnsCount={3}
        thumbnailStyle={{
          borderRadius: 0,
          borderWidth: 4,
          borderColor: '#000000',
          aspectRatio: 1,
        }}
        assets={assets.map(({ uri }) => uri)}
        thumbnailsSpacing={20}
        style={styles.view}
        thumbnailOverlayComponent={({ selected, uri, index }) => (
          <View
            style={{
              backgroundColor: 'green',
              opacity: 0.6,
              borderWidth: 10,
            }}
          >
            <Text style={{ fontSize: 32 }}>
              {index === 6 ? '57' : index + 4}
            </Text>
          </View>
        )}
      >
        <View nativeID="thumbnail-0" key={3213} />
        <Text>Thumbnail2</Text>
        <Text>Thumbnail3</Text>
        <Text>Thumbnail4</Text>
        <Text>Thumbnail5</Text>
      </ExpoSimpleGalleryView>
    </SafeAreaView>
  );
}

function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = {
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
};
