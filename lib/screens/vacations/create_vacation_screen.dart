import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/app_user.dart';
import '../../models/vacation.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class CreateVacationScreen extends StatefulWidget {
  const CreateVacationScreen({super.key});

  @override
  State<CreateVacationScreen> createState() => _CreateVacationScreenState();
}

class _CreateVacationScreenState extends State<CreateVacationScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  final List<AppUser> _addedMembers = [];
  List<AppUser> _allUsers = [];
  bool _isCreating = false;
  bool _isLoadingUsers = true;
  AppUser? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _firestoreService.getAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// Users available for the dropdown (excludes current user and already added members).
  List<AppUser> get _availableUsers {
    final currentUid = _authService.currentUser?.uid;
    final addedUids = _addedMembers.map((m) => m.uid).toSet();
    return _allUsers.where((u) => u.uid != currentUid && !addedUids.contains(u.uid)).toList();
  }

  void _addSelectedMember() {
    if (_selectedUser == null) return;
    setState(() {
      _addedMembers.add(_selectedUser!);
      _selectedUser = null;
    });
  }

  Future<void> _createVacation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final currentUser = await _authService.getCurrentAppUser();
      if (currentUser == null) throw Exception('Not signed in');

      // Build member lists including the creator.
      final memberIds = [
        currentUser.uid,
        ..._addedMembers.map((m) => m.uid),
      ];
      final memberNames = {
        currentUser.uid: currentUser.name,
        for (final m in _addedMembers) m.uid: m.name,
      };

      final vacation = Vacation(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        createdBy: currentUser.uid,
        memberIds: memberIds,
        memberNames: memberNames,
      );

      await _firestoreService.createVacation(vacation);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vacation created! 🎉'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    const Expanded(
                      child: Text(
                        'Create Vacation',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name
                        _buildSectionLabel('Vacation Name'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'e.g., Matroh 2026',
                            prefixIcon: Icon(Icons.beach_access_outlined,
                                color: AppColors.textTertiary),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter a name'
                              : null,
                        ),

                        const SizedBox(height: 20),

                        // Description
                        _buildSectionLabel('Description (optional)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Summer beach trip with the crew',
                            prefixIcon: Icon(Icons.notes_outlined,
                                color: AppColors.textTertiary),
                          ),
                          maxLines: 2,
                        ),

                        const SizedBox(height: 24),

                        // Date range
                        _buildSectionLabel('Dates'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateButton(
                                label: 'Start',
                                date: dateFormat.format(_startDate),
                                onTap: () => _pickDate(true),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.arrow_forward,
                                  color: AppColors.textTertiary, size: 18),
                            ),
                            Expanded(
                              child: _buildDateButton(
                                label: 'End',
                                date: dateFormat.format(_endDate),
                                onTap: () => _pickDate(false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_endDate.difference(_startDate).inDays + 1} days',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Members
                        _buildSectionLabel('Add Members'),
                        const SizedBox(height: 4),
                        const Text(
                          'You\'re automatically added as a member',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingUsers)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                  color: AppColors.primary),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<AppUser>(
                                  initialValue: _selectedUser,
                                  dropdownColor: AppColors.surface,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: 'Select a member',
                                    prefixIcon: Icon(
                                        Icons.person_add_outlined,
                                        color: AppColors.textTertiary),
                                  ),
                                  items: _availableUsers.map((user) {
                                    return DropdownMenuItem<AppUser>(
                                      value: user,
                                      child: Text(
                                        '${user.avatarEmoji} ${user.name}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (user) {
                                    setState(() => _selectedUser = user);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _selectedUser == null
                                      ? null
                                      : _addSelectedMember,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  ),
                                  child: const Text('Add'),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 12),

                        // Added members list
                        ..._addedMembers.asMap().entries.map((entry) {
                          final member = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: GlassDecoration(),
                            child: Row(
                              children: [
                                Text(member.avatarEmoji,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        member.email,
                                        style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _addedMembers.removeAt(entry.key);
                                    });
                                  },
                                  icon: const Icon(Icons.close,
                                      color: AppColors.textTertiary, size: 18),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 32),

                        // Create button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : _createVacation,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isCreating
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Create Vacation 🏖️',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required String date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: GlassDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
