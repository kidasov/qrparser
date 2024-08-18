import { createNativeStackNavigator } from '@react-navigation/native-stack';
import RNVisionCamera from '../screens/RNVisionCamera';
import Main from '../screens/Main';

const Stack = createNativeStackNavigator();
const LibrariesExample = () => {
  return (
    <Stack.Navigator initialRouteName={'Main'}>
      <Stack.Screen name="Main" component={Main} />
      <Stack.Screen name="RnVision" component={RNVisionCamera} />
    </Stack.Navigator>
  );
};

export default LibrariesExample;
