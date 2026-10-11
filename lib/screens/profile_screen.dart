import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Screen allowing the user to update their name, causes, skills,
/// availability, and distance preferences, and inspect volunteering impact.
class ProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback onProfileSaved;
  final VoidCallback onResetData;

  const ProfileScreen({
    super.key,
    required this.userProfile,
    required this.onProfileSaved,
    required this.onResetData,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late Set<String> _selectedCauses;
  late Set<String> _userSkills;
  late Set<String> _availableDays;
  late int _maxDistanceKm;

  final List<String> _allCauses = [
    'Environment',
    'Education',
    'Animal Welfare',
    'Community',
    'Healthcare',
  ];

  final List<String> _allSkills = [
    'Teamwork',
    'Teaching',
    'Gardening',
    'Communication',
    'First Aid',
    'Animal Care',
    'Logistics',
  ];

  final List<String> _allDays = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.name);
    _selectedCauses = Set<String>.from(widget.userProfile.selectedCauses);
    _userSkills = Set<String>.from(widget.userProfile.userSkills);
    _availableDays = Set<String>.from(widget.userProfile.availableDays);
    _maxDistanceKm = widget.userProfile.maxDistanceKm;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid display name.')),
      );
      return;
    }

    if (_selectedCauses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one cause of interest.')),
      );
      return;
    }

    if (_availableDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one available day.')),
      );
      return;
    }

    setState(() {
      widget.userProfile.name = _nameController.text.trim();
      widget.userProfile.selectedCauses = _selectedCauses;
      widget.userProfile.userSkills = _userSkills;
      widget.userProfile.availableDays = _availableDays;
      widget.userProfile.maxDistanceKm = _maxDistanceKm;
    });

    widget.onProfileSaved();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.forestGreen,
        content: Text('Preferences and profile saved successfully!'),
      ),
    );
  }

  void _confirmReset() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
          'This will clear all bookmarks, joined activities, and recorded hours, resetting the app to default demo state.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService.clearProfile();
              widget.onResetData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data reset to initial demo state.')),
                );
              }
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = widget.userProfile.totalCompletedHours;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Profile card
              Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.paleGreen,
                    child: Icon(Icons.person, size: 36, color: AppTheme.forestGreenDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userProfile.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.forestGreenDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.userProfile.impactLevel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Impact metrics overview card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statCol('Verified Hours', '$totalHours', Icons.timer),
                      Container(height: 32, width: 1, color: Colors.grey.shade300),
                      _statCol(
                        'Completed',
                        '${widget.userProfile.completedLogs.length}',
                        Icons.verified,
                      ),
                      Container(height: 32, width: 1, color: Colors.grey.shade300),
                      _statCol(
                        'Active Joined',
                        '${widget.userProfile.joinedOpportunityIds.length}',
                        Icons.handshake,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Name Editor
              const Text(
                'Display Name',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Cause Preferences (40 pts)
              Row(
                children: [
                  const Text(
                    'Causes of Interest',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.paleGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '40 pts in engine',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.forestGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Select causes you care most about to receive prioritized recommendations.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allCauses.map((cause) {
                  final isSelected = _selectedCauses.contains(cause);
                  return FilterChip(
                    label: Text(cause),
                    selected: isSelected,
                    selectedColor: AppTheme.paleGreen,
                    checkmarkColor: AppTheme.forestGreenDark,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCauses.add(cause);
                        } else {
                          _selectedCauses.remove(cause);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // Skills Preferences (30 pts)
              Row(
                children: [
                  const Text(
                    'Your Skills',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.paleGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '30 pts in engine',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.forestGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Select skills you possess to match with opportunity prerequisites.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allSkills.map((skill) {
                  final isSelected = _userSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    selectedColor: AppTheme.paleGreen,
                    checkmarkColor: AppTheme.forestGreenDark,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _userSkills.add(skill);
                        } else {
                          _userSkills.remove(skill);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // Availability Preferences (30 pts)
              Row(
                children: [
                  const Text(
                    'Available Days',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.paleGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '30 pts in engine',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.forestGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Days when you are available for volunteering sessions.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allDays.map((day) {
                  final isSelected = _availableDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    selectedColor: AppTheme.paleGreen,
                    checkmarkColor: AppTheme.forestGreenDark,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _availableDays.add(day);
                        } else {
                          _availableDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // Preferred Distance Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Max Distance Radius',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '$_maxDistanceKm km',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _maxDistanceKm.toDouble(),
                min: 2,
                max: 25,
                divisions: 23,
                activeColor: AppTheme.forestGreen,
                label: '$_maxDistanceKm km',
                onChanged: (val) => setState(() => _maxDistanceKm = val.round()),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Profile & Preferences'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmReset,
                  icon: const Icon(Icons.restore, color: Colors.red),
                  label: const Text(
                    'Reset Demo State',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Compliance & Disclosure card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: AppTheme.forestGreenDark),
                        SizedBox(width: 6),
                        Text(
                          'Compliance & Transparency Notice',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.forestGreenDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Recommendation Engine: Pure deterministic Dart rule algorithm (Causes: 40 pts, Skills: 30 pts, Availability: 30 pts). No external AI black box used in scoring.\n'
                      '• Sample Dataset: All opportunities are simulated demo entries for testing.\n'
                      '• Local Data Persistence: Storage is performed via local on-device SharedPreferences.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.forestGreen),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
