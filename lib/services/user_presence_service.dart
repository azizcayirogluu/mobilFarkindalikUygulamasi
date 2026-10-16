import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPresenceService with WidgetsBindingObserver {
  static final UserPresenceService instance = UserPresenceService._internal();
  UserPresenceService._internal();

  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    setOnline();
    _startHeartbeat();
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setOnline();
      _startHeartbeat();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      setOffline();
      _heartbeatTimer?.cancel();
    }
  }

  Future<void> setOnline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isOnline': true,
        'sonGorulme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> setOffline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isOnline': false,
        'sonGorulme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Her 2 dakikada bir 'sonGorulme' tarihini ve 'isOnline: true' durumunu güncelle
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      setOnline();
    });
  }
}
