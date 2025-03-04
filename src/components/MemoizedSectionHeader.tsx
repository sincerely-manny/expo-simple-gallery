import { memo, useMemo } from 'react';
import { Text, View } from 'react-native';
import type { SectionHeaderComponent } from '../ExpoSimpleGallery.types';

export const MemoizedSectionHeader = memo(function MemoizedSectionHeader({
  SectionHeader,
  index,
  width,
  height,
  isNull,
  debugLabels,
}: {
  SectionHeader: SectionHeaderComponent;
  index: number;
  width: number;
  height: number;
  isNull: boolean;
  debugLabels: boolean;
}) {
  const style = useMemo(() => ({ position: 'absolute', width, height }) as const, [width, height]);
  if (isNull) return null;
  return (
    <View
      style={style}
      nativeID={`SectionHeaderOverlay_${index}`}
      collapsable={false}
      accessibilityLabel={`SectionHeaderOverlay_${index}`}
    >
      {debugLabels && <Text style={{ backgroundColor: 'red', textAlign: 'center' }}>{index}</Text>}
      <SectionHeader index={index} />
    </View>
  );
});
