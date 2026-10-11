import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

class Member {
  final String id;
  final String name;
  final String relation;
  final bool isChild;
  final bool isConnected;
  final double? lat;
  final double? lng;
  final int? distance;
  final DateTime? locationUpdatedAt;
  final DateTime? stayStartedAt;

  const Member({
    required this.id,
    required this.name,
    required this.relation,
    required this.isChild,
    required this.isConnected,
    required this.lat,
    required this.lng,
    required this.distance,
    required this.locationUpdatedAt,
    required this.stayStartedAt,
  });

  factory Member.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Member(
      id: document.id,
      name: data['name'] as String? ?? '',
      relation: data['relation'] as String? ?? 'Member',
      isChild: data['isChild'] as bool? ?? false,
      isConnected: (data['uid'] as String?)?.isNotEmpty ?? false,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      distance: (data['distance'] as num?)?.toInt(),
      locationUpdatedAt: (data['locationUpdatedAt'] as Timestamp?)?.toDate(),
      stayStartedAt: (data['stayStartedAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get hasLocation => lat != null && lng != null;
}

class AppNotification {
  final String title;
  final String body;
  final DateTime? createdAt;
  final bool alert;

  const AppNotification({
    required this.title,
    required this.body,
    required this.createdAt,
    required this.alert,
  });

  factory AppNotification.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return AppNotification(
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      alert: data['alert'] as bool? ?? false,
    );
  }

  String get time {
    if (createdAt == null) return 'Time unavailable';
    final difference = DateTime.now().difference(createdAt!);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays} day(s) ago';
  }
}

class MissingReport {
  final String id;
  final String name;
  final String age;
  final String lastSeen;
  final String photoUrl;
  final String status;

  const MissingReport({
    required this.id,
    required this.name,
    required this.age,
    required this.lastSeen,
    required this.photoUrl,
    required this.status,
  });

  factory MissingReport.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return MissingReport(
      id: document.id,
      name: data['name'] as String? ?? '',
      age: data['age'] as String? ?? '',
      lastSeen: data['lastSeen'] as String? ?? '',
      photoUrl: data['photo'] as String? ?? '',
      status: data['status'] as String? ?? 'Active',
    );
  }
}

class AppDataService {
  AppDataService._();

