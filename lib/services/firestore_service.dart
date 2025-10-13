import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  // --- User Functions (Unchanged) ---
  Future<String> addUser(Map<String, dynamic> userData) async {
    final docRef = await _usersCollection.add(userData);
    return docRef.id;
  }
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final docSnapshot = await _usersCollection.doc(userId).get();
    if (docSnapshot.exists) {
      return docSnapshot.data() as Map<String, dynamic>?;
    }
    return null;
  }
  Future<void> updateUser(String userId, Map<String, dynamic> userData) {
    return _usersCollection.doc(userId).update(userData);
  }
  Future<void> addHealthReading(String userId, Map<String, dynamic> readingData) {
    return _usersCollection.doc(userId).collection('healthReadings').add(readingData);
  }

  // --- Reading Streams (Updated & Simplified) ---

  // For the Riwayat page
  Stream<QuerySnapshot> getHealthReadingsStream(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('healthReadings')
        .orderBy('Timestamp', descending: true)
        .snapshots();
  }

  // NEW: A simple query for the Beranda page. This does NOT require composite indexes.
  Stream<QuerySnapshot> getRecentReadingsStream(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('healthReadings')
        .orderBy('Timestamp', descending: true)
        .limit(10) // Get the last 10 readings
        .snapshots();
  }
}