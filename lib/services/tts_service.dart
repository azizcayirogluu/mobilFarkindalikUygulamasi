import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();

  factory TtsService() => _instance;

  TtsService._internal();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final HttpsCallable _ttsFunction =
  FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  ).httpsCallable(
    'textToSpeech',
    options: HttpsCallableOptions(
      timeout: const Duration(seconds: 60),
    ),
  );

  // ============================================================
  // AUDIO
  // ============================================================

  final AudioPlayer _audioPlayer = AudioPlayer();

  final ValueNotifier<bool> isSpeaking =
  ValueNotifier<bool>(false);

  File? _lastTempFile;

  StreamSubscription<PlayerState>? _playerStateSubscription;

  bool _disposed = false;

  // ============================================================
  // SPEAK
  // ============================================================

  Future<void> speak(
      String metin, {
        String voiceName = 'tr-TR-Wavenet-C',
      }) async {
    if (_disposed) {
      debugPrint('TTS: Service dispose edilmiş.');
      return;
    }

    final String temizMetin = _cleanText(metin);

    if (temizMetin.isEmpty) {
      debugPrint('TTS: Boş metin gönderildi.');
      return;
    }

    try {
      // --------------------------------------------------------
      // 1. AKTİF SESİ DURDUR
      // --------------------------------------------------------

      await _stopCurrentPlayback();

      // --------------------------------------------------------
      // 2. FIREBASE AUTH KONTROLÜ
      // --------------------------------------------------------

      User? user = _auth.currentUser;

      if (user == null) {
        debugPrint(
          'TTS AUTH HATASI: FirebaseAuth.currentUser == null',
        );

        isSpeaking.value = false;
        return;
      }

      debugPrint(
        'TTS AUTH: Kullanıcı bulundu: ${user.uid}',
      );

      // --------------------------------------------------------
      // 3. TOKEN'ı YENİLE
      //
      // Callable Function'a güncel Firebase Auth token'ının
      // gönderildiğinden emin oluyoruz.
      // --------------------------------------------------------

      try {
        await user.getIdToken(true);

        // Token yenilendikten sonra currentUser tekrar alınır.
        user = _auth.currentUser;

        if (user == null) {
          debugPrint(
            'TTS AUTH HATASI: Token yenileme sonrası kullanıcı yok.',
          );

          isSpeaking.value = false;
          return;
        }

        debugPrint(
          'TTS AUTH: Firebase ID token hazır.',
        );
      } catch (e) {
        debugPrint(
          'TTS AUTH TOKEN HATASI: $e',
        );

        isSpeaking.value = false;
        return;
      }

      // --------------------------------------------------------
      // 4. LOADING
      // --------------------------------------------------------

      isSpeaking.value = true;

      // --------------------------------------------------------
      // 5. CLOUD FUNCTION
      // --------------------------------------------------------

      debugPrint(
        'TTS: Cloud Function çağrılıyor...',
      );

      debugPrint(
        'TTS: Function = textToSpeech',
      );

      debugPrint(
        'TTS: Region = europe-west1',
      );

      final HttpsCallableResult<dynamic> result =
      await _ttsFunction.call({
        'metin': temizMetin,
        'voiceName': voiceName,
      });

      // --------------------------------------------------------
      // 6. RESPONSE
      // --------------------------------------------------------

      final dynamic data = result.data;

      if (data == null) {
        throw Exception(
          'TTS Function boş response döndürdü.',
        );
      }

      if (data is! Map) {
        throw Exception(
          'TTS Function geçersiz response döndürdü.',
        );
      }

      final String audioContent =
          data['audioContent']?.toString() ?? '';

      if (audioContent.isEmpty) {
        throw Exception(
          'TTS Function audioContent döndürmedi.',
        );
      }

      debugPrint(
        'TTS: Audio başarıyla alındı. '
            'Base64 uzunluğu: ${audioContent.length}',
      );

      // --------------------------------------------------------
      // 7. WEB
      // --------------------------------------------------------

      if (kIsWeb) {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(
              'data:audio/mp3;base64,$audioContent',
            ),
          ),
        );
      }

      // --------------------------------------------------------
      // 8. ANDROID / IOS / DESKTOP
      // --------------------------------------------------------

      else {
        // Eski temporary dosyayı temizle.
        await _deletePreviousFile();

        final Directory directory =
        await getTemporaryDirectory();

        final String filePath =
            '${directory.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3';

        final File file = File(filePath);

        final List<int> audioBytes =
        base64Decode(audioContent);

        await file.writeAsBytes(
          audioBytes,
          flush: true,
        );

        _lastTempFile = file;

        debugPrint(
          'TTS: Ses dosyası oluşturuldu: $filePath',
        );

        await _audioPlayer.setFilePath(
          file.path,
        );
      }

      // --------------------------------------------------------
      // 9. PLAYER STATE
      // --------------------------------------------------------

      await _playerStateSubscription?.cancel();

      _playerStateSubscription =
          _audioPlayer.playerStateStream.listen(
                (PlayerState state) {
              if (state.processingState ==
                  ProcessingState.completed) {
                isSpeaking.value = false;

                _playerStateSubscription?.cancel();

                _playerStateSubscription = null;
              }
            },
            onError: (Object error) {
              debugPrint(
                'TTS PLAYER STREAM HATASI: $error',
              );

              isSpeaking.value = false;
            },
          );

      // --------------------------------------------------------
      // 10. PLAY
      // --------------------------------------------------------

      await _audioPlayer.play();

      debugPrint(
        'TTS: Ses oynatılıyor.',
      );
    }

    // ==========================================================
    // FIREBASE FUNCTIONS ERROR
    // ==========================================================

    on FirebaseFunctionsException catch (e) {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'TTS CLOUD FUNCTION HATASI',
      );

      debugPrint(
        'Code: ${e.code}',
      );

      debugPrint(
        'Message: ${e.message}',
      );

      debugPrint(
        'Details: ${e.details}',
      );

      debugPrint(
        '========================================',
      );

      isSpeaking.value = false;
    }

    // ==========================================================
    // GENEL HATA
    // ==========================================================

    catch (e, stackTrace) {
      debugPrint(
        'TTS HATA: $e',
      );

      debugPrint(
        'TTS STACK TRACE:\n$stackTrace',
      );

      isSpeaking.value = false;
    }
  }

  // ============================================================
  // STOP
  // ============================================================

  Future<void> stop() async {
    try {
      await _playerStateSubscription?.cancel();

      _playerStateSubscription = null;

      await _audioPlayer.stop();

      isSpeaking.value = false;
    } catch (e) {
      debugPrint(
        'TTS STOP HATASI: $e',
      );

      isSpeaking.value = false;
    }
  }

  // ============================================================
  // INTERNAL STOP
  // ============================================================

  Future<void> _stopCurrentPlayback() async {
    try {
      await _playerStateSubscription?.cancel();

      _playerStateSubscription = null;

      await _audioPlayer.stop();

      isSpeaking.value = false;
    } catch (e) {
      debugPrint(
        'TTS ÖNCEKİ SESİ DURDURMA HATASI: $e',
      );
    }
  }

  // ============================================================
  // DELETE PREVIOUS FILE
  // ============================================================

  Future<void> _deletePreviousFile() async {
    final File? file = _lastTempFile;

    if (file == null) {
      return;
    }

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint(
        'TTS TEMP DOSYA SİLME HATASI: $e',
      );
    }

    _lastTempFile = null;
  }

  // ============================================================
  // TEXT CLEANING
  // ============================================================

  String _cleanText(String text) {
    return text
        .replaceAll(
      RegExp(r'[*_#>]'),
      '',
    )
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _playerStateSubscription?.cancel();

    _playerStateSubscription = null;

    _audioPlayer.dispose();

    isSpeaking.dispose();
  }
}