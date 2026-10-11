import 'package:flutter/material.dart';
import '../../models/opportunity.dart';
import '../../models/provider_profile.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

/// Form screen for creating or editing an opportunity.
/// Validates required fields, prevents negative slots and zero durations.
class CreateOpportunityScreen extends StatefulWidget {
  final ProviderProfile providerProfile;
  final Opportunity? existingOpportunity; // If non-null, in edit mode
  final VoidCallback onOpportunitySaved;

  const CreateOpportunityScreen({
    super.key,
    required this.providerProfile,
    this.existingOpportunity,
    required this.onOpportunitySaved,
  });

  @override
  State<CreateOpportunityScreen> createState() => _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState extends State<CreateOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  late TextEditingController _hoursController;
  late TextEditingController _slotsController;
  late TextEditingController _skillsController;

  String _selectedCause = 'Environment';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  final List<String> _causes = [
    'Environment',
    'Education',
    'Food Donation',
    'Animal Welfare',
    'Community Support',
    'Healthcare',
  ];

  bool get _isEditing => widget.existingOpportunity != null;

  @override
  void initState() {
    super.initState();
    final opp = widget.existingOpportunity;
    _titleController = TextEditingController(text: opp?.title ?? '');
    _descController = TextEditingController(text: opp?.description ?? '');
    _locationController = TextEditingController(text: opp?.location ?? '');
    _hoursController = TextEditingController(text: opp != null ? '${opp.hours}' : '3');
    _slotsController = TextEditingController(text: opp != null ? '${opp.spotsTotal}' : '10');
    _skillsController = TextEditingController(
      text: opp != null ? opp.requiredSkills.join(', ') : 'Teamwork, Communication',
    );
    if (opp != null && _causes.contains(opp.cause)) {
      _selectedCause = opp.cause;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _hoursController.dispose();
    _slotsController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  String _dayOfWeek(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _saveOpportunity() async {
    if (!_formKey.currentState!.validate()) return;

    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final slots = int.tryParse(_slotsController.text.trim()) ?? 0;

    if (hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration must be at least 1 hour.')),
      );
      return;
    }

    if (slots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Volunteer capacity must be at least 1 spot.')),
      );
      return;
    }

    final skillsList = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final timeString = '${_formatTime(_startTime)} - ${_formatTime(_endTime)}';
    final dateString = _formatDate(_selectedDate);
    final dayStr = _dayOfWeek(_selectedDate);

    if (_isEditing) {
      final updated = widget.existingOpportunity!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        cause: _selectedCause,
        location: _locationController.text.trim(),
        date: dateString,
        time: timeString,
        dayOfWeek: dayStr,
        hours: hours,
        spotsTotal: slots,
        requiredSkills: skillsList,
        organizer: widget.providerProfile.organizationName,
      );
      await StorageService.updateOpportunity(updated, widget.providerProfile.id);
    } else {
      final newOpp = Opportunity(
        id: 'opp-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        cause: _selectedCause,
        location: _locationController.text.trim(),
        date: dateString,
        time: timeString,
        dayOfWeek: dayStr,
        hours: hours,
        distanceKm: 5, // Default local estimate
        spotsTotal: slots,
        spotsFilled: 0,
        requiredSkills: skillsList,
        organizer: widget.providerProfile.organizationName,
        providerId: widget.providerProfile.id,
        status: 'open',
        isSample: false,
      );
      await StorageService.createOpportunity(newOpp);
    }

    widget.onOpportunitySaved();

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.forestGreen,
        content: Text(
          _isEditing ? 'Opportunity updated successfully!' : 'Opportunity published successfully!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmWhite,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Opportunity' : 'Create Opportunity'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEditing ? 'Update Activity Details' : 'Publish New Activity',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreenDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditing
                      ? 'Changes will be immediately visible to volunteers.'
                      : 'Create a community opportunity and set volunteer capacity.',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 18),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Opportunity Title *',
                    hintText: 'e.g. Riverside Park Cleanup & Tree Planting',
                    prefixIcon: const Icon(Icons.title, color: AppTheme.forestGreen),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Please enter a title.' : null,
                ),
                const SizedBox(height: 14),

                // Cause Category
                DropdownButtonFormField<String>(
                  initialValue: _selectedCause,
                  decoration: InputDecoration(
                    labelText: 'Cause Category *',
                    prefixIcon: const Icon(Icons.category, color: AppTheme.forestGreen),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _causes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCause = val);
                  },
                ),
                const SizedBox(height: 14),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location / Venue *',
                    hintText: 'e.g. Central Community Center, Room 102',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.forestGreen),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Please enter a location.' : null,
                ),
                const SizedBox(height: 14),

                // Date Picker Tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.forestGreen, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Event Date *', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              '${_formatDate(_selectedDate)} (${_dayOfWeek(_selectedDate)})',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _pickDate,
                        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                        child: const Text('Change Date'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: InkWell(
                          onTap: _pickStartTime,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(_formatTime(_startTime), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: InkWell(
                          onTap: _pickEndTime,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(_formatTime(_endTime), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Duration & Capacity
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Duration (Hours) *',
                          prefixIcon: const Icon(Icons.timer_outlined, color: AppTheme.forestGreen),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          final h = int.tryParse(val ?? '');
                          if (h == null || h <= 0) return 'Must be >= 1 hr';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _slotsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Capacity (Slots) *',
                          prefixIcon: const Icon(Icons.group_outlined, color: AppTheme.forestGreen),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          final s = int.tryParse(val ?? '');
                          if (s == null || s <= 0) return 'Must be >= 1 spot';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Required Skills
                TextFormField(
                  controller: _skillsController,
                  decoration: InputDecoration(
                    labelText: 'Required Skills (comma separated)',
                    hintText: 'e.g. Gardening, Teamwork, First Aid',
                    prefixIcon: const Icon(Icons.handyman_outlined, color: AppTheme.forestGreen),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Activity Description *',
                    hintText: 'Describe volunteer responsibilities, what to bring, and impact goals...',
                    prefixIcon: const Icon(Icons.description_outlined, color: AppTheme.forestGreen),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Please enter a description.' : null,
                ),
                const SizedBox(height: 24),

                // Submit Button
                FilledButton.icon(
                  onPressed: _saveOpportunity,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.forestGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(_isEditing ? Icons.save : Icons.publish),
                  label: Text(
                    _isEditing ? 'Save Opportunity Changes' : 'Publish Opportunity',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
