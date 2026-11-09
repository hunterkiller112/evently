import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

DocumentReference<Map<String, dynamic>> userDocument(String uid) {
  return FirebaseFirestore.instance.collection('Users').doc(uid);
}

CollectionReference<Map<String, dynamic>> userEvents(String uid) {
  return userDocument(uid).collection('Events');
}

Future<void> saveUser(User user) {
  return userDocument(user.uid).set({
    'id': user.uid,
    'name': user.displayName ?? '',
    'email': user.email ?? '',
  }, SetOptions(merge: true));
}

enum EventCategory {
  bookClub,
  sport,
  birthday,
  meeting,
  exhibition;

  String get label => switch (this) {
    bookClub => 'Book club',
    sport => 'Sport',
    birthday => 'Birthday',
    meeting => 'Meeting',
    exhibition => 'Exhibition',
  };

  IconData get icon => switch (this) {
    bookClub => Icons.menu_book_outlined,
    sport => Icons.directions_bike,
    birthday => Icons.cake_outlined,
    meeting => Icons.people_outline,
    exhibition => Icons.collections_outlined,
  };

  String get imagePath => 'assets/images/$name.png';

  String displayName(BuildContext context) {
    if (Localizations.localeOf(context).languageCode != 'ar') return label;
    return switch (this) {
      bookClub => 'نادي الكتاب',
      sport => 'رياضة',
      birthday => 'عيد ميلاد',
      meeting => 'اجتماع',
      exhibition => 'معرض',
    };
  }

  static EventCategory fromName(String name) {
    var category = name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (category == 'bookingclub') return EventCategory.bookClub;
    return EventCategory.values.firstWhere(
      (item) => item.name.toLowerCase() == category,
      orElse: () => EventCategory.sport,
    );
  }
}

class EventDM {
  String id;
  String title;
  String description;
  DateTime dateTime;
  EventCategory category;
  bool isFavorite;

  EventDM({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.category,
    this.isFavorite = false,
  });

  factory EventDM.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    var data = document.data();
    var dateValue = data['event_date'] ?? data['dateTime'];
    var date = DateTime.now();
    if (dateValue is Timestamp) date = dateValue.toDate();
    if (dateValue is int) date = DateTime.fromMillisecondsSinceEpoch(dateValue);
    if (dateValue is String) date = DateTime.tryParse(dateValue) ?? date;
    var time = RegExp(
      r'(\d{1,2}):(\d{2})\s*(AM|PM|ص|م)?',
      caseSensitive: false,
    ).firstMatch(data['event_time']?.toString() ?? '');
    if (time != null) {
      var hour = int.parse(time[1]!);
      var minute = int.parse(time[2]!);
      var period = time[3]?.toUpperCase();
      if (period == 'AM' || period == 'ص') hour = hour % 12;
      if (period == 'PM' || period == 'م') hour = hour % 12 + 12;
      if (hour < 24 && minute < 60) {
        date = DateTime(date.year, date.month, date.day, hour, minute);
      }
    }
    var previousCategory = data['categoryDM'] as Map<String, dynamic>?;
    return EventDM(
      id: document.id,
      title: (data['event_title'] ?? data['title']) as String? ?? '',
      description:
          (data['event_description'] ?? data['description']) as String? ?? '',
      dateTime: date,
      category: EventCategory.fromName(
        (data['event_name'] ?? previousCategory?['name']) as String? ?? '',
      ),
      isFavorite: data['is_favorite'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'event_title': title,
      'event_description': description,
      'event_name': category.label,
      'event_image': category.imagePath,
      'event_date': DateUtils.dateOnly(dateTime).millisecondsSinceEpoch,
      'event_time': TimeOfDay.fromDateTime(dateTime).toString(),
      'is_favorite': isFavorite,
    };
  }
}
