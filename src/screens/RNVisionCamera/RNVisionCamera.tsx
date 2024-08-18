import {Camera, useCameraDevice, useCodeScanner} from "react-native-vision-camera";
import {StyleSheet, Text} from "react-native";
import React from "react";

const RNVisionCamera = () => {
  const device = useCameraDevice('back')

  const codeScanner = useCodeScanner({
    codeTypes: ['qr', 'ean-13'],
    onCodeScanned: (codes) => {
      for (let code in codes) {
        console.warn('cdde', codes[code]);
      }
      console.log(`Scanned ${codes.length} codes!`)
    },
  });

  if (device === null) return <Text>No camera</Text>
  return (
    <Camera
      style={StyleSheet.absoluteFill}
      device={device}
      isActive={true}
      codeScanner={codeScanner}
    />
  );
};

export default RNVisionCamera;
