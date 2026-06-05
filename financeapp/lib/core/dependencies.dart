import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/local_database.dart';

// ─── FIREBASE ────────────────────────────────────────────────────────────────
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// ─── LOCAL DATABASE (SQLite) ──────────────────────────────────────────────────
final localDatabaseProvider = Provider<LocalDatabase>((ref) => LocalDatabase());

// ─── CONNECTIVITY ─────────────────────────────────────────────────────────────
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityProvider).onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});
