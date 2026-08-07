<div align="center">

  # 🛡️ Siber Dost: Yapay Zeka Destekli Farkındalık Platformu
  ### Akran, Siber ve Psikolojik Zorbalığa Karşı Akıllı & Empatik Dijital Rehber

  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
  [![Gemini AI](https://img.shields.io/badge/Gemini_2.5_Flash-8E75B2?style=for-the-badge&logo=google-gemini&logoColor=white)](https://deepmind.google/technologies/gemini/)
  [![Clean Architecture](https://img.shields.io/badge/Clean_Architecture-4CAF50?style=for-the-badge&logo=dependabot&logoColor=white)](#)
  [![TÜBİTAK 2209-A](https://img.shields.io/badge/TÜBİTAK_2209--A-Approved-blue?style=for-the-badge)](#)

  **"Güvenli bir dijital gelecek, bilinçli nesillerle inşa edilir."**

</div>

---

## 📝 Proje Vizyonu

**Siber Dost**, 6-18 yaş aralığındaki çocuk ve gençlerin dijital ve sosyal ekosistemlerde karşılaşabilecekleri zorbalık türlerine karşı "aktif korunma" ve "farkındalık" kazanmaları için geliştirilmiş bir **EdTech (Eğitim Teknolojisi)** çözümüdür.

Sıradan rehberlik uygulamalarının aksine **Siber Dost**; kullanıcı davranışlarını analiz eden, zayıf noktaları saptayan ve tehlike anında proaktif aksiyon alan hibrit bir yapay zeka mimarisi üzerine kurulmuştur.

---

## 🚀 Öne Çıkan İleri Seviye Özellikler

### 🧠 Context-Aware AI Mentörlük (Gemini 2.5 Flash Entegrasyonu)
* **Hata Analiz Motoru:** Kullanıcının interaktif senaryolarda yaptığı yanlış tercihler Cloud Firestore üzerinde anonim olarak analiz edilir.
* **Kişiselleştirilmiş Müfredat:** Siber Asistan, kullanıcının eksik olduğu konuları (örn: şifre güvenliği, kişisel veri gizliliği, siber şantaj) saptayarak sohbeti dinamik şekilde yönlendirir.

### 🚨 Proaktif SOS & Tehlike Tespit Sistemi
* **Semantik Analiz:** Kullanıcı mesajlarındaki korku, tehdit veya şantaj emareleri doğal dil işleme (NLP) yetenekleriyle gerçek zamanlı taranır.
* **Otomatik Yönlendirme:** Kritik bir tehdit algılandığında sistem `[TEHLIKE_TESPIT]` bayrağı ile kullanıcıyı anında acil destek hatlarına ve **Siber İmdat** rehberine yönlendirir.

### 🎮 Gamified Learning (Siber Dedektif)
* **Dinamik Senaryolar:** Gerçek hayat simülasyonları ile siber zorbalık anında doğru karar verme pratiği.
* **Rozet ve Sertifika Sistemi:** Tamamlanan eğitim modülleri ve başarılar sonrasında dijital rozetlerle motivasyon yönetimi.

---

## 🛠️ Teknik Mimari ve Proje Yapısı

Proje, sürdürülebilirlik, ölçeklenebilirlik ve test edilebilirlik için **Clean Architecture** prensiplerine uygun olarak katmanlandırılmıştır.

```text
lib/
 ├── core/              # Sabitler, temalar, yardımcı servisler (Security, AI)
 ├── data/              # Model, DTO ve Firebase/Gemini API Data Source'ları
 ├── domain/            # UseCase'ler ve Repository arayüzleri
 └── presentation/      # UI Ekranları, Widget'lar ve State Management (Provider/Riverpod)
