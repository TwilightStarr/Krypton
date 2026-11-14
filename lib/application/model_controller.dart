import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/crash_guard.dart';
import '../data/default_data.dart';
import '../data/llm_engine.dart';
import '../data/model_downloader.dart';
import '../data/native_services.dart';
import '../data/routing_engine.dart';
import '../data/storage.dart';
import '../domain/entities.dart';
import 'model_fit.dart';

final storageProvider = Provider<Storage>((ref) => Storage());

final downloaderProvider = Provider<ModelDownloader>((ref) => ModelDownloader());

/// Cihazın toplam RAM'i (bayt); okunamazsa null. Testlerde geçersiz kılınabilir.
final deviceRamProvider = Provider<Future<int?> Function()>(
  (ref) => () async {
    try {
      return (await MemInfoNative.current()).totalBytes;
    } catch (_) {
      return null;
    }
  },
);

/// Yerel çıkarım motoru: .gguf -> llama.cpp, .litertlm/.task -> LiteRT-LM.
final engineProvider = Provider<LlmEngine>((ref) {
  final e = RoutingEngine();
  ref.onDispose(e.dispose);
  return e;
});

final modelsProvider = NotifierProvider<ModelsController, ModelsState>(ModelsController.new);

/// Yerel model listesi, indirme ilerlemesi ve kısa bildirimler.
class ModelsState {
  const ModelsState({
    this.loaded = false,
    this.models = const [],
    this.downloads = const {},
    this.notice,
    this.noticeId = 0,
    this.totalRamBytes,
    this.defaultPick,
  });

  final bool loaded;
  final List<GgufModel> models;

  /// Süren indirmeler: model kimliği -> ilerleme (0..1; 1 = doğrulanıyor).
  final Map<String, double> downloads;
  final String? notice;
  final int noticeId;
  final int? totalRamBytes;
  final DefaultModelPick? defaultPick;

  int get cachedCount => models.where((m) => m.isCached).length;

  ModelsState copyWith({
    bool? loaded,
    List<GgufModel>? models,
    Map<String, double>? downloads,
    String? notice,
    int? noticeId,
    int? totalRamBytes,
    DefaultModelPick? defaultPick,
  }) => ModelsState(
    loaded: loaded ?? this.loaded,
    models: models ?? this.models,
    downloads: downloads ?? this.downloads,
    notice: notice ?? this.notice,
    noticeId: noticeId ?? this.noticeId,
    totalRamBytes: totalRamBytes ?? this.totalRamBytes,
    defaultPick: defaultPick ?? this.defaultPick,
  );
}

class ModelsController extends Notifier<ModelsState> {
  bool _disposed = false;
  final Map<String, DownloadCancel> _downloads = {};

  @override
  ModelsState build() {
    ref.onDispose(() {
      _disposed = true;
      for (final d in _downloads.values) {
        d.cancelled = true;
      }
    });
    Future.microtask(_init);
    return const ModelsState();
  }

  Future<void> _init() async {
    try {
      final st = ref.read(storageProvider);
      final reg = await st.loadRegistry();
      final models = modelCatalog.map((m) {
        final r = reg[m.id];
        if (r != null && File(r['path'] ?? '').existsSync()) {
          return m.withCache(r['path'], r['sha256'], sizeBytes: int.tryParse(r['size'] ?? ''));
        }
        return m;
      }).toList();
      final totalRam = await ref.read(deviceRamProvider)();
      final pick = pickDefaultModels(models, totalRam);
      if (_disposed) return;
      state = state.copyWith(totalRamBytes: totalRam, defaultPick: pick, loaded: true, models: models);
    } catch (e, st) {
      // Başlatma hatası arayüzü sonsuz yüklemede bırakmasın: boş kayıtla açılır.
      CrashGuard.log('Başlatma', e, st);
      if (_disposed) return;
      state = state.copyWith(loaded: true, models: modelCatalog);
      _notice('Kayıtlı model bilgisi okunamadı; liste varsayılanlarla açıldı.');
    }
  }

  void _notice(String m) {
    if (_disposed) return;
    state = state.copyWith(notice: m, noticeId: state.noticeId + 1);
  }

  void _setProgress(String id, double v) {
    if (_disposed) return;
    state = state.copyWith(downloads: {...state.downloads, id: v});
  }

  Future<void> startDownload(String id) async {
    if (state.downloads.containsKey(id)) return;
    GgufModel? m;
    for (final x in state.models) {
      if (x.id == id) m = x;
    }
    if (m == null || m.isCached) return;
    final model = m;
    final cancel = DownloadCancel();
    _downloads[id] = cancel;
    _setProgress(id, 0);
    _notice('İndirme başlatıldı: ${model.name}');
    try {
      final st = ref.read(storageProvider);
      final dl = ref.read(downloaderProvider);
      final path = await dl.download(model, await st.modelsDir(), (v) => _setProgress(id, v), cancel);
      final hash = await dl.sha256Of(path);
      final reg = await st.loadRegistry();
      final size = await File(path).length(); // indirici boyutu doğruladı: beklenene eşit
      reg[id] = {'path': path, 'sha256': hash, 'size': '$size'};
      await st.saveRegistry(reg);
      state = state.copyWith(
        models: [for (final x in state.models) x.id == id ? x.withCache(path, hash, sizeBytes: size) : x],
      );
      _notice('${model.name} indirildi ve kaydedildi.');
    } on DownloadCancelled {
      _notice('İndirme duraklatıldı: ${model.name}');
    } catch (e) {
      _notice('İndirme hatası: $e');
    } finally {
      _downloads.remove(id);
      if (!_disposed) {
        final d = {...state.downloads}..remove(id);
        state = state.copyWith(downloads: d);
      }
    }
  }

  void cancelDownload(String id) => _downloads[id]?.cancelled = true;

  Future<void> deleteModel(String id) async {
    GgufModel? m;
    for (final x in state.models) {
      if (x.id == id) m = x;
    }
    if (m == null || !m.isCached) return;
    try {
      final f = File(m.localPath!);
      if (await f.exists()) await f.delete();
      final st = ref.read(storageProvider);
      final reg = await st.loadRegistry();
      reg.remove(id);
      await st.saveRegistry(reg);
      state = state.copyWith(
        models: [for (final x in state.models) x.id == id ? x.withCache(null, null) : x],
      );
      _notice('${m.name} silindi.');
    } catch (e) {
      _notice('Silinemedi: $e');
    }
  }
}
