import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/storage.dart';
import '../domain/chat_type_mode.dart';
import 'model_controller.dart' show storageProvider;

/// Kalıcı görünüm / performans tercihleri.
class AppSettings {
  /// Seçili tema paleti ([KPalette.id]).
  final String themeId;

  /// Sohbette seçilen model ([GgufModel.id]); null = cihaz varsayılanı.
  final String? chatModelId;

  /// Açıksa sohbet açılınca model ilk mesajı beklemeden arka planda hazırlanır.
  /// Düşük RAM'li telefonlarda kapatılabilir (model ilk mesajda yüklenir).
  final bool chatAutoPrepare;

  /// Sohbette yanıtın yazılış animasyonu (varsayılan: harf harf).
  final ChatTypeMode chatTypeMode;

  const AppSettings({
    this.themeId = 'gece',
    this.chatModelId,
    this.chatAutoPrepare = true,
    this.chatTypeMode = ChatTypeMode.letter,
  });

  AppSettings copyWith({
    String? themeId,
    String? chatModelId,
    bool? chatAutoPrepare,
    ChatTypeMode? chatTypeMode,
  }) => AppSettings(
        themeId: themeId ?? this.themeId,
        chatModelId: chatModelId ?? this.chatModelId,
        chatAutoPrepare: chatAutoPrepare ?? this.chatAutoPrepare,
        chatTypeMode: chatTypeMode ?? this.chatTypeMode,
      );

  Map<String, dynamic> toJson() => {
        'theme': themeId,
        if (chatModelId != null) 'chatModel': chatModelId,
        'chatAutoPrepare': chatAutoPrepare,
        'chatTypeMode': chatTypeMode.name,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        themeId: KPalette.byId(j['theme'] as String?).id,
        chatModelId: j['chatModel'] is String ? j['chatModel'] as String : null,
        chatAutoPrepare: j['chatAutoPrepare'] != false,
        chatTypeMode: ChatTypeMode.fromId(j['chatTypeMode']),
      );

  /// Açılışta (runApp'ten önce) okunur; hata olursa varsayılanlar döner.
  static Future<AppSettings> load(Storage st) async {
    try {
      return AppSettings.fromJson(await st.loadSettings());
    } catch (_) {
      return const AppSettings();
    }
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  SettingsController([this._initial]);

  final AppSettings? _initial;

  @override
  AppSettings build() {
    final s = _initial ?? AppSettings(themeId: KPalette.current.id);
    KPalette.current = KPalette.byId(s.themeId);
    return s;
  }

  void setTheme(String id) {
    final p = KPalette.byId(id);
    if (state.themeId == p.id) return;
    KPalette.current = p; // önce palet, sonra durum: dinleyenler yeni renkleri okur
    state = state.copyWith(themeId: p.id);
    _save();
  }

  void setChatModel(String id) {
    if (state.chatModelId == id) return;
    state = state.copyWith(chatModelId: id);
    _save();
  }

  void setChatAutoPrepare(bool v) {
    if (state.chatAutoPrepare == v) return;
    state = state.copyWith(chatAutoPrepare: v);
    _save();
  }

  void setChatTypeMode(ChatTypeMode v) {
    if (state.chatTypeMode == v) return;
    state = state.copyWith(chatTypeMode: v);
    _save();
  }

  Future<void> _save() async {
    try {
      await ref.read(storageProvider).saveSettings(state.toJson());
    } catch (_) {}
  }
}
