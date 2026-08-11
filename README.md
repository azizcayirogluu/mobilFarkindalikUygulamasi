# 🛡️ Siber Dost

<p align="center">
  <strong>Çocuklar ve gençler için akran zorbalığı, siber zorbalık ve dijital güvenlik farkındalık platformu.</strong>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img alt="Gemini" src="https://img.shields.io/badge/Gemini-4285F4?style=for-the-badge&logo=google-gemini&logoColor=white" />
  <img alt="TÜBİTAK 2209-A" src="https://img.shields.io/badge/TÜBİTAK_2209--A-1565C0?style=for-the-badge" />
</p>

> “Güvenli bir dijital gelecek, bilinçli nesillerle inşa edilir.”

## Proje Hakkında

**Siber Dost**, 6–18 yaş aralığındaki kullanıcıların akran zorbalığı, siber zorbalık ve dijital güvenlik hakkında bilgi edinmesini; güvenli kararlar için pratik yapmasını ve ihtiyaç duyduğunda doğru destek kanallarına yönelmesini amaçlayan bir Flutter uygulamasıdır.

Uygulama; öğretici içerikleri, etkileşimli senaryoları, güvenlik rehberini, olay bildirimini ve yapay zekâ destekli sohbet deneyimini aynı çatı altında toplar. Amaç; kullanıcıyı yargılamadan desteklemek, güvenli davranışları öğretmek ve yardım istemeyi kolaylaştırmaktır.

> **Önemli:** Siber Dost, profesyonel psikolojik destek, sağlık hizmeti veya acil yardım hizmetlerinin yerine geçmez. Kullanıcı kendisi ya da bir başkası için acil tehlike hissediyorsa 112 Acil Çağrı Merkezi’ne veya yakındaki güvenilir bir yetişkine başvurmalıdır.

## Öne Çıkan Özellikler

### 🎓 Eğitsel ve etkileşimli içerikler

- Zorbalık farkındalığı için senaryolar ve karar akışları
- Siber Dedektif ile güvenli internet davranışlarına yönelik soru/cevap deneyimi
- Hikâyeler ve video içerikleri
- Tamamlanan içerikler için ilerleme, rozet ve motivasyon sistemi

### 🧭 Güvenlik Rehberi

- Zorbalığı tanıma, güvenli kalma, siber zorbalıkla baş etme ve yardım isteme bölümleri
- Sabit, profesyonel olarak hazırlanmış Türkçe ses kayıtlarıyla çevrim dışı dinleme deneyimi
- Hızlı güvenlik planı ve Siber Asistan’a doğrudan geçiş

### 🚨 Siber İmdat ve olay bildirimi

- Acil destek numaralarına yönlendirme
- Güvenlik adımlarını takip etmek için kontrol listesi
- Yaşanan olayı yöneticilere iletmek için olay bildirim formu
- Yakındaki yardım noktalarını harita uygulamasında açma

### 🤖 Yapay zekâ destekli Siber Asistan

- Firebase Cloud Functions üzerinden çalışan, yaşa uygun sohbet deneyimi
- Zorbalık, arkadaşlık, okul hayatı ve güvenli iletişim odaklı yönlendirme
- Mesaj uzunluğu, sohbet geçmişi ve istek sıklığı için sunucu tarafı sınırlar
- Riskli ifadelerde kullanıcıyı güvenilir yetişkinlere ve Güvenlik Merkezi’ne yönlendirmeye odaklı içerik tasarımı

### 🔐 Hesap ve veri yönetimi

- Firebase Authentication ile kullanıcı oturumu
- Cloud Firestore ile gerçek zamanlı ilerleme ve içerik verileri
- Firebase App Check desteği
- Kullanıcının kendi hesabını ve ilişkili verilerini silmesine yönelik akış
- Rol tabanlı yönetici paneli

## Ekran Görüntüleri

<p align="center">
  <img width="220" alt="Ana ekran" src="https://github.com/user-attachments/assets/99218e75-1c55-4e1c-b585-26d59e9dee54" />
  <img width="220" alt="Senaryo ekranı" src="https://github.com/user-attachments/assets/0389573d-eb3d-479e-9bb4-a48cde9dad55" />
  <img width="220" alt="Siber Dedektif" src="https://github.com/user-attachments/assets/0800738b-33a3-4634-b09b-e8a4c830ec33" />
  <img width="220" alt="Siber Asistan" src="https://github.com/user-attachments/assets/6918573a-0206-4aa5-9386-ebf5d6ab0e7d" />
</p>

<p align="center">
  <img width="220" alt="Rozetler" src="https://github.com/user-attachments/assets/9afbf129-35e3-4ea4-9ae9-bd142d29cadb" />
  <img width="220" alt="Güvenlik Merkezi" src="https://github.com/user-attachments/assets/3568e6d6-d156-4767-ae3f-0a162182b383" />
  <img width="220" alt="Güvenlik Rehberi" src="https://github.com/user-attachments/assets/6289aefc-58c0-4298-92e5-d69329cacfe7" />
  <img width="220" alt="Hakkında" src="https://github.com/user-attachments/assets/eb3bfecd-8992-4df0-acfd-a9c7b0963eb5" />
</p>

## Teknik Yapı

