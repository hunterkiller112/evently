import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'event_dm.dart';

class EditEventScreen extends StatefulWidget {
  const EditEventScreen({super.key});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  var formKey = GlobalKey<FormState>();
  EventDM? original;
  bool initialized = false;
  late String uid;
  late EventCategory selectedCategory;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  bool saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    uid = FirebaseAuth.instance.currentUser!.uid;
    var event = ModalRoute.of(context)!.settings.arguments as EventDM?;
    original = event;
    titleController.text = event?.title ?? '';
    descriptionController.text = event?.description ?? '';
    selectedCategory = event?.category ?? EventCategory.sport;
    selectedDate = event?.dateTime ?? DateTime.now();
    selectedTime = TimeOfDay.fromDateTime(selectedDate);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    var today = DateUtils.dateOnly(DateTime.now());
    var firstDate = selectedDate.isBefore(today) ? selectedDate : today;
    var lastDate = today.add(const Duration(days: 365));
    if (selectedDate.isAfter(lastDate)) lastDate = selectedDate;
    var date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date != null && mounted) setState(() => selectedDate = date);
  }

  Future<void> chooseTime() async {
    var time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (time != null && mounted) setState(() => selectedTime = time);
  }

  Future<void> updateEvent() async {
    if (saving || !formKey.currentState!.validate()) return;
    var event = EventDM(
      id: original?.id ?? '',
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      dateTime: DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
      category: selectedCategory,
      isFavorite: original?.isFavorite ?? false,
    );
    setState(() => saving = true);
    try {
      var collection = userEvents(uid);
      if (original == null) {
        var document = collection.doc();
        event.id = document.id;
        await document.set(event.toFirestore());
      } else {
        var changes = event.toFirestore();
        changes.remove('is_favorite');
        await collection.doc(event.id).update(changes);
      }
    } on FirebaseException {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            label(context, 'Could not save the event', 'تعذر حفظ الفعالية'),
          ),
        ),
      );
      return;
    }
    if (mounted) Navigator.pop(context, event);
  }

  @override
  Widget build(BuildContext context) {
    var blue = Theme.of(context).colorScheme.primary;
    var date = MaterialLocalizations.of(context).formatShortDate(selectedDate);

    var screenTitle = original == null
        ? label(context, 'Add Event', 'إضافة فعالية')
        : label(context, 'Edit Event', 'تعديل الفعالية');

    return Scaffold(
      appBar: AppBar(title: Text(screenTitle)),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(selectedCategory.imagePath),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var category in EventCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(category.icon, size: 18),
                        label: Text(category.displayName(context)),
                        selected: selectedCategory == category,
                        onSelected: (selected) {
                          setState(() => selectedCategory = category);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(label(context, 'Title', 'العنوان')),
            const SizedBox(height: 6),
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: label(context, 'Event Title', 'عنوان الفعالية'),
              ),
              validator: (value) {
                return value == null || value.trim().isEmpty
                    ? label(context, 'Enter a title', 'أدخل عنوانًا')
                    : null;
              },
            ),
            const SizedBox(height: 14),
            Text(label(context, 'Description', 'الوصف')),
            const SizedBox(height: 6),
            TextFormField(
              controller: descriptionController,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: label(context, 'Event Description', 'وصف الفعالية'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: blue),
                const SizedBox(width: 8),
                Text(label(context, 'Event Date', 'تاريخ الفعالية')),
                const Spacer(),
                TextButton(onPressed: chooseDate, child: Text(date)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.schedule, color: blue),
                const SizedBox(width: 8),
                Text(label(context, 'Event Time', 'وقت الفعالية')),
                const Spacer(),
                TextButton(
                  onPressed: chooseTime,
                  child: Text(selectedTime.format(context)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: saving ? null : updateEvent,
              child: Text(screenTitle),
            ),
          ],
        ),
      ),
    );
  }
}
