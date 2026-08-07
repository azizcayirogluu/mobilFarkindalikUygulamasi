import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Cloud Function referansı (API anahtarı sunucuda)
  final HttpsCallable _ttsFn =
      FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('textToSpeech');

  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);
  File? _lastTempFile;
  StreamSubscription? _playerStateSubscription;

  Future<void> speak(
    String metin, {
    String voiceName = "tr-TR-Wavenet-C",
  }) async {
    if (metin.isEmpty) return;

    try {
      // 1. Concurrency Safety: Önceki dinleyiciyi iptal et ve çalan sesi durdur
      await _playerStateSubscription?.cancel();
      await _audioPlayer.stop();
      isSpeaking.value = true;

      String temizMetin = metin.replaceAll(RegExp(r'[*_#>]'), '');

      // Cloud Function çağrısı
      final result = await _ttsFn.call({
        'metin': temizMetin,
        'voiceName': voiceName,
      });

      final String audioContent = result.data['audioContent'] ?? '';
      if (audioContent.isEmpty) {
        isSpeaking.value = false;
        return;
      }

      if (kIsWeb) {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse("data:audio/mp3;base64,$audioContent")),
        );
      } else {
        // Önceki geçici dosyayı güvenle temizle
        if (_lastTempFile != null && await _lastTempFile!.exists()) {
          try {
            await _lastTempFile!.delete();
          } catch (_) {}
        }
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/tts_cache_${DateTime.now().millisecondsSinceEpoch}.mp3',
        );
        await file.writeAsBytes(base64Decode(audioContent));
        _lastTempFile = file;
        await _audioPlayer.setFilePath(file.path);
      }

      await _audioPlayer.play();

      // 2. Memory & Event Safety: Engelleyici firstWhere yerine abonelik (StreamSubscription) yönetimi
      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          isSpeaking.value = false;
          _playerStateSubscription?.cancel();
        }
      });

    } on FirebaseFunctionsException catch (e) {
      debugPrint("TTS Cloud Function Hatası: ${e.code} - ${e.message}");
      isSpeaking.value = false;
    } catch (e) {
      debugPrint("TTS HATA: $e");
      isSpeaking.value = false;
    }
  }

  Future<void> stop() async {
    await _playerStateSubscription?.cancel();
    await _audioPlayer.stop();
    isSpeaking.value = false;
  }

  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
  }
}
