import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OfflineWriteOperation { set, update, remove }

class OfflineWrite {
  const OfflineWrite({
    required this.path,
    required this.operation,
    this.value,
    this.userId,
    this.busId,
    this.tripId,
    this.studentId,
    this.eventId,
    this.source,
  });

  final String path;
  final OfflineWriteOperation operation;
  final dynamic value;
  final String? userId;
  final String? busId;
  final String? tripId;
  final String? studentId;
  final String? eventId;
  final String? source;

  Map<String, dynamic> toJson() => {
    'path': path,
    'operation': operation.name,
    if (value != null) 'value': value,
    if (userId != null) 'userId': userId,
    if (busId != null) 'busId': busId,
    if (tripId != null) 'tripId': tripId,
    if (studentId != null) 'studentId': studentId,
    if (eventId != null) 'eventId': eventId,
    if (source != null) 'source': source,
  };

  factory OfflineWrite.fromJson(Map<String, dynamic> json) {
    return OfflineWrite(
      path: json['path'] as String,
      operation: OfflineWriteOperation.values.byName(
        json['operation'] as String,
      ),
      value: json['value'],
      userId: json['userId']?.toString(),
      busId: json['busId']?.toString(),
      tripId: json['tripId']?.toString(),
      studentId: json['studentId']?.toString(),
      eventId: json['eventId']?.toString(),
      source: json['source']?.toString(),
    );
  }
}

/// Durable FIFO queue for Firebase writes that fail while the app is offline.
class OfflineWriteQueue {
  OfflineWriteQueue._();
  static final OfflineWriteQueue instance = OfflineWriteQueue._();

  static const _storageKey = 'offline_firebase_writes';
  final List<OfflineWrite> _writes = [];
  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  Timer? _retryTimer;
  Future<void>? _initializing;
  bool _isFlushing = false;

  Future<void> initialize() {
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _writes.addAll(
            decoded.whereType<Map>().map(
              (item) => OfflineWrite.fromJson(Map<String, dynamic>.from(item)),
            ),
          );
        }
      }

      _connectionSubscription = FirebaseDatabase.instance
          .ref('.info/connected')
          .onValue
          .listen((event) {
            if (event.snapshot.value == true) {
              unawaited(flush());
            }
          });
      _retryTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(flush()),
      );
      await flush();
    } catch (error) {
      // A queue storage failure must not prevent the app from starting.
      debugPrint('OfflineWriteQueue: Error initializing: $error');
    }
  }

  Future<void> enqueue({
    required String path,
    required OfflineWriteOperation operation,
    dynamic value,
    String? userId,
    String? busId,
    String? tripId,
    String? studentId,
    String? eventId,
    String? source,
  }) async {
    await initialize();
    _writes.add(
      OfflineWrite(
        path: path,
        operation: operation,
        value: value,
        userId: userId,
        busId: busId,
        tripId: tripId,
        studentId: studentId,
        eventId: eventId,
        source: source,
      ),
    );
    await _persist();
  }

  Future<void> flush() async {
    if (_isFlushing || _writes.isEmpty) return;
    _isFlushing = true;
    try {
      while (_writes.isNotEmpty) {
        final write = _writes.first;
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (write.userId != null && write.userId != currentUid) {
          _writes.removeAt(0);
          await _persist();
          debugPrint(
            'OfflineWriteQueue: Dropped a write from a previous session.',
          );
          continue;
        }
        try {
          final reference = FirebaseDatabase.instance.ref(write.path);
          switch (write.operation) {
            case OfflineWriteOperation.set:
              await reference.set(write.value);
            case OfflineWriteOperation.update:
              await reference.update(
                Map<String, dynamic>.from(write.value as Map),
              );
            case OfflineWriteOperation.remove:
              await reference.remove();
          }
          _writes.removeAt(0);
          await _persist();
        } catch (error) {
          debugPrint('OfflineWriteQueue: Retry deferred: $error');
          break;
        }
      }
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_writes.map((write) => write.toJson()).toList()),
    );
  }

  Future<void> dispose() async {
    await _connectionSubscription?.cancel();
    _retryTimer?.cancel();
  }
}