  static final AppDataService instance = AppDataService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, Stream<DocumentSnapshot<Map<String, dynamic>>>>
  _profileStreams = {};
  final Map<String, Stream<DocumentSnapshot<Map<String, dynamic>>?>>
  _familyStreams = {};
  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>>
  _familyMemberStreams = {};
  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>>
  _notificationStreams = {};
  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>>
  _familyNotificationStreams = {};
  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>>
  _reportStreams = {};

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in is required.');
    return user.uid;
  }

  void refreshFamilyStreams() {
    final uid = _uid;
    _familyStreams.remove(uid);
    _profileStreams.remove(uid);
    _familyMemberStreams.clear();
  }

  DocumentReference<Map<String, dynamic>> get _userDocument =>
      _firestore.collection('users').doc(_uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> get userProfile =>
      _profileStreams.putIfAbsent(_uid, () => _userDocument.snapshots());

  Future<Map<String, dynamic>> getUserProfile() async {
    final snapshot = await _userDocument.get();
    return <String, dynamic>{
      'displayName': _auth.currentUser?.displayName ?? '',
      'email': _auth.currentUser?.email ?? '',
      'phone': _auth.currentUser?.phoneNumber ?? '',
      ...?snapshot.data(),
    };
  }

  Future<void> saveUserProfile({
    required String displayName,
    required String email,
    required String phone,
  }) async {
    final updates = <Future<void>>[
      _userDocument.set({
        'displayName': displayName,
        'email': email,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    ];
    final user = _auth.currentUser;
    if (user != null) {
      updates.add(user.updateDisplayName(displayName));
    }
    await Future.wait(updates);
  }

  Future<void> savePreference(String key, bool value) => _userDocument.set({
    'preferences': {key: value},
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Future<String?> get familyId async =>
      (await _userDocument.get()).data()?['familyId'] as String?;

  bool isCurrentUserFamilyOwner(Map<String, dynamic> familyData) =>
      familyData['ownerUid'] == _uid;

  Future<void> saveFamilySafeZone({
    double? latitude,
    double? longitude,
    required int radiusMeters,
    required bool enabled,
  }) async {
    if (radiusMeters < 100 || radiusMeters > 2000) {
      throw ArgumentError.value(
        radiusMeters,
        'radiusMeters',
        'Safe-zone radius must be between 100 and 2000 meters.',
      );
    }
    if ((latitude == null) != (longitude == null) ||
        (enabled && latitude == null)) {
      throw ArgumentError(
        'An enabled safe zone requires both latitude and longitude.',
      );
    }

    final id = await familyId;
    if (id == null || id.isEmpty) {
      throw StateError('Join or create a family before setting a safe zone.');
    }

    final familyRef = _firestore.collection('families').doc(id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(familyRef);
      final data = snapshot.data();
      if (data == null) {
        throw StateError('The family could not be found.');
      }
      if (data['ownerUid'] != _uid) {
        throw StateError('Only the family owner can change the safe zone.');
      }

      final version = (data['safeZoneVersion'] as num?)?.toInt() ?? 0;
      final update = <String, dynamic>{
        'safeZoneEnabled': enabled,
        'safeZoneRadiusMeters': radiusMeters,
        'safeZoneVersion': version + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (latitude != null && longitude != null) {
        update['safeZoneLat'] = latitude;
        update['safeZoneLng'] = longitude;
      }
      transaction.update(familyRef, update);
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>?> get family =>
      _familyStreams.putIfAbsent(
        _uid,
        () => _userDocument.snapshots().asyncExpand((userSnapshot) {
          final id = userSnapshot.data()?['familyId'] as String?;
          if (id == null) {
            return Stream<DocumentSnapshot<Map<String, dynamic>>?>.value(null);
          }
          return _firestore
              .collection('families')
              .doc(id)
              .snapshots()
              .map<DocumentSnapshot<Map<String, dynamic>>?>(
                (snapshot) => snapshot,
              );
        }),
      );

  Stream<QuerySnapshot<Map<String, dynamic>>> familyMembers(String id) =>
      _familyMemberStreams.putIfAbsent(
        id,
        () => _firestore
            .collection('families')
            .doc(id)
            .collection('members')
            .orderBy('createdAt')
            .snapshots(),
      );

  Future<void> createFamily({
    required String name,
    required String destination,
  }) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final inviteCode = _newInviteCode();
      final familyRef = _firestore.collection('families').doc();
      final inviteRef = _firestore.collection('familyInvites').doc(inviteCode);
      final created = await _firestore.runTransaction((transaction) async {
        final inviteSnapshot = await transaction.get(inviteRef);
        if (inviteSnapshot.exists) return false;

        transaction.set(familyRef, {
          'name': name,
          'destination': destination,
          'ownerUid': _uid,
          'inviteCode': inviteCode,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.set(inviteRef, {'familyId': familyRef.id});
        transaction.set(familyRef.collection('members').doc(_uid), {
          'uid': _uid,
          'name':
              _auth.currentUser?.displayName ??
              _auth.currentUser?.email ??
              'Account owner',
          'phone': _auth.currentUser?.phoneNumber ?? '',
          'relation': 'Owner',
          'isChild': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.set(_userDocument, {
          'familyId': familyRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      });
      if (created) return;
    }
    throw StateError('Could not generate a unique family invite code.');
  }

  Future<String> createFamilyInviteCode() async {
    final id = await familyId;
    if (id == null) {
      throw StateError('Create or join a family before inviting members.');
    }
    final familyRef = _firestore.collection('families').doc(id);
    final memberRef = familyRef.collection('members').doc(_uid);

    for (var attempt = 0; attempt < 5; attempt++) {
      final inviteCode = _newInviteCode();
      final inviteRef = _firestore.collection('familyInvites').doc(inviteCode);
      final result = await _firestore.runTransaction<String?>((
        transaction,
      ) async {
        final familySnapshot = await transaction.get(familyRef);
        final memberSnapshot = await transaction.get(memberRef);
        final inviteSnapshot = await transaction.get(inviteRef);
        if (!familySnapshot.exists || !memberSnapshot.exists) {
          throw StateError('Your account is not connected to this family.');
        }
        final existingCode = familySnapshot.data()?['inviteCode'] as String?;
        if (existingCode != null && existingCode.isNotEmpty) {
          final existingInviteRef = _firestore
              .collection('familyInvites')
              .doc(existingCode);
          final existingInvite = await transaction.get(existingInviteRef);
          if (existingInvite.exists &&
              existingInvite.data()?['familyId'] != id) {
            throw StateError('The family invite code is already in use.');
          }
          if (!existingInvite.exists) {
            transaction.set(existingInviteRef, {'familyId': id});
          }
          return existingCode;
        }
        if (inviteSnapshot.exists) return null;

        transaction.set(familyRef, {
          'inviteCode': inviteCode,
        }, SetOptions(merge: true));
        transaction.set(inviteRef, {'familyId': id});
        return inviteCode;
      });
      if (result != null) return result;
    }
    throw StateError('Could not generate a unique family invite code.');
  }

  Future<void> joinFamily(String inviteCode) async {
    final code = inviteCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw StateError('Enter a family invite code.');
    }
    final inviteRef = _firestore.collection('familyInvites').doc(code);
    final inviteSnapshot = await inviteRef.get();
    final familyId = inviteSnapshot.data()?['familyId'] as String?;
    if (!inviteSnapshot.exists || familyId == null || familyId.isEmpty) {
      throw StateError('That family invite code is not valid.');
    }

    final familyRef = _firestore.collection('families').doc(familyId);
    final memberRef = familyRef.collection('members').doc(_uid);
    final currentUser = _auth.currentUser;
    final displayName =
        currentUser?.displayName ?? currentUser?.email ?? 'Family member';

    await _firestore.runTransaction((transaction) async {
      final currentInvite = await transaction.get(inviteRef);
      final familySnapshot = await transaction.get(familyRef);
      final userSnapshot = await transaction.get(_userDocument);
      final memberSnapshot = await transaction.get(memberRef);

      if (!currentInvite.exists ||
          currentInvite.data()?['familyId'] != familyId ||
          !familySnapshot.exists) {
        throw StateError('That family invite code is no longer valid.');
      }
      final currentFamilyId = userSnapshot.data()?['familyId'] as String?;
      if (currentFamilyId != null && currentFamilyId != familyId) {
        throw StateError(
          'Your account is already connected to another family.',
        );
      }

      final ownerUid = familySnapshot.data()?['ownerUid'] as String?;
      var assignOwner = ownerUid == null || ownerUid.isEmpty;
      if (ownerUid != null && ownerUid.isNotEmpty && ownerUid != _uid) {
        final ownerSnapshot = await transaction.get(
          familyRef.collection('members').doc(ownerUid),
        );
        assignOwner = !ownerSnapshot.exists;
      }

      transaction.set(memberRef, {
        'uid': _uid,
        'name': displayName,
        'phone':
            currentUser?.phoneNumber ??
            userSnapshot.data()?['phone'] as String? ??
            '',
        'relation': assignOwner
            ? 'Owner'
            : memberSnapshot.data()?['relation'] as String? ?? 'Member',
        'isChild': false,
        'createdAt':
            memberSnapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(_userDocument, {
        'familyId': familyId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (assignOwner) {
        transaction.set(familyRef, {
          'ownerUid': _uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> leaveFamily() async {
    final id = await familyId;
    if (id == null || id.isEmpty) {
      throw StateError('Your account is not connected to a family.');
    }

    final familyRef = _firestore.collection('families').doc(id);
    final memberRef = familyRef.collection('members').doc(_uid);
    final candidateMembers = await familyRef
        .collection('members')
        .orderBy('createdAt')
        .get();

    await _firestore.runTransaction((transaction) async {
      final familySnapshot = await transaction.get(familyRef);
      final userSnapshot = await transaction.get(_userDocument);
      final memberSnapshot = await transaction.get(memberRef);

      if (userSnapshot.data()?['familyId'] != id) {
        throw StateError('Your account is no longer connected to this family.');
      }
      if (!memberSnapshot.exists) {
        throw StateError('Your family membership could not be found.');
      }

      final isOwner = familySnapshot.data()?['ownerUid'] == _uid;
      if (isOwner) {
        DocumentSnapshot<Map<String, dynamic>>? successor;
        for (final candidate in candidateMembers.docs) {
          if (candidate.id == _uid) continue;
          final candidateSnapshot = await transaction.get(candidate.reference);
          final uid = candidateSnapshot.data()?['uid'] as String?;
          if (candidateSnapshot.exists && uid != null && uid.isNotEmpty) {
            successor = candidateSnapshot;
            break;
          }
        }

        if (successor == null) {
          transaction.set(familyRef, {
            'ownerUid': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          transaction.set(familyRef, {
            'ownerUid': successor.id,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          transaction.set(successor.reference, {
            'relation': 'Owner',
          }, SetOptions(merge: true));
        }
      }

      transaction.delete(memberRef);
      transaction.set(_userDocument, {
        'familyId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    refreshFamilyStreams();
  }

  String _newInviteCode() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      8,
      (_) => characters[random.nextInt(characters.length)],
    ).join();
  }

  Future<void> addFamilyMember({
    required String familyId,
    required String name,
    required String phone,
    required String relation,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .add({
          'name': name,
          'phone': phone,
          'relation': relation,
          'isChild': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<bool> get locationSharingEnabled async {
    final profile = (await _userDocument.get()).data();
    final preferences = profile?['preferences'];
    return preferences is Map && preferences['shareLocation'] == true;
  }

  Stream<bool> get locationSharingPreference =>
      _userDocument.snapshots().map((snapshot) {
        final preferences = snapshot.data()?['preferences'];
        return preferences is Map && preferences['shareLocation'] == true;
      });

  Future<void> publishCurrentLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (!await locationSharingEnabled) {
      throw StateError('Enable “Share my location” in Settings first.');
    }
    final id = await familyId;
    if (id == null) {
      throw StateError('Create a family before sharing your location.');
    }
    final member = _firestore
        .collection('families')
        .doc(id)
        .collection('members')
        .doc(_uid);

    final family = _firestore.collection('families').doc(id);
    await _firestore.runTransaction((transaction) async {
      final familySnapshot = await transaction.get(family);
      final memberSnapshot = await transaction.get(member);
      final familyData = familySnapshot.data();
      final memberData = memberSnapshot.data();
      if (familyData == null || memberData == null) {
        throw StateError('Family or member data could not be found.');
      }

      final safeZoneEnabled = familyData['safeZoneEnabled'] == true;
      final centerLat = (familyData['safeZoneLat'] as num?)?.toDouble();
      final centerLng = (familyData['safeZoneLng'] as num?)?.toDouble();
      final radius = (familyData['safeZoneRadiusMeters'] as num?)?.toDouble();
      final version = (familyData['safeZoneVersion'] as num?)?.toInt() ?? 0;
      var outside = false;
      if (safeZoneEnabled &&
          centerLat != null &&
          centerLng != null &&
          radius != null &&
          radius > 0) {
        outside =
            Geolocator.distanceBetween(
              centerLat,
              centerLng,
              latitude,
              longitude,
            ) >
            radius;
      }
      final wasOutsideInThisZone =
          memberData['safeZoneVersion'] == version &&
          memberData['outsideSafeZone'] == true;
      const stayRadiusMeters = 100.0;
      final stayLat = (memberData['stayAnchorLat'] as num?)?.toDouble();
      final stayLng = (memberData['stayAnchorLng'] as num?)?.toDouble();
      final hasStayAnchor =
          stayLat != null &&
          stayLng != null &&
          memberData['stayStartedAt'] is Timestamp;
      final leftStayArea =
          !hasStayAnchor ||
          Geolocator.distanceBetween(stayLat, stayLng, latitude, longitude) >
              stayRadiusMeters;

      final locationUpdate = <String, dynamic>{
        'lat': latitude,
        'lng': longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'safeZoneVersion': version,
        'outsideSafeZone': outside,
      };
      if (leftStayArea) {
        locationUpdate['stayAnchorLat'] = latitude;
        locationUpdate['stayAnchorLng'] = longitude;
        locationUpdate['stayStartedAt'] = FieldValue.serverTimestamp();
      }
      transaction.update(member, locationUpdate);

      if (outside && !wasOutsideInThisZone) {
        final ownerUid = familyData['ownerUid'] as String?;
        if (ownerUid == null || ownerUid.isEmpty) {
          throw StateError('The family owner could not be found.');
        }
        final notification = _firestore
            .collection('users')
            .doc(ownerUid)
            .collection('notifications')
            .doc();
        final name = (memberData['name'] as String? ?? '').trim();
        transaction.set(notification, {
          'title': 'Safe Zone Alert',
          'body':
              '${name.isEmpty ? 'A family member' : name} has left the family safe zone.',
          'alert': true,
          'sourceUid': _uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.set(family.collection('notifications').doc(), {
          'title': 'Safe Zone Alert',
          'body':
              '${name.isEmpty ? 'A family member' : name} has left the family safe zone.',
          'alert': true,
          'sourceUid': _uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> familyNotifications(String id) =>
      _familyNotificationStreams.putIfAbsent(
        id,
        () => _firestore
            .collection('families')
            .doc(id)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
      );

  Stream<QuerySnapshot<Map<String, dynamic>>> get notifications =>
      _notificationStreams.putIfAbsent(
        _uid,
        () => _firestore
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
      );

  Future<void> addNotification({
    required String title,
    required String body,
    bool alert = false,
  }) =>
      _firestore.collection('users').doc(_uid).collection('notifications').add({
        'title': title,
        'body': body,
        'alert': alert,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<QuerySnapshot<Map<String, dynamic>>> get missingReports =>
      _reportStreams.putIfAbsent(
        _uid,
        () => _firestore
            .collection('missingChildReports')
            .where('ownerUid', isEqualTo: _uid)
            .snapshots(),
      );

  Future<void> submitMissingReport(Map<String, dynamic> data) async {
    final report = _firestore.collection('missingChildReports').doc();
    var photoUrl = data['photo'] as String? ?? '';
    final photoBytes = data['photoBytes'];
    if (photoBytes is Uint8List && photoBytes.isNotEmpty) {
      final storageRef = FirebaseStorage.instance.ref().child(
        'missing-child-reports/$_uid/${report.id}',
      );
      late final TaskSnapshot uploadedPhoto;
      try {
        uploadedPhoto = await storageRef.putData(
          photoBytes,
          SettableMetadata(
            contentType: data['photoContentType'] as String? ?? 'image/jpeg',
          ),
        );
      } on FirebaseException catch (error) {
        throw StateError(
          'Could not upload the report photo (${error.code}): ${error.message ?? 'Check your connection and Firebase Storage rules.'}',
        );
      }
      try {
        photoUrl = await uploadedPhoto.ref.getDownloadURL();
      } on FirebaseException catch (error) {
        if (error.code == 'object-not-found') {
          throw StateError(
            'Firebase Storage could not find the uploaded report photo. '
            'Check that Storage is initialized for this Firebase project, '
            'the configured bucket is correct, and storage.rules are deployed.',
          );
        }
        throw StateError(
          'Could not get the report photo URL (${error.code}): ${error.message ?? 'Check Firebase Storage access.'}',
        );
      }
    }
    final notification = _firestore
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc();
    final batch = _firestore.batch();
    batch.set(report, {
      'ownerUid': _uid,
      'name': data['name'] ?? '',
      'age': data['age'] ?? '',
      'description': data['description'] ?? '',
      'photo': photoUrl,
      'lastSeen': data['lastSeen'] ?? '',
      'time': data['time'] ?? '',
      'status': 'Active',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(notification, {
      'title': 'Missing child report created',
      'body': 'Your report for ${data['name'] ?? 'the child'} was saved.',
      'alert': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get crowdLevels => _firestore
      .collection('crowdLevels')
      .orderBy('updatedAt', descending: true)
      .limit(1)
      .snapshots();

  Future<void> signOut() => _auth.signOut();
}
