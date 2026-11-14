import '../domain/entities.dart';

// GGUF anahtarları (qwen2.block_count / embedding_length / attention.head_count[_kv] / feed_forward_length).
// Katman ve head sayıları Qwen model kartlarından doğrulandı: 1.5B 28 kat. 12Q/2KV, 3B 36 kat., 7B 28 kat. 28Q/4KV.
const _qwenCoder1_5bArch = GgufArch(
  blockCount: 28,
  embeddingLength: 1536,
  attentionHeadCount: 12,
  attentionHeadCountKv: 2,
  feedForwardLength: 8960,
);
const _qwenCoder3bArch = GgufArch(
  blockCount: 36,
  embeddingLength: 2048,
  attentionHeadCount: 16,
  attentionHeadCountKv: 2,
  feedForwardLength: 11008,
);
const _qwenCoder7bArch = GgufArch(
  blockCount: 28,
  embeddingLength: 3584,
  attentionHeadCount: 28,
  attentionHeadCountKv: 4,
  feedForwardLength: 18944,
);

const modelCatalog = <GgufModel>[
  GgufModel(
    id: 'qwen-2.5-coder-7b-q4km',
    name: 'Qwen 2.5 Coder 7B (Instruct)',
    family: 'Qwen',
    parameters: '7B',
    quantization: 'Q4_K_M',
    sizeGb: 4.1,
    ramGb: 4.8,
    tokensPerSec: '18 - 24 tok/s',
    quality: 'Optimum Denge (Varsayılan Önerilen)',
    url:
        'https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q4_k_m.gguf',
    fileName: 'qwen2.5-coder-7b-q4_k_m.gguf',
    template: ChatTemplate.chatml,
    arch: _qwenCoder7bArch,
  ),
  GgufModel(
    id: 'deepseek-r1-distill-7b-q4km',
    name: 'DeepSeek R1 Distill Qwen 7B',
    family: 'DeepSeek',
    parameters: '7B',
    quantization: 'Q4_K_M',
    sizeGb: 4.1,
    ramGb: 4.8,
    tokensPerSec: '17 - 23 tok/s',
    quality: 'Yüksek Mantıksal ve Adım Adım Muhakeme',
    url:
        'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf',
    fileName: 'deepseek-r1-distill-qwen-7b-q4_k_m.gguf',
    template: ChatTemplate.deepseek,
  ),
  GgufModel(
    id: 'mistral-7b-instruct-v03-q5km',
    name: 'Mistral 7B Instruct v0.3',
    family: 'Mistral',
    parameters: '7B',
    quantization: 'Q5_K_M',
    sizeGb: 4.8,
    ramGb: 5.6,
    tokensPerSec: '12 - 16 tok/s',
    quality: 'Yüksek (Kodlama ve Hata Ayıklama)',
    url:
        'https://huggingface.co/MaziyarPanahi/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3.Q5_K_M.gguf',
    fileName: 'mistral-7b-instruct-v0.3-q5_k_m.gguf',
    template: ChatTemplate.mistral,
  ),
  GgufModel(
    id: 'llama-3.2-3b-q4km',
    name: 'Llama 3.2 3B Instruct',
    family: 'Llama',
    parameters: '3.2B',
    quantization: 'Q4_K_M',
    sizeGb: 2.1,
    ramGb: 2.7,
    tokensPerSec: '28 - 36 tok/s',
    quality: 'Düşük RAM ve Hızlı Mobil Çıkarım',
    url:
        'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    fileName: 'llama-3.2-3b-instruct-q4_k_m.gguf',
    template: ChatTemplate.llama3,
  ),
  GgufModel(
    id: 'qwen-2.5-coder-7b-q5km',
    name: 'Qwen 2.5 Coder 7B (Hassas Hata Ayıklama)',
    family: 'Qwen',
    parameters: '7B',
    quantization: 'Q5_K_M',
    sizeGb: 4.8,
    ramGb: 5.6,
    tokensPerSec: '12 - 16 tok/s',
    quality: 'Yüksek Hassasiyet (Kod Analizi)',
    url:
        'https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q5_k_m.gguf',
    fileName: 'qwen2.5-coder-7b-q5_k_m.gguf',
    template: ChatTemplate.chatml,
    arch: _qwenCoder7bArch,
  ),
  GgufModel(
    id: 'phi-3.5-mini-3.8b-q4km',
    name: 'Phi-3.5 Mini Instruct 3.8B',
    family: 'Phi',
    parameters: '3.8B',
    quantization: 'Q4_K_M',
    sizeGb: 2.3,
    ramGb: 2.9,
    tokensPerSec: '25 - 32 tok/s',
    quality: 'Dengeli Dokümantasyon & Özetleme',
    url:
        'https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf',
    fileName: 'phi-3.5-mini-instruct-q4_k_m.gguf',
    template: ChatTemplate.phi3,
  ),
  // --- Düşük RAM seçenekleri (sizeGb/ramGb catalogBytes + arch'tan türetilir) ---
  // catalogBytes: Hugging Face dosya sayfasındaki boyut (ondalık GB'den yuvarlanmış; indirme sırasında
  // sunucunun bildirdiği kesin boyutla doğrulanır).
  GgufModel(
    id: 'qwen-2.5-coder-3b-q4km',
    name: 'Qwen 2.5 Coder 3B (Instruct)',
    family: 'Qwen',
    parameters: '3B',
    quantization: 'Q4_K_M',
    catalogBytes: 1930000000,
    arch: _qwenCoder3bArch,
    tokensPerSec: 'tahmini 28 - 36 tok/s',
    quality: 'Düşük RAM: 7B\'ye göre yaklaşık yarı RAM, kodlama odaklı',
    url:
        'https://huggingface.co/bartowski/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-3B-Instruct-Q4_K_M.gguf',
    fileName: 'Qwen2.5-Coder-3B-Instruct-Q4_K_M.gguf',
    template: ChatTemplate.chatml,
  ),
  GgufModel(
    id: 'qwen-2.5-coder-1.5b-q4km',
    name: 'Qwen 2.5 Coder 1.5B (Instruct)',
    family: 'Qwen',
    parameters: '1.5B',
    quantization: 'Q4_K_M',
    catalogBytes: 986000000,
    arch: _qwenCoder1_5bArch,
    tokensPerSec: 'tahmini 45 - 60 tok/s',
    quality: 'En düşük RAM: basit kod/özet görevleri, kalite 7B\'nin altında',
    url:
        'https://huggingface.co/bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf',
    fileName: 'Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf',
    template: ChatTemplate.chatml,
  ),
  GgufModel(
    id: 'qwen-2.5-coder-7b-iq4xs',
    name: 'Qwen 2.5 Coder 7B (IQ4_XS, hafif)',
    family: 'Qwen',
    parameters: '7B',
    quantization: 'IQ4_XS',
    catalogBytes: 4220000000,
    arch: _qwenCoder7bArch,
    tokensPerSec: 'tahmini 15 - 20 tok/s',
    quality:
        'RAM kazancı küçüktür: dosya Q4_K_S\'ten yalnızca 0.24 GB küçük; 7B\'nin bellek tabanı yüksek kalır. IQ4_XS ARM CPU\'da K-kuantlardan yavaş olabilir.',
    url:
        'https://huggingface.co/bartowski/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-7B-Instruct-IQ4_XS.gguf',
    fileName: 'Qwen2.5-Coder-7B-Instruct-IQ4_XS.gguf',
    template: ChatTemplate.chatml,
  ),
];
