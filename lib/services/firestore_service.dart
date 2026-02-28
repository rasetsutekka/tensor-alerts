import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/collection_alert.dart';

class FirestoreService {
FirebaseFirestore? get _db =>
Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

final Map<String, Map<String, CollectionAlert>> _local = {};
final Map<String, StreamController<List<CollectionAlert>>> _controllers = {};

StreamController<List<CollectionAlert>> _controllerFor(String deviceId) {
return _controllers.putIfAbsent(
deviceId,
() => StreamController<List<CollectionAlert>>.broadcast(),
);
}

Stream<List<CollectionAlert>> streamCollections(String deviceId) {
final db = _db;
if (db != null) {
return db
.collection('users')
.doc(deviceId)
.collection('collections')
.snapshots()
.map((snap) =>
snap.docs.map((d) => CollectionAlert.fromMap(d.data())).toList());
}

final c = _controllerFor(deviceId);
Future.microtask(() {
final items = _local[deviceId]?.values.toList() ?? const <CollectionAlert>[];
c.add(items);
});
return c.stream;
}

Future<void> upsertCollection(String deviceId, CollectionAlert collection) async {
final db = _db;
if (db != null) {
await db
.collection('users')
.doc(deviceId)
.collection('collections')
.doc(collection.slug)
.set(collection.toMap(), SetOptions(merge: true));
return;
}

final userMap = _local.putIfAbsent(deviceId, () => {});
userMap[collection.slug] = collection;
_controllerFor(deviceId).add(userMap.values.toList());
}
}
