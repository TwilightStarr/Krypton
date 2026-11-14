import '../data/llm_engine.dart';
import '../domain/entities.dart';

/// Modelin bu cihazın toplam RAM'ine uygunluğu (memoryPlan sonucundan).
enum ModelFit { fits, borderline, tooBig }

String modelFitLabel(ModelFit f) => switch (f) {
      ModelFit.fits => 'Bu cihaza uygun',
      ModelFit.borderline => 'Sınırda',
      ModelFit.tooBig => 'Sığmaz',
    };

/// Rozet: "kullanılabilir bellek" anlık dalgalandığı için varsayılan olarak toplam RAM'in yarısı sayılır
/// (Android + arka plan uygulamalarının payı). [availableBytes] verilirse o kullanılır.
///
/// - fits: memoryPlan'ın seçtiği profil yeşil VE bağlam 4096 (normal)
/// - borderline: sarı, veya yeşil ama bağlam küçültülmüş
/// - tooBig: kırmızı (en küçük profil bile sığmıyor)
ModelFit modelFit(GgufModel m, {required int totalBytes, int? availableBytes}) {
  final modelBytes = m.sizeBytes ?? m.catalogBytes ?? (m.sizeGb * 1e9).round();
  final plan = memoryPlan(
    availableBytes: availableBytes ?? totalBytes ~/ 2,
    totalBytes: totalBytes,
    modelBytes: modelBytes,
    kvPerToken: m.arch?.kvBytesPerToken ?? fallbackKvBytesPerToken(modelBytes),
    nFf: m.arch?.feedForwardLength,
  );
  final sel = plan.selected;
  switch (sel.status) {
    case MemoryStatus.red:
      return ModelFit.tooBig;
    case MemoryStatus.yellow:
      return ModelFit.borderline;
    case MemoryStatus.green:
      return sel.ctx >= kRamEstimateCtx ? ModelFit.fits : ModelFit.borderline;
  }
}

/// Cihaza göre önerilen sohbet modeli.
class DefaultModelPick {
  const DefaultModelPick({required this.primaryId});
  final String primaryId;
}

/// Tercih sırası: büyükten küçüğe. Hiçbiri cihaza uygun değilse listedeki en küçük model önerilir.
const _preference = [
  'qwen-2.5-coder-7b-q4km',
  'qwen-2.5-coder-7b-iq4xs',
  'qwen-2.5-coder-3b-q4km',
  'qwen-2.5-coder-1.5b-q4km',
];

/// Varsayılan sohbet modeli: tercih sırasındaki ilk "uygun" model; hiçbiri uygun değilse en küçüğü.
/// RAM bilinmiyorsa (null) ilk tercih önerilir.
DefaultModelPick pickDefaultModels(List<GgufModel> models, int? totalBytes) {
  const legacy = DefaultModelPick(primaryId: 'qwen-2.5-coder-7b-q4km');
  if (totalBytes == null) return legacy;
  final byId = {for (final m in models) m.id: m};
  final candidates = [for (final id in _preference) if (byId[id] != null) byId[id]!];
  if (candidates.isEmpty) return legacy;
  var primary = candidates.last;
  for (final m in candidates) {
    if (modelFit(m, totalBytes: totalBytes) == ModelFit.fits) {
      primary = m;
      break;
    }
  }
  return DefaultModelPick(primaryId: primary.id);
}
