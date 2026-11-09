import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'edit_event_screen.dart';
import 'event_dm.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late String uid;
  bool deleting = false;
  EventDM? updatedEvent;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> editEvent(EventDM event) async {
    var updated = await Navigator.push<EventDM>(
      context,
      MaterialPageRoute<EventDM>(
        settings: RouteSettings(arguments: event),
        builder: (context) => const EditEventScreen(),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => updatedEvent = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label(context, 'Event updated', 'تم تحديث الفعالية')),
      ),
    );
  }

  Future<void> deleteEvent(EventDM event) async {
    var confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label(context, 'Delete event?', 'حذف الفعالية؟')),
        content: Text(event.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(label(context, 'No', 'لا')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(label(context, 'Yes', 'نعم')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => deleting = true);
    try {
      await userEvents(uid).doc(event.id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(label(context, 'Event deleted', 'تم حذف الفعالية')),
        ),
      );
      Navigator.pop(context);
    } on FirebaseException {
      if (!mounted) return;
      setState(() => deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            label(context, 'Could not delete the event', 'تعذر حذف الفعالية'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var event =
        updatedEvent ?? ModalRoute.of(context)!.settings.arguments as EventDM;
    var localizations = MaterialLocalizations.of(context);
    var date = localizations.formatFullDate(event.dateTime);
    var time = TimeOfDay.fromDateTime(event.dateTime).format(context);
    var colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(label(context, 'Event Details', 'تفاصيل الفعالية')),
        actions: [
          IconButton(
            tooltip: label(context, 'Edit event', 'تعديل الفعالية'),
            onPressed: deleting ? null : () => editEvent(event),
            icon: Icon(Icons.edit_outlined, color: colors.primary),
          ),
          IconButton(
            tooltip: label(context, 'Delete event', 'حذف الفعالية'),
            onPressed: deleting ? null : () => deleteEvent(event),
            icon: Icon(Icons.delete_outline, color: colors.error),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(event.category.imagePath),
          ),
          const SizedBox(height: 16),
          Text(
            event.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: colors.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(time, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label(context, 'Description', 'الوصف'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 140),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.outlineVariant),
            ),
            padding: const EdgeInsets.all(16),
            child: Text(
              event.description,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
