import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── USER OPERATIONS ───
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('username', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
        .limit(20)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Future<List<UserModel>> getSuggestedUsers(String currentUid) async {
    final snapshot = await _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUid)
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // ─── FOLLOW OPERATIONS ───
  Future<void> followUser(String currentUid, String targetUid) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(currentUid), {
      'following': FieldValue.arrayUnion([targetUid]),
      'followingCount': FieldValue.increment(1),
    });
    batch.update(_firestore.collection('users').doc(targetUid), {
      'followers': FieldValue.arrayUnion([currentUid]),
      'followersCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> unfollowUser(String currentUid, String targetUid) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(currentUid), {
      'following': FieldValue.arrayRemove([targetUid]),
      'followingCount': FieldValue.increment(-1),
    });
    batch.update(_firestore.collection('users').doc(targetUid), {
      'followers': FieldValue.arrayRemove([currentUid]),
      'followersCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  // ─── POST OPERATIONS ───
  Future<void> createPost(PostModel post) async {
    await _firestore.collection('posts').doc(post.postId).set(post.toMap());
    await _firestore.collection('users').doc(post.userId).update({
      'postsCount': FieldValue.increment(1),
    });
  }

  Future<void> deletePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).delete();
    await _firestore.collection('users').doc(userId).update({
      'postsCount': FieldValue.increment(-1),
    });
    // Delete all comments for this post
    final comments = await _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();
    for (final doc in comments.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<PostModel>> getFeedPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromMap(doc.data())).toList());
  }

  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromMap(doc.data())).toList());
  }

  Stream<List<PostModel>> getMoviePosts(String movieImdbId) {
    return _firestore
        .collection('posts')
        .where('movieImdbId', isEqualTo: movieImdbId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromMap(doc.data())).toList());
  }

  // ─── LIKE OPERATIONS ───
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final post = await postRef.get();
    if (!post.exists) return;

    final likes = List<String>.from(post.data()?['likes'] ?? []);
    if (likes.contains(userId)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }

  // ─── COMMENT OPERATIONS ───
  Future<void> addComment(CommentModel comment) async {
    await _firestore.collection('comments').doc(comment.commentId).set(comment.toMap());
    await _firestore.collection('posts').doc(comment.postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CommentModel.fromMap(doc.data())).toList());
  }
}
