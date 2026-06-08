import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/vacation.dart';
import '../../models/expense.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/expense_card.dart';
import 'add_expense_screen.dart';
import 'summary_screen.dart';

class VacationHomeScreen extends StatefulWidget {
  final String vacationId;

  const VacationHomeScreen({super.key, required this.vacationId});

  @override
  State<VacationHomeScreen> createState() => _VacationHomeScreenState();
}

class _VacationHomeScreenState extends State<VacationHomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  AppUser? _currentAppUser;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentAppUser();
    if (!mounted) return;
    setState(() {
      _currentAppUser = user;
    });
  }

  void _addExpense(Vacation vacation) {
    Navigator.of(context).push(
      SlidePageRoute(
        page: AddExpenseScreen(
          vacationId: vacation.id,
          memberNames: vacation.memberNames,
          memberIds: vacation.memberIds,
        ),
      ),
    );
  }

  void _editExpense(Vacation vacation, Expense expense) {
    Navigator.of(context).push(
      SlidePageRoute(
        page: AddExpenseScreen(
          vacationId: vacation.id,
          memberNames: vacation.memberNames,
          memberIds: vacation.memberIds,
          expense: expense,
        ),
      ),
    );
  }

  Future<bool> _showAddMemberDialog(Vacation vacation) async {
    var isLoading = true;
    List<AppUser> availableUsers = [];
    AppUser? selectedUser;
    var isSaving = false;
    String? errorText;

    // Pre-fetch users before showing the dialog.
    try {
      final allUsers = await _firestoreService.getAllUsers();
      availableUsers = allUsers
          .where((u) => !vacation.memberIds.contains(u.uid))
          .toList();
      isLoading = false;
    } catch (e) {
      isLoading = false;
      errorText = 'Failed to load users';
    }

    if (!mounted) return false;
    final scaffoldContext = context;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Add member'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else if (availableUsers.isEmpty)
                  const Text(
                    'No more users available to add',
                    style: TextStyle(color: AppColors.textTertiary),
                  )
                else
                  DropdownButtonFormField<AppUser>(
                    initialValue: selectedUser,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Select a user',
                      prefixIcon: Icon(Icons.person_add_outlined,
                          color: AppColors.textTertiary),
                    ),
                    items: availableUsers.map((user) {
                      return DropdownMenuItem<AppUser>(
                        value: user,
                        child: Text(
                          '${user.avatarEmoji} ${user.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (user) {
                      setState(() => selectedUser = user);
                    },
                  ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: const TextStyle(
                        color: AppColors.negative, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    isSaving ? null : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (isSaving || selectedUser == null)
                    ? null
                    : () async {
                        final currentDialogContext = dialogContext;
                        setState(() {
                          isSaving = true;
                          errorText = null;
                        });

                        try {
                          await _firestoreService.addMemberToVacation(
                              vacation.id, selectedUser!.email);
                          if (!currentDialogContext.mounted) return;
                          Navigator.of(currentDialogContext).pop(true);
                        } catch (e) {
                          if (!currentDialogContext.mounted) return;
                          setState(() {
                            isSaving = false;
                            errorText = 'Error: ${e.toString()}';
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Add'),
              ),
            ],
          );
        });
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          content: Text('Member added successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
    }

    return result == true;
  }

  Future<bool> _showEditVacationDialog(Vacation vacation) async {
    final nameController = TextEditingController(text: vacation.name);
    final descriptionController = TextEditingController(text: vacation.description ?? '');
    DateTime startDate = vacation.startDate;
    DateTime endDate = vacation.endDate;
    var isSaving = false;
    String? errorText;

    final scaffoldContext = context;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Edit vacation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: startDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                startDate = picked;
                                if (endDate.isBefore(startDate)) {
                                  endDate = startDate.add(const Duration(days: 1));
                                }
                              });
                            }
                          },
                          child: Text('Start: ${DateFormat('MMM d, yyyy').format(startDate)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                endDate = picked;
                              });
                            }
                          },
                          child: Text('End: ${DateFormat('MMM d, yyyy').format(endDate)}'),
                        ),
                      ),
                    ],
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(errorText ?? '', style: const TextStyle(color: AppColors.negative)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final currentDialogContext = dialogContext;
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          setState(() {
                            errorText = 'Vacation name cannot be empty';
                          });
                          return;
                        }

                        setState(() {
                          isSaving = true;
                          errorText = null;
                        });

                        try {
                          final updatedVacation = vacation.copyWith(
                            name: name,
                            description: descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            startDate: startDate,
                            endDate: endDate,
                          );
                          await _firestoreService.updateVacation(updatedVacation);
                          if (!currentDialogContext.mounted) return;
                          Navigator.of(currentDialogContext).pop(true);
                        } catch (e) {
                          if (!currentDialogContext.mounted) return;
                          setState(() {
                            isSaving = false;
                            errorText = 'Error: ${e.toString()}';
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        });
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          content: Text('Vacation updated'),
          backgroundColor: AppColors.primary,
        ),
      );
    }

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Vacation?>(
      stream: _firestoreService.getVacation(widget.vacationId),
      builder: (context, vacSnapshot) {
        final vacation = vacSnapshot.data;
        if (vacation == null) {
          return Scaffold(
            body: Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        return StreamBuilder<List<Expense>>(
          stream: _firestoreService.getExpenses(widget.vacationId),
          builder: (context, expSnapshot) {
            final expenses = expSnapshot.data ?? [];

            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.backgroundGradient),
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
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    vacation.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${vacation.memberCount} members • ${vacation.durationDays} days',
                                    style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildMemberChips(vacation),
                                ],
                              ),
                            ),
                            if (_currentAppUser?.isAdmin == true) ...[
                              IconButton(
                                onPressed: () => _showAddMemberDialog(vacation),
                                icon: const Icon(
                                  Icons.person_add_alt_1_outlined,
                                  color: AppColors.textPrimary,
                                ),
                                tooltip: 'Add member',
                              ),
                              IconButton(
                                onPressed: () => _showEditVacationDialog(vacation),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.textPrimary,
                                ),
                                tooltip: 'Edit vacation',
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Stats header
                      _buildStatsHeader(vacation, expenses),

                      // Tab bar
                      _buildTabBar(),

                      // Content
                      Expanded(
                        child: _currentTab == 0
                            ? _buildExpensesList(vacation, expenses)
                            : SummaryScreen(
                                vacation: vacation,
                                expenses: expenses,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton: _currentTab == 0
                  ? FloatingActionButton.extended(
                      onPressed: () => _addExpense(vacation),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Expense'),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildStatsHeader(Vacation vacation, List<Expense> expenses) {
    final total = _firestoreService.calculateTotal(expenses);
    final uid = _authService.currentUser?.uid ?? '';
    final balances = _firestoreService.calculateBalances(
      expenses,
      vacation.memberNames,
    );
    final myBalance = balances[uid] ?? 0;
    final numberFormat = NumberFormat('#,##0', 'en_US');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: GlassDecoration(highlight: true),
      child: Row(
        children: [
          // Total spent
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Spent',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${numberFormat.format(total)} EGP',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${expenses.length} expenses',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 48,
            color: AppColors.glassBorder,
          ),
          const SizedBox(width: 16),

          // My balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Your Balance',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${myBalance >= 0 ? '+' : ''}${numberFormat.format(myBalance)} EGP',
                style: TextStyle(
                  color: myBalance >= 0 ? AppColors.positive : AppColors.negative,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                myBalance >= 0 ? 'you receive' : 'you owe',
                style: TextStyle(
                  color: (myBalance >= 0 ? AppColors.positive : AppColors.negative)
                      .withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberChips(Vacation vacation) {
    if (vacation.memberNames.isEmpty) return const SizedBox();

    final currentUid = _authService.currentUser?.uid;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: vacation.memberNames.entries.map((entry) {
        final isCurrent = entry.key == currentUid;
        return Chip(
          backgroundColor: AppColors.surface,
          labelStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
          label: Text('${entry.value}${isCurrent ? ' (You)' : ''}'),
        );
      }).toList(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          _buildTab('Expenses', Icons.receipt_long_outlined, 0),
          _buildTab('Summary', Icons.analytics_outlined, 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, int index) {
    final isActive = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.primary : AppColors.textTertiary,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesList(Vacation vacation, List<Expense> expenses) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: const Text('💸', style: TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 12),
            const Text(
              'No expenses yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap + to add your first expense',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final canDelete =
            expense.payerId == _authService.currentUser?.uid;

        return ExpenseCard(
          expense: expense,
          memberCount: vacation.memberCount,
          memberNames: vacation.memberNames,
          index: index,
          onTap: canDelete ? () => _editExpense(vacation, expense) : null,
          onDelete: canDelete
              ? () {
                  _firestoreService.deleteExpense(
                      widget.vacationId, expense.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense deleted'),
                      backgroundColor: AppColors.surface,
                    ),
                  );
                }
              : null,
        );
      },
    );
  }
}
