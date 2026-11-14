# Krypton

![Platform: Android arm64](https://img.shields.io/badge/platform-Android%20arm64-green.svg)
![Flutter](https://img.shields.io/badge/Flutter-stable-02569B.svg)
[![Lisans: MIT](https://img.shields.io/badge/lisans-MIT-blue.svg)](LICENSE)

**Telefonunda tamamen yerel çalışan yapay zekâ sohbet uygulaması.**

Krypton, GGUF biçimindeki dil modellerini doğrudan cihazda çalıştırır
([llama.cpp](https://github.com/ggml-org/llama.cpp) tabanlı `flutter_llama` ile). Hesap, abonelik veya internet
bağlantısı gerekmez; modeli bir kez indirdikten sonra tüm sohbet çevrimdışı çalışır.

Uygulama açılınca doğrudan sohbet ekranı gelir. Başka mod, menü ya da ekran yoktur.

## Özellikler

- **Yerel sohbet:** Model cihazda çalışır; yazdıkların telefondan çıkmaz.
- **Kalıcı geçmiş:** Her mesaj diske yazılır; eski konuşmalar aranıp ilgili olanlar modele hatırlatılır.
- **Bilgi ekleme (Hafıza):**
  - Kendin hakkında yazdığın dosyaları **ZIP** olarak yükle (`.txt`, `.md`, `.json`, `.csv`, `.html`, `.docx` …);
    model soruların ilgili olduğunda bu bilgiden yararlanır.
  - Bir mesaja uzun basıp **kalıcı hafızaya sabitle**; sabit notlar her yanıtta modele verilir.
- **Model yöneticisi:** Cihazın RAM'ine göre uygunluk rozetleri, duraklatılabilir indirme, SHA-256 doğrulama, silme.
- **Cihaza duyarlı bellek yönetimi:** Model, RAM'e göre bağlam/batch profiliyle yüklenir; sığmazsa otomatik küçülür.
- **Yazı animasyonu** (kapalı / kelime / harf), **7 tema**, sohbet geçmişini Markdown olarak dışa aktarma.

## Kullanım

1. Sağ üstteki menüden **Model yöneticisi**'ni aç ve cihazına uygun bir model indir.
2. Başlıktaki model adına dokunarak modeli seç.
3. (İsteğe bağlı) **Hafıza** düğmesinden ZIP yükle veya not ekle.
4. Yaz ve gönder.

## Gereksinimler

- Android 8.0+ (minSdk 26), **arm64** cihaz.
- Model için boş depolama alanı ve RAM (4 GB RAM'de 1.5B–3B, 8 GB+ RAM'de 7B önerilir).

## Kurulum

### Hazır APK (GitHub Actions)

`main` dalına yapılan her push, **Build APK & Publish Release** iş akışıyla bir `Krypton-<sürüm>.apk` üretir ve
Releases sayfasında yayınlar (yanında `.sha256` dosyası bulunur).

### Kaynaktan derleme

```bash
./kurulum.sh        # Android platform dosyalarını üretir
flutter build apk --release --target-platform android-arm64
```

> `flutter_llama` paketi llama.cpp kaynağını içermez; yerel derlemede `llama.cpp` klasörünün eklentiye ayrıca
> eklenmesi gerekir. CI iş akışı (`.github/workflows/build-apk.yml`) bunu ve Android iskeletini otomatik yapar.

## Proje yapısı

```
lib/
  main.dart                 Açılış, hata yakalama, doğrudan sohbet ekranı
  core/theme.dart           Temalar
  domain/                   Sohbet modelleri, şablonlar, model kataloğu varlıkları
  application/
    chat_controller.dart    Mesajlaşma, hafıza, üretim akışı
    chat_memory.dart        Aranabilir hafıza ve istem kurma
    model_controller.dart   Model listesi, indirme, silme, çıkarım motoru
    settings_controller.dart
  data/                     llama.cpp / LiteRT motorları, depolama, ZIP içe aktarma, indirici
  presentation/             Sohbet ekranı, hafıza, model yöneticisi, tema
test/                       Birim testleri
```

## Gizlilik ve izinler

Sohbetler, hafıza dosyaları ve ayarlar yalnızca cihazda saklanır. Uygulama yalnızca model dosyalarını indirmek için
ağa bağlanır (Hugging Face).

| İzin | Neden |
|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | Model indirme |
| `FOREGROUND_SERVICE` (+ `DATA_SYNC`, `SPECIAL_USE`) | İndirme ve yanıt üretiminin arka planda kesilmemesi |
| `POST_NOTIFICATIONS` | İndirme/üretim bildirimi |
| `WAKE_LOCK` | Uzun yanıtlarda cihazın uyumaması |
| `READ_EXTERNAL_STORAGE` (Android 12L ve altı) | ZIP dosya seçici |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Pil kısıtlaması muafiyeti isteği (isteğe bağlı) |

## Test

```bash
flutter test
```

## Bilinen sınırlamalar

- Yerel 7B sınıfı modellerin kalitesi bulut modellerinden düşüktür.
- Düşük RAM'li cihazlarda bağlam penceresi küçülür; çok uzun mesajlar sığmayabilir.
- `flutter_litert_lm` (`.litertlm` / `.task` modelleri) adaptörü henüz bağlanmamıştır; katalogdaki modeller GGUF'tur.

## Lisans

[MIT](LICENSE). Üçüncü taraf bileşenler ve model lisansları için bkz. [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
