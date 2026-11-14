import 'package:flutter_test/flutter_test.dart';
import 'package:krypton_ai/domain/inference_settings.dart';

void main() {
  group('InferenceSettings', () {
    test('varsayılanlar eski sabit değerlerdir', () {
      const d = InferenceSettings();
      expect(d.temperature, 0.4);
      expect(d.topP, 0.9);
      expect(d.topK, 40);
      expect(d.repeatPenalty, 1.1);
      expect(d.maxTokens, isNull);
      expect(d.isDefault, isTrue);
    });

    test('JSON gidiş-dönüşünde özel ayarlar korunur', () {
      const c = InferenceSettings(temperature: 0.1, topP: 0.8, topK: 20, repeatPenalty: 1.2, maxTokens: 512);
      expect(InferenceSettings.fromJson(c.toJson()), c);
    });

    test('clamped: bozuk değerler geçerli aralığa çekilir', () {
      final c = const InferenceSettings(
        temperature: 9,
        topP: 0,
        topK: 0,
        repeatPenalty: 0.2,
        maxTokens: 5,
      ).clamped();
      expect(c.temperature, 2.0);
      expect(c.topP, 0.05);
      expect(c.topK, 1);
      expect(c.repeatPenalty, 1.0);
      expect(c.maxTokens, 32);
      expect(const InferenceSettings(maxTokens: 0).clamped().maxTokens, isNull);
    });

    test('copyWith(clearMaxTokens) otomatiğe döner', () {
      final c = const InferenceSettings(maxTokens: 512).copyWith(clearMaxTokens: true);
      expect(c.maxTokens, isNull);
    });
  });
}
