# 🛡️ Siber Dost (Kahraman Dostum)

<p align="center">
  <strong>Çocuklar ve gençler için akran zorbalığı, siber zorbalık ve dijital güvenlik farkındalığı platformu.</strong>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img alt="Gemini" src="https://img.shields.io/badge/Gemini-4285F4?style=for-the-badge&logo=google-gemini&logoColor=white" />
  <img alt="TÜBİTAK 2209-A" src="https://img.shields.io/badge/TÜBİTAK_2209--A-1565C0?style=for-the-badge" />
</p>

---

### 🌟 "Güvenli bir dijital gelecek, bilinçli nesillerle inşa edilir."

**Siber Dost**, 6–18 yaş aralığındaki çocukların ve gençlerin akran zorbalığı, siber zorbalık ve dijital dünyadaki tehditler hakkında eğlenerek farkındalık kazanması amacıyla geliştirilmiş **yapay zekâ destekli** mobil platformdur. Proje, modern pedagojik yaklaşımlarla dijital güvenliği birleştirerek çocukları yargılamadan desteklemeyi, doğru rehberlik sunmayı ve gerektiğinde yardım istemeyi öğretmeyi amaçlamaktadır.

> 🏆 **Proje Desteği:** Bu çalışma, çocuklarda dijital farkındalık ve siber güvenlik bilinci oluşturmaya yönelik yenilikçi yaklaşımıyla **TÜBİTAK 2209-A Üniversite Öğrencileri Araştırma Projeleri Destekleme Programı** kapsamında desteklenmektedir.

---

## 🎨 Öne Çıkan Özellikler

### 🎓 Eğitsel ve Etkileşimli İçerikler
* **İnteraktif Senaryolar:** Yaş gruplarına özel olarak hazırlanan karar akışları sayesinde çocuklar, zorbalık anında verebilecekleri kararların sonuçlarını güvenli bir simülasyonda deneyimler.
* **Siber Dedektif Oyunu:** Çocukların dijital ayak izlerini ve internetteki tehlikeli davranışları bir dedektif gibi inceleyerek analiz ettiği soru/cevap ve oyun tabanlı öğrenme modülü.
* **Multimedya Kütüphanesi:** Özenle seçilmiş pedagojik hikayeler, eğitici animasyonlar ve video içerikleri.
* **Rozet & Motivasyon Sistemi:** Tamamlanan her görev, okunan her hikaye için çocukları teşvik eden efsanevi siber koruyucu rozetleri ve ilerleme takibi.

### 🧭 Güvenlik Rehberi & Çevrim Dışı Dinleme
* Zorbalığı tanıma, siber zorbalıkla baş etme ve profesyonel yardım isteme adımlarını içeren kapsamlı rehber.
* **Kesintisiz Ses Deneyimi:** İnternet bağlantısı olmasa bile profesyonel Türkçe ses kayıtlarıyla rehberi sesli dinleyebilme (ExoPlayer entegrasyonu ile sıfır gecikme).
* **Hızlı Güvenlik Planı:** Acil anlarda çocukların uygulayabileceği 3 adımlı pratik eylem planı.

### 🤖 Yapay Zekâ Destekli Siber Asistan
* **Firebase Cloud Functions** üzerinden güvenli bir şekilde çalışan, yaş gruplarına özel filtrelenmiş **Gemini 1.5 Flash** entegrasyonu.
* Zorbalık, arkadaşlık ilişkileri ve okul hayatına odaklı, çocuk psikolojisine uygun 7/24 interaktif rehberlik.
* **Çevrim Dışı Kural Motoru:** İnternet kesildiğinde bile yerel kural tabanlı yapay zekâ motoru sayesinde kesintisiz koruma ve analiz.
* **Enerji (Hak) & Reklam Entegrasyonu:** AdMob ödüllü reklam yapısıyla çocukları suistimalden koruyan, sunucu taraflı hız limitleri (Rate Limiting) ve günlük hak sistemi.

### 🚨 Siber İmdat & Olay Bildirimi
* Resmi yardım kanallarına (112 Acil Çağrı, siber ihbar noktaları) hızlı yönlendirme.
* **Olay Bildirim Formu:** Yaşanılan siber veya akran zorbalığı olaylarını yetkili yöneticilere güvenli ve anonim olarak iletebilme altyapısı.
* PDF formatında kurumsal rapor oluşturma ve yazdırma desteği.

---

## 🔒 Güvenlik ve Gizlilik Mimarisi

