import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/member_selector.dart';

class AddExpenseScreen extends StatefulWidget {
  final String vacationId;
  final Map<String, String> memberNames;
  final List<String> memberIds;
  final Expense? expense;

  const AddExpenseScreen({
    super.key,
    required this.vacationId,
    required this.memberNames,
    required this.memberIds,
    this.expense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late List<String> _splitWith;
  bool _isSubmitting = false;

  late AnimationController _submitAnimController;
  late Animation<double> _submitScale;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing.
    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toStringAsFixed(2);
      _descriptionController.text = widget.expense!.description;
      _selectedDate = widget.expense!.date;
      _splitWith = List<String>.from(widget.expense!.splitWith);
    } else {
      _splitWith = List<String>.from(widget.memberIds);
    }

    _submitAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _submitScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _submitAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _submitAnimController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_splitWith.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one person to split with'),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }

    // Haptic feedback + animation
    HapticFeedback.mediumImpact();
    _submitAnimController.forward().then((_) {
      _submitAnimController.reverse();
    });

    setState(() => _isSubmitting = true);

    try {
      final user = _authService.currentUser!;
      final userName = widget.memberNames[user.uid] ?? user.displayName ?? 'Unknown';

      final amount = double.parse(
        _amountController.text.trim().replaceAll(',', ''),
      );

      if (widget.expense != null) {
        final updatedExpense = Expense(
          id: widget.expense!.id,
          vacationId: widget.vacationId,
          payerId: widget.expense!.payerId,
          payerName: widget.expense!.payerName,
          amount: amount,
          description: _descriptionController.text.trim(),
          splitWith: _splitWith,
          date: _selectedDate,
          createdAt: widget.expense!.createdAt,
        );
        await _firestoreService.updateExpense(widget.vacationId, updatedExpense);
      } else {
        final expense = Expense(
          id: '',
          vacationId: widget.vacationId,
          payerId: user.uid,
          payerName: userName,
          amount: amount,
          description: _descriptionController.text.trim(),
          splitWith: _splitWith,
          date: _selectedDate,
        );
        await _firestoreService.addExpense(widget.vacationId, expense);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.expense != null ? 'Expense updated! 💰' : 'Expense added! 💰'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
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
    final dateFormat = DateFormat('EEE, MMM d');

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
                      icon: const Icon(Icons.close,
                          color: AppColors.textPrimary, size: 22),
                    ),
                    Expanded(
                      child: Text(
                        widget.expense != null ? 'Edit Expense' : 'Add Expense',
                        style: const TextStyle(
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
                        const SizedBox(height: 8),

                        // Amount (big prominent input)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: GlassDecoration(
                            borderRadius: 24,
                            highlight: true,
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'How much?',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _amountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: '0.00',
                                        hintStyle: TextStyle(
                                          color: Color(0x40FFD700),
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Enter amount';
                                        }
                                        final parsed = double.tryParse(
                                            v.trim().replaceAll(',', ''));
                                        if (parsed == null || parsed <= 0) {
                                          return 'Enter a valid amount';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'EGP',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'What was it for?',
                            prefixIcon: Icon(Icons.edit_note,
                                color: AppColors.textTertiary),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter a description'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // Date picker
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: GlassDecoration(),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColors.textTertiary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  dateFormat.format(_selectedDate),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textTertiary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Member selector
                        MemberSelector(
                          memberNames: widget.memberNames,
                          selectedIds: _splitWith,
                          onChanged: (ids) {
                            setState(() => _splitWith = ids);
                          },
                        ),

                        const SizedBox(height: 32),

                        // Submit button
                        ScaleTransition(
                          scale: _submitScale,
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      widget.expense != null
                                          ? 'Save Changes 💾'
                                          : 'Add Expense 💰',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
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
}
