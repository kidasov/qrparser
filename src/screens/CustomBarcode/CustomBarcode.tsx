import {
  Image,
  NativeSyntheticEvent,
  requireNativeComponent, SafeAreaView, StyleSheet,
  View,
  ViewStyle,
} from 'react-native';
import styles from './CustomBarcode.styles';

const BarcodeViewNative = requireNativeComponent<{cameraModel: number}>(
  'BarcodeView',
);

export type BarcodeViewProps = {
  onBarcodeRead: (e: NativeSyntheticEvent<{code: string}>) => void;
  placeholderContainerStyle: ViewStyle;
};

const CustomBarcode = () => {
  const handleBarcodeRead = async e => {
    const newCode = e.nativeEvent.code;

    console.warn('Code', newCode);
  };

  return (
    <SafeAreaView style={styles.container}>
      <BarcodeViewNative style={StyleSheet.absoluteFillObject} cameraModel={2} onBarcodeRead={handleBarcodeRead} />
      <View
        style={styles.barcodePlaceholderContainer}>
        <Image
          resizeMode={'contain'}
          style={styles.barcodeImagePlaceholder}
          source={require('../../assets/scan.png')}
        />
      </View>
    </SafeAreaView>
  );
};

export default CustomBarcode;
