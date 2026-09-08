import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo/services/call_tutor_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CallTutorService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Save and load Twilio and ElevenLabs credentials', () async {
      final service = CallTutorService.instance;

      await service.saveCredentials(
        twilioSid: 'AC1234567890',
        twilioAuth: 'auth_secret_xyz',
        twilioFromNumber: '+14155552671',
        elevenLabsKey: 'xi_key_test_123',
        elevenLabsAgentId: 'agent_abc',
        elevenLabsVoiceId: CallTutorService.defaultVoiceRachel,
        studentPhone: '+919876543210',
      );

      final creds = await service.loadCredentials();
      expect(creds['twilioSid'], 'AC1234567890');
      expect(creds['twilioAuth'], 'auth_secret_xyz');
      expect(creds['twilioFromNumber'], '+14155552671');
      expect(creds['elevenLabsKey'], 'xi_key_test_123');
      expect(creds['elevenLabsAgentId'], 'agent_abc');
      expect(creds['studentPhone'], '+919876543210');
    });

    test('Twilio call initiation validates empty phone number', () async {
      final service = CallTutorService.instance;
      final result = await service.initiateTwilioPhoneCall(
        toNumber: '',
        topic: 'Newtonian Dynamics',
        grade: 'Class 10',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('valid recipient phone number'));
    });

    test('Twilio call initiation succeeds in simulation/demo mode when live creds are not set', () async {
      final service = CallTutorService.instance;
      final result = await service.initiateTwilioPhoneCall(
        toNumber: '+919876543210',
        topic: 'Laws of Motion',
        grade: 'Class 10',
      );
      expect(result.success, isTrue);
      expect(result.isSimulation, isTrue);
      expect(result.callSid, startsWith('SIM_TWILIO_'));
    });

    test('Socratic tutor generates contextual conversational responses', () {
      final service = CallTutorService.instance;

      final greeting = service.generateTutorResponse(
        studentSpeech: 'Hello Echo, can you help me?',
        topic: 'Thermodynamics',
        grade: 'Class 11',
        history: [],
      );
      expect(greeting, contains('Echo'));
      expect(greeting, contains('Thermodynamics'));

      final whyResp = service.generateTutorResponse(
        studentSpeech: 'Why does heat transfer from hot to cold?',
        topic: 'Thermodynamics',
        grade: 'Class 11',
        history: [],
      );
      expect(whyResp.isNotEmpty, isTrue);

      final formulaResp = service.generateTutorResponse(
        studentSpeech: 'What is the formula for work done?',
        topic: 'Work and Energy',
        grade: 'Class 9',
        history: [],
      );
      expect(formulaResp, contains('Work and Energy'));
    });
  });
}
