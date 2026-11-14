enum ChatTemplate { chatml, llama3, mistral, phi3, alpaca, deepseek }

/// GGUF metadata'sından KV/FFN hesabı için gereken mimari değerleri (model kartı = GGUF anahtarları).
/// Formül [GgufMeta.kvBytesPerToken] ile aynıdır (F16 K+V önbelleği, token başına bayt).
class GgufArch {
  const GgufArch({
    required this.blockCount,
    required this.embeddingLength,
    required this.attentionHeadCount,
    required this.attentionHeadCountKv,
    required this.feedForwardLength,
  });

  final int blockCount;
  final int embeddingLength;
  final int attentionHeadCount;
  final int attentionHeadCountKv;
  final int feedForwardLength;

  int get kvBytesPerToken =>
      2 *
      blockCount *
      ((embeddingLength * attentionHeadCountKv) ~/ attentionHeadCount) *
      2;
}

/// Katalogdaki RAM tahmini: dosya boyutu + KV(ctx) + sabit 0.5 GB (ondalık GB, 1 GB = 1e9 bayt).
const kRamEstimateCtx = 4096;
const kRamOverheadBytes = 500 * 1000 * 1000;

double estimateRamGb({
  required int fileBytes,
  required int kvBytesPerToken,
  int ctx = kRamEstimateCtx,
  int overheadBytes = kRamOverheadBytes,
}) => (fileBytes + kvBytesPerToken * ctx + overheadBytes) / 1e9;

class GgufModel {
  final String id;
  final String name;
  final String family;
  final String parameters;
  final String quantization;
  final String tokensPerSec;
  final String quality;
  final String url;
  final String fileName;
  final ChatTemplate template;
  final String? localPath;
  final String? sha256;

  /// İndirilmiş dosyanın gerçek boyutu (yalnızca önbellekteyken).
  final int? sizeBytes;

  /// Hugging Face'in bildirdiği yaklaşık indirme boyutu (bayt). [arch] ile birlikte verilirse
  /// [sizeGb] ve [ramGb] bundan TÜRETİLİR (elle yazılmaz).
  final int? catalogBytes;
  final GgufArch? arch;
  final double? _sizeGb;
  final double? _ramGb;

  const GgufModel({
    required this.id,
    required this.name,
    required this.family,
    required this.parameters,
    required this.quantization,
    double? sizeGb,
    double? ramGb,
    required this.tokensPerSec,
    required this.quality,
    required this.url,
    required this.fileName,
    required this.template,
    this.localPath,
    this.sha256,
    this.sizeBytes,
    this.catalogBytes,
    this.arch,
  }) : _sizeGb = sizeGb,
       _ramGb = ramGb,
       assert(sizeGb != null || catalogBytes != null),
       assert(ramGb != null || (catalogBytes != null && arch != null));

  double get sizeGb => _sizeGb ?? catalogBytes! / 1e9;

  double get ramGb => (catalogBytes != null && arch != null)
      ? estimateRamGb(
          fileBytes: catalogBytes!,
          kvBytesPerToken: arch!.kvBytesPerToken,
        )
      : _ramGb!;

  bool get isCached => localPath != null;

  GgufModel withCache(String? path, String? hash, {int? sizeBytes}) =>
      GgufModel(
        id: id,
        name: name,
        family: family,
        parameters: parameters,
        quantization: quantization,
        sizeGb: _sizeGb,
        ramGb: _ramGb,
        tokensPerSec: tokensPerSec,
        quality: quality,
        url: url,
        fileName: fileName,
        template: template,
        localPath: path,
        sha256: hash,
        sizeBytes: sizeBytes,
        catalogBytes: catalogBytes,
        arch: arch,
      );
}
