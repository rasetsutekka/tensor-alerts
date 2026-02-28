import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_alert.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Stream<List<CollectionAlert>> streamCollections(String deviceId) {
    return _db
        .collection('users')
        .doc(deviceId)
        .collection('collections')
        .snapshots()
        .map((snap) => snap.docs.map((d) => CollectionAlert.fromMap(d.data())).toList());
  }

  Future<void> upsertCollection(String deviceId, CollectionAlert collection) async {
    await _db
        .collection('users')
        .doc(deviceId)
        .collection('collections')
        .doc(collection.slug)
        .set(collection.toMap(), SetOptions(merge: true));
  }
}
