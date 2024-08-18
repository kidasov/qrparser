import {Button, SafeAreaView, View} from 'react-native';

const Main = ({ navigation }) => {
  return (
    <SafeAreaView>
      <View>
        <Button title={'Show Rn camera'} onPress={() => navigation.navigate('RnVision')} />
      </View>
    </SafeAreaView>
  )
}

export default Main;
