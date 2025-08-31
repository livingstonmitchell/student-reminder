import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:students_reminder/src/models/note.dart';

class NotesService {
  NotesService._();
  static final instance = NotesService._();
  final _db = FirebaseFirestore.instance;

  //Finding the destination for notes
  CollectionReference<Map<String, dynamic>> _notesCol(String uid) {
    return _db.collection('users').doc(uid).collection('notes');
  }

  // Stream<QuerySnapshot<Map<String, dynamic>>> watchMyNotes(String uid) {
  //   return _notesCol(uid).orderBy('aud_dt', descending: true).snapshots();
  // }

  // Stream<QuerySnapshot<Map<String, dynamic>>> watchPublicNotes(String uid) {
  //   return _notesCol(uid)
  //       .where('visibility', isEqualTo: 'public')
  //       .orderBy('aud_dt', descending: true)
  //       .snapshots();
  // }

  Stream<QuerySnapshot<Map<String, dynamic>>> publicFeeds() {
    return _db
        .collectionGroup('notes')
        .where('visibility', isEqualTo: 'public')
        .orderBy(
          'aud_dt',
          descending: true,
        ) // or orderBy('likesCount', descending: true)
        .limit(100)
        .snapshots();
  }

  // Future<String> createNote(
  //   String uid, {
  //   required String title,
  //   required String body,
  //   required String visibility,
  //   DateTime? dueDate,
  //   List<String>? tags,
  // }) async {
  //   final doc = await _notesCol(uid).add({
  //     'title': title,
  //     'body': body,
  //     'visibility': visibility,
  //     'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
  //     'tags': tags ?? [],
  //     'aud_dt': FieldValue.serverTimestamp(),
  //   });
  //   return doc.id;
  // }

  // Future<void> updateNote(
  //   String uid,
  //   String noteId, {
  //   String? title,
  //   String? body,
  //   String? visibility,
  //   DateTime? dueDate,
  //   List<String>? tags,
  // }) async {
  //   final data = <String, dynamic>{};
  //   if (title != null) data['title'] = title;
  //   if (body != null) data['body'] = body;
  //   if (visibility != null) data['visibility'] = visibility;
  //   if (dueDate != null) {
  //     data['dueDate'] = Timestamp.fromDate(dueDate);
  //   }
  //   if (tags != null) data['tags'] = tags;
  //   await _notesCol(uid).doc(noteId).update(data);
  // }

