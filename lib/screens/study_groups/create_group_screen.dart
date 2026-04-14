import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../core/providers/campus_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '5');
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_subjectController.text.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final campus = ref.read(selectedCampusProvider);
      final user = Supabase.instance.client.auth.currentUser!;
      
      final dateTimeStr = '${_selectedDate!.toIso8601String().split('T')[0]} ${_selectedTime!.format(context)}';

      // 1. Create the group
      final response = await Supabase.instance.client.from('study_groups').insert({
        'campus_id': campus!['campus_id'],
        'creator_id': user.id,
        'creator_name': user.userMetadata?['full_name'] ?? 'Student',
        'subject': _subjectController.text,
        'description': _descriptionController.text,
        'date_time': dateTimeStr,
        'location': _locationController.text,
        'max_members': int.tryParse(_maxMembersController.text) ?? 5,
        'member_count': 1,
      }).select().single();

      // 2. Add creator as first approved member
      await Supabase.instance.client.from('study_group_members').insert({
        'group_id': response['id'],
        'user_id': user.id,
        'status': 'approved',
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Create Study Group'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(hintText: 'Subject (e.g., Physics 101)', prefixIcon: Icon(Icons.book)),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Description', prefixIcon: Icon(Icons.description)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(_selectedDate == null ? 'Select Date' : _selectedDate!.toLocal().toString().split(' ')[0]),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                    leading: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (picked != null) setState(() => _selectedTime = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(hintText: 'Location (e.g., Library)', prefixIcon: Icon(Icons.location_on)),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _maxMembersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Max Members', prefixIcon: Icon(Icons.people)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
