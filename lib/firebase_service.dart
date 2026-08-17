import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Service - Handles Authentication and Firestore operations
/// This replaces the Flask backend for login/register and data storage
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== AUTHENTICATION ====================

  /// Register a new user with email and password
  static Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role, // 'student', 'faculty', 'admin'
    String? semester,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        return {'success': false, 'message': 'Failed to create user'};
      }

      // Save additional user data to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        'role': role,
        'semester': semester,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': user.emailVerified,
      });

      return {
        'success': true,
        'user': {
          'uid': user.uid,
          'email': user.email,
          'name': name,
          'role': role,
        }
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  /// Login with email and password
  static Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        return {'success': false, 'message': 'Login failed'};
      }

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {'success': false, 'message': 'User data not found'};
      }

      final userData = userDoc.data()!;

      return {
        'success': true,
        'user': {
          'uid': user.uid,
          'email': user.email,
          'name': userData['name'],
          'role': userData['role'],
          'semester': userData['semester'],
        }
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Get auth error message
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'invalid-action-code':
        return 'Verification link expired or invalid';
      default:
        return 'An error occurred. Please try again';
    }
  }

  // ==================== DEPRECATED: Email Verification ====================
  // Backend OTP system handles email verification now. Firebase verification removed.
  // Keeping basic auth methods for potential future use.


  /// Send password reset email via Firebase Auth
  static Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return {
        'success': true,
        'message': 'Password reset email sent. Check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send reset email: $e'};
    }
  }

  // ==================== FIRESTORE OPERATIONS ====================

  /// Get all users (for admin)
  static Future<List<Map<String, dynamic>>> getUsers({String? role}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('users');
      
      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }
      
      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get notices
  static Future<List<Map<String, dynamic>>> getNotices({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  /// Create notice (admin/faculty only)
  static Future<bool> createNotice({
    required String title,
    required String content,
    String priority = 'normal',
    required String authorId,
    required String authorName,
  }) async {
    try {
      await _firestore.collection('notices').add({
        'title': title,
        'content': content,
        'priority': priority,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete notice
  static Future<bool> deleteNotice(String noticeId) async {
    try {
      await _firestore.collection('notices').doc(noticeId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get assignments
  static Future<List<Map<String, dynamic>>> getAssignments({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('assignments')
          .orderBy('dueDate', descending: false)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  /// Create assignment
  static Future<bool> createAssignment({
    required String title,
    required String description,
    required String dueDate,
    required String authorId,
    required String authorName,
  }) async {
    try {
      await _firestore.collection('assignments').add({
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get study materials
  static Future<List<Map<String, dynamic>>> getMaterials({
    String? subject,
    int limit = 50,
  }) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      
      if (subject != null) {
        snapshot = await _firestore
            .collection('materials')
            .where('subject', isEqualTo: subject)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
      } else {
        snapshot = await _firestore
            .collection('materials')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
      }
      
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  /// Upload study material
  static Future<bool> uploadMaterial({
    required String title,
    required String subject,
    required String type,
    required String fileUrl,
    String description = '',
    required String authorId,
    required String authorName,
  }) async {
    try {
      await _firestore.collection('materials').add({
        'title': title,
        'subject': subject,
        'type': type,
        'fileUrl': fileUrl,
        'description': description,
        'authorId': authorId,
        'authorName': authorName,
        'status': 'approved', // or 'pending' for review
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get FAQs
  static Future<List<Map<String, dynamic>>> getFaqs({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('faqs')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  /// Create FAQ
  static Future<bool> createFaq({
    required String question,
    required String answer,
    required String category,
  }) async {
    try {
      await _firestore.collection('faqs').add({
        'question': question,
        'answer': answer,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update user profile
  static Future<bool> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get user data
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Activate/Deactivate user (admin)
  static Future<bool> setUserActive(String uid, bool isActive) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isActive': isActive});
      return true;
    } catch (e) {
      return false;
    }
  }
}
