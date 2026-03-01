import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/collection_alert.dart';

class FirestoreService {
  FirebaseFirestore? get _dbOrNull {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  Stream<List<CollectionAlert>> streamCollections(String deviceId) {
    final db = _dbOrNull;
    if (db == null) return Stream.value(const []);
    return db
        .collection('users')
        .doc(deviceId)
        .collection('collections')
        .snapshots()
        .map((snap) => snap.docs.map((d) => CollectionAlert.fromMap(d.data())).toList());
  }

  Future<void> upsertCollection(String deviceId, CollectionAlert collection) async {
    final db = _dbOrNull;
    if (db == null) return;
    await db
        .collection('users')
        .doc(deviceId)
        .collection('collections')
        .doc(collection.slug)
        .set(collection.toMap(), SetOptions(merge: true));
  }
}
