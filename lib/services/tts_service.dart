import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _googleApiKey = dotenv.env['GOOGLE_CLOUD_TTS_KEY'] ?? "";

  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  Future<void> speak(String metin, {String voiceName = "tr-TR-Wavenet-C"}) async {
    if (metin.isEmpty) return;
    
    if (_googleApiKey.isEmpty) {
      debugPrint("HATA: Google Cloud API Key bulunamadı! .env dosyasını kontrol et.");
      return;
    }

    try {
      isSpeaking.value = true;
      debugPrint("TTS Başlatılıyor: $metin");

      String temizMetin = metin.replaceAll(RegExp(r'[*_#>]'), '');
      
      final response = await http.post(
        Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize?key=$_googleApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "input": {"text": temizMetin},
          "voice": {
            "languageCode": "tr-TR",
            "name": voiceName, 
            "ssmlGender": voiceName.contains("Wavenet-B") ? "MALE" : "FEMALE"
          },
          "audioConfig": {
            "audioEncoding": "MP3",
            "pitch": 0.0,
            "speakingRate": 1.05
          }
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String audioContent = data['audioContent'];
        final bytes = base64Decode(audioContent);

        if (kIsWeb) {
          // WEB İÇİN: Data URI kullanarak çal
          await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse("data:audio/mp3;base64,$audioContent")));
        } else {
          // MOBİL İÇİN: Dosyaya yazarak çal
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/tts_cache.mp3');
          await file.writeAsBytes(bytes);
          await _audioPlayer.setFilePath(file.path);
        }
        
        await _audioPlayer.play();
        debugPrint("Ses başarıyla çalınıyor.");
      } else {
        debugPrint("API HATASI: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("TTS SERVİS KRİTİK HATA: $e");
    } finally {
      isSpeaking.value = false;
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    isSpeaking.value = false;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
