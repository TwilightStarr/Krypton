import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krypton_ai/application/settings_controller.dart';
import 'package:krypton_ai/core/theme.dart';
import 'package:krypton_ai/domain/chat_type_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => KPalette.current = KPalette.gece);

  group('tema paletleri', () {
    test('kimlikler benzersiz, bilinmeyen kimlik varsayılana düşer', () {
      final ids = KPalette.all.map((p) => p.id).toSet();
      expect(ids.length, KPalette.all.length);
      expect(KPalette.all.length, greaterThanOrEqualTo(5));
      expect(KPalette.byId('yok_boyle_bir_tema'), same(KPalette.gece));
      expect(KPalette.byId(null), same(KPalette.gece));
    });

    test('her palet için ThemeData üretilir ve parlaklık eşleşir', () {
      for (final p in KPalette.all) {
        final t = buildTheme(p);
        expect(t.brightness, p.brightness, reason: p.id);
        expect(t.scaffoldBackgroundColor, p.bg, reason: p.id);
        expect(t.colorScheme.primary, p.accent, reason: p.id);
      }
    });

    test('KColors geçerli paleti okur', () {
      KPalette.current = KPalette.amoled;
      expect(KColors.bg, const Color(0xFF000000));
      KPalette.current = KPalette.gunIsigi;
      expect(KColors.card, const Color(0xFFFFFFFF));
    });

    test('ayarlar JSON gidiş-dönüş; bozuk tema kimliği varsayılana döner', () {
      const s = AppSettings(themeId: 'orman', chatAutoPrepare: false, chatTypeMode: ChatTypeMode.word);
      final back = AppSettings.fromJson(s.toJson());
      expect(back.themeId, 'orman');
      expect(back.chatAutoPrepare, isFalse);
      expect(back.chatTypeMode, ChatTypeMode.word);
      expect(AppSettings.fromJson({'theme': 'x'}).themeId, 'gece');
      expect(AppSettings.fromJson({}).chatAutoPrepare, isTrue);
      expect(AppSettings.fromJson({}).chatTypeMode, ChatTypeMode.letter);
    });

    test('setTheme paleti hemen günceller', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(settingsProvider.notifier).setTheme('mor_gece');
      expect(KPalette.current.id, 'mor_gece');
      expect(c.read(settingsProvider).themeId, 'mor_gece');
    });
  });
}
