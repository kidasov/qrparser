import {Button, SafeAreaView, View} from 'react-native';

const Main = ({ navigation }) => {
  return (
    <SafeAreaView>
      <View>
        <Button title={'Show Rn camera'} onPress={() => navigation.navigate('RnVision')} />
        <Button title={'Show Custom Barcode Scanner'} onPress={() => navigation.navigate('CustomBarcode')} />
      </View>
    </SafeAreaView>
  )
}

export default Main;
