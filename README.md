<div align="center">

# Siber Dost | Kahraman Dostum

Çocuk ve gençlere zorbalık karşısında güvenli seçimleri ve dijital dünyada bilinçli davranışları interaktif içeriklerle öğreten bir Flutter uygulaması.

<img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img alt="Firebase" src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img alt="Gemini" src="https://img.shields.io/badge/Gemini-4285F4?style=for-the-badge&logo=google-gemini&logoColor=white" />

</div>

## Proje Hakkında

Siber Dost, **6–18 yaş** grubundaki çocuk ve gençlerin akran zorbalığı, siber zorbalık ve dijital güvenlik konularında farkındalık kazanmasını destekler. Yaş grubuna göre sunulan senaryoları, eğitici içerikleri ve yardım kaynaklarını tek bir mobil uygulamada bir araya getirir.

## Özellikler

- **İnteraktif senaryolar:** Kullanıcılar yaş gruplarına göre sunulan senaryolarda seçimler yapar ve sonuçlarını inceler.
- **Siber Dedektif:** Güvenli ve riskli çevrimiçi davranışları ayırt etmeye yönelik soru tabanlı bir oyun sunar.
- **Hikâyeler ve videolar:** Eğitici hikâyeler ile video içeriklerine uygulama içinden erişilebilir.
- **Siber Asistan:** Gemini destekli sohbet, Firebase Cloud Functions üzerinden çalışır. İstekler kullanıcı yaş grubuna göre hazırlanır.
- **Rozetler ve ilerleme:** Tamamlanan etkinlikler ve kullanıcı ilerlemesi uygulamada takip edilir.
- **Güvenlik rehberi:** Zorbalığı tanıma, dijital güvenlik ve yardım isteme adımlarını metin ve ses içerikleriyle sunar.
- **Siber İmdat ve olay bildirimi:** Siber İmdat ekranında 112 ve 183 numaralarına arama bağlantıları ve güvenlik yönlendirmeleri bulunur. Firestore kuralları kullanıcının kendi rapor kaydını oluşturmasına izin verir; ancak uygulama içindeki olay gönderim akışı kodda doğrulanamadı.
- **PDF raporlama:** Yönetici panelinde PDF oluşturma seçeneği vardır; mevcut üretici yalnızca temel bir “SISTEM OZETI” çıktısı oluşturur, ayrıntılı veri raporu üretmez.

## Güvenlik ve Gizlilik

- **Firebase Authentication:** Uygulama kullanıcı oturumlarını Firebase Authentication ile yönetir.
- **Firestore kuralları:** Kullanıcı verilerine sahiplik ve yönetici rolüne göre erişim uygulanır. İçerik yazma yöneticiyle sınırlıdır; rapor oluşturma kuralı oturum açmış kullanıcının kendi UID'sini şart koşar.
- **Firebase App Check:** Android ve iOS istemcilerinde yapılandırılmıştır. Debug yapılarında debug sağlayıcıları, üretim yapılarında Play Integrity ve Apple App Attest (DeviceCheck geri dönüşü) kullanılır. Bununla birlikte, Cloud Functions tarafında birçok çağrılabilir işlev için `enforceAppCheck: false` ayarlıdır; App Check tüm uç noktalarda sunucu tarafında zorunlu değildir.
- **Cloud Functions ve API anahtarı:** Gemini çağrıları sunucu tarafındaki callable function üzerinden yapılır; `GEMINI_API_KEY` function secret olarak tanımlanmıştır. Gemini sohbet işlevi kimlik doğrulama, girdi uzunluğu ve hız sınırı kontrolleri uygular.
- **Yönetici yetkisi:** Yönetici rolü Firebase Auth custom claim'i (`admin`) ile ve Firestore kurallarında kontrol edilir.
- **Hesap silme:** Callable function; hesap profili, ilerleme kaydı, ilişkili raporlar ve belirli işlem kayıtlarını silip Firebase Authentication kullanıcısını kaldırır.

Bu açıklamalar kod deposunda görülen uygulama yapılandırmasını ve kuralları özetler; dağıtılmış Firebase projesinin canlı ayarlarını veya mevzuata/politikalara uyumluluğunu garanti etmez.

## Teknoloji Yığını

| Alan | Kullanılan teknolojiler |
| :--- | :--- |
| Mobil uygulama | Flutter, Dart (SDK `3.9.2+`), GetIt |
| Backend ve kimlik | Firebase Authentication, Cloud Firestore, Cloud Functions v2 (Node.js 22), Firebase App Check, Cloud Messaging, Crashlytics, Firebase Hosting |
| Yapay zekâ ve ses | Gemini API (`gemini-3.8-flash`, sunucu tarafında), Google Cloud Text-to-Speech |
| İçerik ve arayüz | YouTube Player IFrame, just_audio, flutter_animate, cached_network_image, confetti |
| Dışa aktarma ve reklam | `pdf`, `printing`, `excel`, Google Mobile Ads |

## Ekran Görüntüleri

<table>
  <tr>
    <td align="center"><img width="180" alt="Ana ekran" src="https://github.com/user-attachments/assets/99218e75-1c55-4e1c-b585-26d59e9dee54" /><br><b>Ana Ekran</b></td>
    <td align="center"><img width="180" alt="Senaryo ekranı" src="https://github.com/user-attachments/assets/0389573d-eb3d-479e-9bb4-a48cde9dad55" /><br><b>Senaryolar</b></td>
  </tr>
  <tr>
    <td align="center"><img width="180" alt="Siber Dedektif" src="https://github.com/user-attachments/assets/0800738b-33a3-4634-b09b-e8a4c830ec33" /><br><b>Siber Dedektif</b></td>
    <td align="center"><img width="180" alt="Siber Asistan" src="https://github.com/user-attachments/assets/6918573a-0206-4aa5-9386-ebf5d6ab0e7d" /><br><b>Siber Asistan</b></td>
  </tr>
  <tr>
    <td align="center"><img width="180" alt="Rozetler" src="https://github.com/user-attachments/assets/9afbf129-35e3-4ea4-9ae9-bd142d29cadb" /><br><b>Rozet Koleksiyonu</b></td>
    <td align="center"><img width="180" alt="Siber İmdat" src="https://github.com/user-attachments/assets/3568e6d6-d156-4767-ae3f-0a162182b383" /><br><b>Siber İmdat</b></td>
  </tr>
  <tr>
    <td align="center"><img width="180" alt="Güvenlik Rehberi" src="https://github.com/user-attachments/assets/6289aefc-58c0-4298-92e5-d69329cacfe7" /><br><b>Güvenlik Rehberi</b></td>
    <td align="center"><img width="180" alt="Hakkında ekranı" src="https://github.com/user-attachments/assets/eb3bfecd-8992-4df0-acfd-a9c7b0963eb5" /><br><b>Hakkında</b></td>
  </tr>
</table>

## Yasal Uyarı

**Siber Dost | Kahraman Dostum**, eğitim ve farkındalık amacı taşır; profesyonel psikolojik, tıbbi veya hukuki desteğin ve acil yardım hizmetlerinin yerine geçmez. Acil tehlike durumunda **112'yi arayın** ve güvendiğiniz bir yetişkinden yardım isteyin.
