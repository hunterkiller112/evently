import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'edit_event_screen.dart';
import 'event_details_screen.dart';
import 'event_dm.dart';
import 'login_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int tab = 0;
  EventCategory? selectedCategory;
  late String uid;
  late Stream<QuerySnapshot<Map<String, dynamic>>> eventsStream;
  Set<String> savingFavorites = {};

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    eventsStream = userEvents(uid).snapshots();
  }

  void openEvent(EventDM event) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        settings: RouteSettings(arguments: event),
        builder: (context) => const EventDetailsScreen(),
      ),
    );
  }

  void addEvent() {
    Navigator.push<EventDM>(
      context,
      MaterialPageRoute<EventDM>(builder: (context) => const EditEventScreen()),
    );
  }

  Future<void> toggleFavorite(EventDM event) async {
    if (savingFavorites.contains(event.id)) return;
    setState(() => savingFavorites.add(event.id));
    try {
      await userEvents(uid)
          .doc(event.id)
          .update({'is_favorite': !event.isFavorite});
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              label(context, 'Could not change favorite', 'تعذر تغيير المفضلة'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => savingFavorites.remove(event.id));
    }
  }

  Future<void> logOut() async {
    try {
      await signOut();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              label(context, 'Could not log out', 'تعذر تسجيل الخروج'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;
    var colors = Theme.of(context).colorScheme;
    var categories = <EventCategory?>[null, ...EventCategory.values];
    var heading = switch (tab) {
      1 => label(context, 'Favorites', 'المفضلة'),
      2 => label(context, 'Profile', 'الملف الشخصي'),
      _ =>
        user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!
            : 'Evently',
    };
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tab == 0
            ? (settings.isDark
                  ? colors.surfaceContainerHighest
                  : colors.primary)
            : null,
        foregroundColor: tab == 0 ? Colors.white : null,
        centerTitle: tab != 0,
        shape: tab == 0
            ? const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
              )
            : null,
        title: tab == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label(context, 'Welcome Back ✨', 'مرحبًا بعودتك ✨'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(heading),
                ],
              )
            : Text(heading),
        actions: [
          if (tab == 0) ...[
            IconButton(
              tooltip: label(context, 'Change theme', 'تغيير المظهر'),
              onPressed: () => settings.changeTheme(!settings.isDark),
              icon: Icon(
                settings.isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => settings.changeLanguage(
                settings.language == 'en' ? 'ar' : 'en',
              ),
              child: Text(settings.language.toUpperCase()),
            ),
          ],
        ],
        bottom: tab == 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(55),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      for (var category in categories)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: Text(
                              category?.displayName(context) ??
                                  label(context, 'All', 'الكل'),
                            ),
                            labelStyle: TextStyle(
                              color: selectedCategory == category
                                  ? Colors.black87
                                  : Colors.white,
                            ),
                            backgroundColor: Colors.transparent,
                            selectedColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            shape: const StadiumBorder(),
                            selected: selectedCategory == category,
                            onSelected: (selected) =>
                                setState(() => selectedCategory = category),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: tab == 2
          ? buildProfile(user)
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: eventsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      label(
                        context,
                        'Could not load events',
                        'تعذر تحميل الفعاليات',
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return buildEventList(
                  snapshot.data!.docs.map(EventDM.fromFirestore).toList(),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: addEvent,
        tooltip: label(context, 'Add Event', 'إضافة فعالية'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: label(context, 'Home', 'الرئيسية'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_outline),
            label: label(context, 'Favorites', 'المفضلة'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: label(context, 'Profile', 'الملف الشخصي'),
          ),
        ],
      ),
    );
  }

  Widget buildProfile(User? user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          child: const Text(
            'ROUTE',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user?.displayName ?? 'Evently',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(user?.email ?? '', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        SwitchListTile(
          title: Text(label(context, 'Dark mode', 'الوضع الداكن')),
          value: settings.isDark,
          onChanged: settings.changeTheme,
        ),
        ListTile(
          title: Text(label(context, 'Language', 'اللغة')),
          subtitle: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('English'),
                selected: settings.language == 'en',
                onSelected: (selected) => settings.changeLanguage('en'),
              ),
              ChoiceChip(
                label: const Text('العربية'),
                selected: settings.language == 'ar',
                onSelected: (selected) => settings.changeLanguage('ar'),
              ),
            ],
          ),
        ),
        if (user != null)
          ListTile(
            title: Text(label(context, 'Logout', 'تسجيل الخروج')),
            trailing: const Icon(Icons.logout),
            onTap: logOut,
          ),
      ],
    );
  }

  Widget buildEventList(List<EventDM> events) {
    var filtered = events.where((event) {
      if (tab == 1) {
        return event.isFavorite;
      }
      return selectedCategory == null || event.category == selectedCategory;
    }).toList();
    filtered.sort((first, second) => first.dateTime.compareTo(second.dateTime));
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          tab == 1
              ? label(context, 'No favorites found', 'لا توجد فعاليات مفضلة')
              : label(context, 'No events found yet', 'لا توجد فعاليات بعد'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        var event = filtered[index];
        var colors = Theme.of(context).colorScheme;
        var date = MaterialLocalizations.of(context)
            .formatShortMonthDay(event.dateTime);
        return Card(
          clipBehavior: Clip.antiAlias,
          color: colors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => openEvent(event),
            child: Stack(
              children: [
                Image.asset(
                  event.category.imagePath,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
                PositionedDirectional(
                  start: 10,
                  top: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Text(date, style: TextStyle(color: colors.primary)),
                  ),
                ),
                PositionedDirectional(
                  start: 8,
                  end: 8,
                  bottom: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: event.isFavorite
                              ? label(
                                  context,
                                  'Remove from favorites',
                                  'إزالة من المفضلة',
                                )
                              : label(
                                  context,
                                  'Add to favorites',
                                  'إضافة إلى المفضلة',
                                ),
                          onPressed: savingFavorites.contains(event.id)
                              ? null
                              : () => toggleFavorite(event),
                          icon: Icon(
                            event.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