Proje, çocuk verilerinin gizliliğini en üst düzeyde tutmak için endüstri standardı güvenlik protokolleriyle donatılmıştır:

* **Gizli API Yönetimi:** Gemini API anahtarları asla istemci (client) tarafında barındırılmaz; tamamen sunucu (Firebase Cloud Functions) ortamında ve şifrelenmiş sırlar (Secrets Manager) olarak saklanır.
* **Firebase App Check & Play Integrity:** Uygulama içi isteklere sahte cihazlardan veya botlardan gelen suistimalleri engellemek için Google Play Integrity ve Apple App Attest altyapıları entegre edilmiştir.
* **Gelişmiş Firestore & Storage Kuralları:** Rol tabanlı erişim kontrolü sayesinde kullanıcı raporlarına ve hassas ilerleme verilerine sadece yetkili yöneticiler ve ilgili verinin sahibi olan kullanıcı erişebilir.
* **Veri Senkronizasyonu & Custom Claims:** Yönetici yetkilendirmeleri sunucu tarafında atomik Firestore tetikleyicileri ve Auth Custom Claims ile anlık olarak doğrulanır.
* **Hesap ve Veri Silme Güvencesi:** Kullanıcılar, Google Play politikalarıyla %100 uyumlu şekilde, profilleri üzerinden tek tıkla tüm kişisel verilerini, raporlarını ve hesaplarını kalıcı olarak silebilirler (GDPR/KVKK uyumlu veri temizliği).

---

## 🛠️ Kullanılan Teknolojiler

* **Frontend:** Flutter (Dart) - Nesne yönelimli, temiz mimari (Clean Architecture) ve bağımlılık enjeksiyonu (GetIt) kullanımı.
* **Backend:** Firebase (Authentication, Cloud Firestore, Cloud Functions v2, Firebase Hosting, Cloud Messaging).
* **Yapay Zekâ:** Google Gemini API (`gemini-1.5-flash`), Google Cloud Text-to-Speech API (Seslendirme entegrasyonu).
* **Multimedya & UI:** Just Audio, Youtube Player Iframe, Flutter Animate, Cached Network Image, FL Chart.
* **Reklam & Analiz:** Google Mobile Ads (AdMob Rewarded Ads), Firebase Crashlytics, Firebase Analytics.

---

## 📱 Ekran Görüntüleri

<table>
  <tr>
    <td><img width="220" alt="Ana ekran" src="https://github.com/user-attachments/assets/99218e75-1c55-4e1c-b585-26d59e9dee54" /></td>
    <td><img width="220" alt="Senaryo ekranı" src="https://github.com/user-attachments/assets/0389573d-eb3d-479e-9bb4-a48cde9dad55" /></td>
    <td><img width="220" alt="Siber Dedektif" src="https://github.com/user-attachments/assets/0800738b-33a3-4634-b09b-e8a4c830ec33" /></td>
    <td><img width="220" alt="Siber Asistan" src="https://github.com/user-attachments/assets/6918573a-0206-4aa5-9386-ebf5d6ab0e7d" /></td>
  </tr>
  <tr>
    <td><img width="220" alt="Rozetler" src="https://github.com/user-attachments/assets/9afbf129-35e3-4ea4-9ae9-bd142d29cadb" /></td>
    <td><img width="220" alt="Güvenlik Merkezi" src="https://github.com/user-attachments/assets/3568e6d6-d156-4767-ae3f-0a162182b383" /></td>
    <td><img width="220" alt="Güvenlik Rehberi" src="https://github.com/user-attachments/assets/6289aefc-58c0-4298-92e5-d69329cacfe7" /></td>
    <td><img width="220" alt="Hakkında" src="https://github.com/user-attachments/assets/eb3bfecd-8992-4df0-acfd-a9c7b0963eb5" /></td>
  </tr>
</table>

---

## 📝 Önemli Yasal Uyarı

**Siber Dost (Kahraman Dostum)**, eğitsel ve farkındalık oluşturma amaçlı bir platformdur; profesyonel psikolojik destek, tıbbi tanı, hukuki danışmanlık veya acil yardım hizmetlerinin yerine geçmez. Kullanıcı kendisi veya bir başkası için acil bir fiziksel/siber tehlike hissediyorsa, vakit kaybetmeden **112 Acil Çağrı Merkezi**'ne veya güvenilir bir yetişkine başvurmalıdır.

---
<p align="center">
  <strong>Siber Dost</strong> · Dijital dünyada daha bilinçli, daha güvenli ve daha cesur adımlar için.
</p>
