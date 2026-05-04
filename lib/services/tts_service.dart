import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  File?
  _lastTempFile; // Son oluşturulan geçici dosyayı takip eder (bellek yönetimi)

  Future<void> speak(
    String metin, {
    String voiceName = "tr-TR-Wavenet-C",
  }) async {
    if (metin.isEmpty) return;

    try {
      isSpeaking.value = true;
      // Mevcut çalma varsa durdur
      await _audioPlayer.stop();

      String temizMetin = metin.replaceAll(RegExp(r'[*_#>]'), '');

      final response = await http
          .post(
            Uri.parse(
              'https://texttospeech.googleapis.com/v1/text:synthesize?key=$_googleApiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "input": {"text": temizMetin},
              "voice": {"languageCode": "tr-TR", "name": voiceName},
              "audioConfig": {"audioEncoding": "MP3", "speakingRate": 1.0},
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String audioContent = data['audioContent'];

        if (kIsWeb) {
          await _audioPlayer.setAudioSource(
            AudioSource.uri(Uri.parse("data:audio/mp3;base64,$audioContent")),
          );
        } else {
          // Önceki geçici dosyayı temizle (depolama şişmesini önler)
          if (_lastTempFile != null && await _lastTempFile!.exists()) {
            await _lastTempFile!.delete();
          }
          final dir = await getTemporaryDirectory();
          final file = File(
            '${dir.path}/tts_cache_${DateTime.now().millisecondsSinceEpoch}.mp3',
          );
          await file.writeAsBytes(base64Decode(audioContent));
          _lastTempFile = file;
          await _audioPlayer.setFilePath(file.path);
        }

        // Sesin bitmesini beklemek için kesin yöntem
        await _audioPlayer.play();

        // Ses bitene kadar burada bekle (Akışı bloklar, böylece ekran tarafındaki await çalışır)
        await _audioPlayer.playerStateStream.firstWhere(
          (state) => state.processingState == ProcessingState.completed,
        );
      }
    } catch (e) {
      debugPrint("TTS HATA: $e");
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
