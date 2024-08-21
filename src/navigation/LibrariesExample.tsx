import { createNativeStackNavigator } from '@react-navigation/native-stack';
import RNVisionCamera from '../screens/RNVisionCamera';
import Main from '../screens/Main';
import CustomBarcode from "../screens/CustomBarcode";

const Stack = createNativeStackNavigator();
const LibrariesExample = () => {
  return (
    <Stack.Navigator initialRouteName={'Main'}>
      <Stack.Screen name="Main" component={Main} />
      <Stack.Screen name="RnVision" component={RNVisionCamera} />
      <Stack.Screen name="CustomBarcode" component={CustomBarcode} />
    </Stack.Navigator>
  );
};

export default LibrariesExample;