  // Future<void> deleteNote(String uid, String noteId) {
  //   return _notesCol(uid).doc(noteId).delete();
  // }
  Future<void> toggleLike({
    required DocumentReference<Map<String, dynamic>> noteRef,
    required String uid,
  }) async {
    final db = FirebaseFirestore.instance;

    await db.runTransaction((tx) async {
      final snap = await tx.get(noteRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      final Map<String, dynamic> likedBy = Map<String, dynamic>.from(
        data['likedBy'] ?? const {},
      );
      final bool alreadyLiked = likedBy[uid] == true;
      final int currentCount = (data['likesCount'] ?? 0) as int;

      if (alreadyLiked) {
        // UNLIKE
        likedBy.remove(uid);
        final newCount = (currentCount - 1).clamp(0, 1 << 30);
        tx.update(noteRef, {
          'likesCount': newCount,
          'likedBy.$uid': FieldValue.delete(),
        });
      } else {
        // LIKE
        final newCount = currentCount + 1;
        tx.update(noteRef, {'likesCount': newCount, 'likedBy.$uid': true});
      }
    });
  }

  Future<void> reportNote({
    required DocumentReference<Map<String, dynamic>> noteRef,
    required String uid,
    required String reason,
  }) async {
    final reportRef = noteRef.collection('reports').doc(uid);
    await reportRef.set({
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Remove the current user's report (optional "Undo report")
  Future<void> unreportNote({
    required DocumentReference<Map<String, dynamic>> noteRef,
    required String uid,
  }) async {
    await noteRef.collection('reports').doc(uid).delete();
  }

  /// Admin: stream all report docs across all notes (newest first)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllReportsForAdmin({
    int limit = 200,
  }) {
    return FirebaseFirestore.instance
        .collectionGroup('reports')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Stream of deleted notes (bin) for user
  Stream<List<Note>> watchBinNotes(String uid) {
    return _binCol(uid)
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Note.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  CollectionReference<Map<String, dynamic>> _binCol(String uid) =>
      _db.collection('users').doc(uid).collection('bin');

  // Stream of user's notes (not deleted) - Returns QuerySnapshot for compatibility
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyNotesSnapshot(String uid) {
    return _notesCol(uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('aud_dt', descending: true)
        .snapshots();
  }

  // Stream of user's notes (not deleted) - Returns List<Note>
  Stream<List<Note>> watchMyNotes(String uid) {
    return _notesCol(uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('aud_dt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Note.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Stream of user's public notes (not deleted)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPublicNotes(String uid){
    return _notesCol(uid)
        .where('visibility', isEqualTo: 'public')
        .where('isDeleted', isEqualTo: false)
        .orderBy('aud_dt', descending: true)
        .snapshots();
  }

  // Create a note
  Future<String> createNote(
    String uid, {
    required String title,
    required String body,
    required String visibility,
    DateTime? dueDate,
    List<String>? tags,
  }) async {
    final data = {
      'title': title,
      'body': body,
      'visibility': visibility,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'tags': tags ?? [],
      'aud_dt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
    };
    final doc = await _notesCol(uid).add(data);
    return doc.id;
  }

  // Create a note from a Note model
  Future<void> createNoteModel(String uid, Note note) async {
    await _notesCol(uid).doc(note.id).set(note.toMap());
  }

  // Update note with field validation
  Future<void> updateNote(
    String uid,
    String noteId, {
    String? title,
    String? body,
    String? visibility,
    DateTime? dueDate,
    List<String>? tags,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (body != null) data['body'] = body;
    if (visibility != null) data['visibility'] = visibility;
    if (dueDate != null) data['dueDate'] = Timestamp.fromDate(dueDate);
    if (tags != null) data['tags'] = tags;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _notesCol(uid).doc(noteId).update(data);
  }

  // Update entire note (from Note model)
  Future<void> updateNoteModel(String uid, Note note) async {
    final updateData = note.toMap();
    updateData['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _notesCol(uid).doc(note.id).update(updateData);
  }

  // Soft delete - move to bin
  Future<void> softDeleteNote(String uid, String noteId) async {
    final doc = await _notesCol(uid).doc(noteId).get();
    if (doc.exists) {
      final noteData = doc.data()!;
      // Move to bin
      await _binCol(uid).doc(noteId).set({
        ...noteData,
        'deletedAt': Timestamp.fromDate(DateTime.now()),
        'originalCollection': 'notes',
      });
      // Mark as deleted in notes collection
      await _notesCol(uid).doc(noteId).update({
        'isDeleted': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  // Restore note from bin
  Future<void> restoreNote(String uid, String noteId) async {
    final binDoc = await _binCol(uid).doc(noteId).get();
    if (binDoc.exists) {
      // Remove from bin
      await _binCol(uid).doc(noteId).delete();
      // Mark as not deleted in notes
      await _notesCol(uid).doc(noteId).update({
        'isDeleted': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  // Permanent delete from bin
  Future<void> permanentDeleteNote(String uid, String noteId) async {
    await _binCol(uid).doc(noteId).delete();
    // Optionally, you could also remove from notes collection
    // await _notesCol(uid).doc(noteId).delete();
  }

  // Hard delete from notes (not bin)
  Future<void> deleteNote(String uid, String noteId) {
    return _notesCol(uid).doc(noteId).delete();
  }
}
