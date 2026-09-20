import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Kahraman Dostum uygulaması için Text-to-Speech (TTS) servisi.
/// Google Cloud TTS API'sini bir Firebase Cloud Function üzerinden kullanır.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  TtsService._internal() {
    _initAudioPlayer();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final HttpsCallable _ttsFunction = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  ).httpsCallable(
    'textToSpeech',
    options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
  );

  final AudioPlayer _audioPlayer = AudioPlayer();
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);
  final ValueNotifier<String?> userMessage = ValueNotifier<String?>(null);

  static const String friendlyErrorMessage =
      'Kahraman Dostum şu an biraz dinleniyor, birazdan tekrar konuşabiliriz 💤';

  File? _lastTempFile;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _disposed = false;
  int _currentRequestTag = 0;

  void _initAudioPlayer() {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      (state) {
        if (state.processingState == ProcessingState.completed) {
          isSpeaking.value = false;
        }
      },
      onError: (e, stack) {
        _recordError(e, stack, reason: 'TTS_PLAYER_STREAM_ERROR');
        _showFriendlyError();
      },
    );
  }

  /// Verilen metni seslendirir.
  /// Concurrent (üst üste) çağrılarda son çağrı geçerli olur.
  Future<void> speak(String metin, {String voiceName = 'tr-TR-Wavenet-C'}) async {
    if (_disposed) return;

    final String temizMetin = _cleanText(metin);
    if (temizMetin.isEmpty) return;

    userMessage.value = null;
    final int requestTag = ++_currentRequestTag;

    try {
      await _stopCurrentPlayback();
      
      final User? user = _auth.currentUser;
      if (user == null) {
        isSpeaking.value = false;
        return;
      }

      isSpeaking.value = true;

      // Cloud Function çağrısı
      final result = await _ttsFunction.call({
        'metin': temizMetin,
        'voiceName': voiceName,
      });

      // Eğer bu isteğin cevabı gelene kadar yeni bir speak() çağrılmışsa iptal et
      if (requestTag != _currentRequestTag || _disposed) return;

      final data = result.data as Map?;
      final String audioContent = data?['audioContent']?.toString() ?? '';

      if (audioContent.isEmpty) {
        throw const FormatException('TTS_EMPTY_RESPONSE');
      }

      if (kIsWeb) {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse('data:audio/mp3;base64,$audioContent')),
        );
      } else {
        await _deletePreviousFile();
        final Directory directory = await getTemporaryDirectory();
        final String filePath =
            '${directory.path}/tts_${DateTime.now().microsecondsSinceEpoch}.mp3';
        final File file = File(filePath);
        await file.writeAsBytes(base64Decode(audioContent), flush: true);
        
        if (requestTag != _currentRequestTag || _disposed) {
          unawaited(file.delete());
          return;
        }

        _lastTempFile = file;
        await _audioPlayer.setFilePath(file.path);
      }

      if (requestTag == _currentRequestTag && !_disposed) {
        await _audioPlayer.play();
      }
    } catch (e, stack) {
      if (requestTag == _currentRequestTag) {
        debugPrint('TTS_ERROR: $e');
        _recordError(e, stack, reason: 'TTS_SPEAK_FAILED');
        isSpeaking.value = false;
        _showFriendlyError();
      }
    }
  }

  Future<void> stop() async {
    if (_disposed) return;
    await _stopCurrentPlayback();
  }

  Future<void> _stopCurrentPlayback() async {
    try {
      await _audioPlayer.stop();
      isSpeaking.value = false;
    } catch (e) {
      // Durdurma hatası kritik değil
    }
  }

  void _showFriendlyError() {
    if (_disposed) return;
    userMessage.value = friendlyErrorMessage;
    isSpeaking.value = false;
  }

  Future<void> _deletePreviousFile() async {
    final file = _lastTempFile;
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      // Silme hatası loglanabilir ama kullanıcıyı etkilemez
    } finally {
      _lastTempFile = null;
    }
  }

  String _cleanText(String text) {
    // Markdown ve gereksiz karakter temizliği
    return text
        .replaceAll(RegExp(r'[*_#>`]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _recordError(Object error, StackTrace stackTrace, {required String reason}) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _deletePreviousFile();
    isSpeaking.dispose();
    userMessage.dispose();
  }
}
