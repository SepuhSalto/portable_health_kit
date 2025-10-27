import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  // NEW: Collection for patients
  final CollectionReference _patientsCollection = FirebaseFirestore.instance.collection('patients');

  // --- User Functions (Kept for the health worker, if needed later) ---
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

  // --- Patient Functions (NEW) ---
  
  // Adds a new patient document
  Future<String> addPatient(Map<String, dynamic> patientData) async {
    final docRef = await _patientsCollection.add(patientData);
    return docRef.id;
  }

  // Gets a stream of all patients
  Stream<QuerySnapshot> getPatientsStream() {
    // You can add .orderBy('Name') here if you want
    return _patientsCollection.snapshots();
  }

  // Adds a health reading to a sub-collection inside a patient's document
  Future<void> addHealthReadingToPatient(String patientId, Map<String, dynamic> readingData) {
    return _patientsCollection
        .doc(patientId)
        .collection('healthReadings')
        .add(readingData);
  }

  // Gets the health reading stream for a SPECIFIC patient
  Stream<QuerySnapshot> getPatientHealthReadingsStream(String patientId) {
    return _patientsCollection
        .doc(patientId)
        .collection('healthReadings')
        .orderBy('Timestamp', descending: true)
        .snapshots();
  }
  
  // Gets recent readings for a SPECIFIC patient
  Stream<QuerySnapshot> getPatientRecentReadingsStream(String patientId) {
    return _patientsCollection
        .doc(patientId)
        .collection('healthReadings')
        .orderBy('Timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getPatientData(String patientId) async {
    try {
      final docSnapshot = await _patientsCollection.doc(patientId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>?;
      } else {
        print("FirestoreService: No patient found with ID: $patientId");
        return null;
      }
    } catch (e) {
      print("FirestoreService: Error getting patient data for ID $patientId: $e");
      return null; // Return null on error
    }
  }

  // --- OLD Reading Streams (These are now incorrect) ---
  // We leave them for now, but they will be fixed later.
  Stream<QuerySnapshot> getHealthReadingsStream(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('healthReadings')
        .orderBy('Timestamp', descending: true)
        .snapshots();
  }
  Stream<QuerySnapshot> getRecentReadingsStream(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('healthReadings')
        .orderBy('Timestamp', descending: true)
        .limit(10)
        .snapshots();
  }
}