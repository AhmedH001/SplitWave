import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_user.dart';
import '../../models/vacation.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/vacation_card.dart';
import '../vacations/create_vacation_screen.dart';
import '../vacation_detail/vacation_home_screen.dart';
import '../profile/profile_screen.dart';

class VacationsListScreen extends StatefulWidget {
  const VacationsListScreen({super.key});

  @override
  State<VacationsListScreen> createState() => _VacationsListScreenState();
}

class _VacationsListScreenState extends State<VacationsListScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentAppUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  void _openVacation(Vacation vacation) {
    Navigator.of(context).push(
      SlidePageRoute(
        page: VacationHomeScreen(vacationId: vacation.id),
      ),
    );
  }

  void _createVacation() {
    Navigator.of(context).push(
      SlidePageRoute(page: const CreateVacationScreen()),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      SlidePageRoute(page: const ProfileScreen()),
    ).then((_) => _loadUser());
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Matroh 🏖️',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentUser != null
                                ? 'Welcome back, ${_currentUser!.name}!'
                                : 'Your vacations',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _openProfile,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _currentUser?.avatarEmoji ?? '🏖️',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_currentUser?.isAdmin == true) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 14, color: AppColors.gold),
                        SizedBox(width: 4),
                        Text(
                          'Admin',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Vacations list
              Expanded(
                child: StreamBuilder<List<Vacation>>(
                  stream: _firestoreService.getUserVacations(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.negative,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Error loading vacations',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              snapshot.error.toString(),
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final vacations = snapshot.data ?? [];

                    if (vacations.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async {
                        // Stream auto-refreshes, but this provides visual feedback.
                        await Future.delayed(
                            const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: vacations.length,
                        itemBuilder: (context, index) {
                          final vacation = vacations[index];
                          return VacationCard(
                            vacation: vacation,
                            index: index,
                            onTap: () => _openVacation(vacation),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _currentUser?.isAdmin == true
          ? FloatingActionButton.extended(
              onPressed: _createVacation,
              icon: const Icon(Icons.add),
              label: const Text('New Vacation'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
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
            child: const Text('🌴', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No vacations yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentUser?.isAdmin == true
                ? 'Create your first vacation!'
                : 'Ask an admin to add you to a vacation',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}