| Katman | Kullanılan teknoloji |
| --- | --- |
| Mobil uygulama | Flutter / Dart |
| Kimlik doğrulama | Firebase Authentication |
| Veritabanı | Cloud Firestore |
| Sunucu işlevleri | Firebase Cloud Functions (Node.js) |
| Yapay zekâ | Google Gemini, yalnızca Cloud Functions üzerinden |
| Güvenlik | Firebase App Check, Firestore Rules, Storage Rules |
| Bildirimler | Firebase Cloud Messaging ve yerel bildirimler |
| Reklam | Google Mobile Ads rewarded ads |
| Ses | `just_audio` ile uygulama içi MP3 oynatma |

Proje; `data`, `domain`, `services`, `screens` ve `admin_panel` klasörleriyle sorumlulukları ayrıştıran katmanlı bir Flutter yapısı kullanır.

```text
lib/
├── admin_panel/       # Yönetici ekranları ve yönetim araçları
├── core/              # Uygulama çekirdeği ve yardımcı altyapı
├── data/              # Modeller, veri kaynakları ve repository implementasyonları
├── domain/            # Repository sözleşmeleri
├── screens/           # Kullanıcı ekranları
├── services/          # Firestore, bildirim, analiz, raporlama ve reklam servisleri
├── app_theme.dart
├── firebase_options.dart
└── main.dart

functions/
└── index.js           # Gemini ve kullanıcı hesabı işlemleri için Cloud Functions
```

## Kurulum

### Gereksinimler

- Flutter SDK (projedeki `pubspec.yaml` ile uyumlu sürüm)
- Firebase CLI
- Node.js 22 veya `functions/package.json` içindeki sürümle uyumlu Node.js
- Firebase projesine erişim yetkisi

### 1. Repoyu klonlayın

```bash
git clone https://github.com/azizcayirogluu/mobilFarkindalikUygulamasi.git
cd mobilFarkindalikUygulamasi
```

### 2. Flutter bağımlılıklarını yükleyin

```bash
flutter pub get
```

### 3. Firebase yapılandırmasını hazırlayın

Firebase projenizi kendi ortamınıza bağlayın ve platform yapılandırmasını üretin:

```bash
flutterfire configure
```

Bu işlem `lib/firebase_options.dart` dosyasını günceller. Gerçek proje kimliklerini veya gizli yapılandırma dosyalarını herkese açık depolara eklemeyin.

### 4. Cloud Functions bağımlılıklarını yükleyin

```bash
cd functions
npm ci
cd ..
```

### 5. Gemini anahtarını güvenli olarak tanımlayın

Gemini anahtarını Flutter istemcisine koymayın. Anahtar, Firebase secret olarak saklanmalıdır:

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

### 6. Ses dosyalarını ekleyin

Güvenlik Rehberi için aşağıdaki dosyaları `assets/audio/` altına ekleyin:

```text
zorbaligi_tani.mp3
guvende_kal.mp3
siber_zorbalik.mp3
arkadasina_destek_ol.mp3
yardim_iste.mp3
hizli_guvenlik_plani.mp3
```

`pubspec.yaml` dosyasında `assets/` tanımı bulunduğundan bu klasör varlık paketine dâhil edilir.

### 7. Uygulamayı çalıştırın

```bash
flutter run
```

## Firebase Functions dağıtımı

Cloud Functions’ı dağıtmadan önce Firebase projesinin doğru seçildiğini doğrulayın:

```bash
firebase use
firebase deploy --only functions
```

Uygulamanın çağırdığı callable fonksiyonlar `europe-west1` bölgesiyle uyumlu olmalıdır. AdMob Server-Side Verification kullanılıyorsa callback URL’si ve deploy edilen fonksiyon adı da ayrıca doğrulanmalıdır.

## Test ve kalite kontrolleri

```bash
flutter analyze
flutter test
```

Yayın öncesi ayrıca şunları kontrol edin:

- Fiziksel Android ve iOS cihazda giriş, kayıt, çıkış ve hesap silme akışı
- Ses dosyalarının internet bağlantısı olmadan oynatılması
- Olay bildiriminin yönetici panelinde görünmesi
- Siber Asistan’da ağ kesintisi, boş cevap ve zaman aşımı davranışı
- Firebase App Check’in release ortamında etkin çalışması
- Rewarded reklam sonrası Gemini hakkının yalnızca doğrulanmış sunucu callback’i ile güncellenmesi

## Güvenlik ve gizlilik ilkeleri

- Gemini anahtarı istemciye eklenmez; yalnızca sunucu ortamında kullanılır.
- Yönetici erişimi Firebase custom claims ve Firestore kurallarıyla sınırlandırılmalıdır.
- Olay bildirimleri hassas veri içerebilir; yalnızca yetkili yöneticiler erişebilmelidir.
- Kullanıcılar, hesap silme akışıyla kişisel verilerinin silinmesini talep edebilmelidir.
- Uygulama içindeki yönlendirmeler destekleyicidir; acil durumlarda profesyonel ve yerel yardım kanalları esas alınır.

## Katkı ve geliştirme

Katkı sağlamak için önce bir issue açarak önerinizi veya hatayı paylaşın. Değişikliklerde:

1. Kodun analiz ve testlerden geçtiğini doğrulayın.
2. Kullanıcı güvenliği ve gizliliğini etkileyen değişiklikleri açıkça belgeleyin.
3. Yeni kullanıcı metinlerini yaşa uygun, yargılamayan ve sade bir dille yazın.

---

<p align="center">
  <strong>Siber Dost</strong> · Dijital dünyada daha bilinçli, daha güvenli adımlar için.
</p>
