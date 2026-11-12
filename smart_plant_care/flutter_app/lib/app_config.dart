/// Cloud Functions base URL used by Pump Control and AI Prediction.
///
/// Default points to the project's deployed Cloud Functions in us-central1.
/// For local emulator testing, pass:
/// `--dart-define=FUNCTIONS_BASE_URL=http://10.0.2.2:5001/smart-plant-care-342d6/us-central1`
const String kFunctionsBaseUrl = String.fromEnvironment(
  'FUNCTIONS_BASE_URL',
  defaultValue: 'https://us-central1-smart-plant-care-342d6.cloudfunctions.net',
);
