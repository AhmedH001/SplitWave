import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/vacation.dart';
import '../models/expense.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── User Operations ──────────────────────────────────────────────

  /// Get a user by UID.
  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Get a user by email.
  Future<AppUser?> getUserByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return AppUser.fromFirestore(query.docs.first);
  }

  /// Update a user's profile.
  Future<void> updateUser(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toFirestore());
  }

  /// Update the user's avatar emoji.
  Future<void> updateAvatar(String uid, String emoji) async {
    await _firestore.collection('users').doc(uid).update({'avatarEmoji': emoji});
  }

  /// Update a user's name across all vacations where they are a member.
  Future<void> updateUserNameAcrossVacations(String uid, String newName) async {
    final snapshot = await _firestore
        .collection('vacations')
        .where('memberIds', arrayContains: uid)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'memberNames.$uid': newName});
    }
    await batch.commit();
  }

  /// Get all registered users in the system.
  Future<List<AppUser>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }

  // ─── Vacation Operations ──────────────────────────────────────────

  /// Create a new vacation.
  Future<String> createVacation(Vacation vacation) async {
    final docRef = await _firestore.collection('vacations').add(vacation.toFirestore());
    return docRef.id;
  }

  /// Update an existing vacation.
  Future<void> updateVacation(Vacation vacation) async {
    await _firestore.collection('vacations').doc(vacation.id).update(vacation.toFirestore());
  }

  /// Get all vacations the user is a member of (real-time stream).
  Stream<List<Vacation>> getUserVacations(String uid) {
    return _firestore
        .collection('vacations')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final vacations = snapshot.docs.map((doc) => Vacation.fromFirestore(doc)).toList();
      // Sort client-side by startDate descending to avoid requiring a composite index.
      vacations.sort((a, b) => b.startDate.compareTo(a.startDate));
      return vacations;
    });
  }

  /// Get a single vacation by ID (real-time stream).
  Stream<Vacation?> getVacation(String vacationId) {
    return _firestore
        .collection('vacations')
        .doc(vacationId)
        .snapshots()
        .map((doc) => doc.exists ? Vacation.fromFirestore(doc) : null);
  }

  /// Add a member to a vacation by email.
  /// Returns the added user or null if not found.
  Future<AppUser?> addMemberToVacation(String vacationId, String email) async {
    final user = await getUserByEmail(email);
    if (user == null) return null;

    final vacDoc = _firestore.collection('vacations').doc(vacationId);
    await vacDoc.update({
      'memberIds': FieldValue.arrayUnion([user.uid]),
      'memberNames.${user.uid}': user.name,
    });

    return user;
  }

  /// Remove a member from a vacation.
  Future<void> removeMemberFromVacation(String vacationId, String userId) async {
    final vacDoc = _firestore.collection('vacations').doc(vacationId);
    final snap = await vacDoc.get();
    if (!snap.exists) return;

    final vacation = Vacation.fromFirestore(snap);
    final updatedNames = Map<String, String>.from(vacation.memberNames);
    updatedNames.remove(userId);

    await vacDoc.update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'memberNames': updatedNames,
    });
  }

  // ─── Expense Operations ───────────────────────────────────────────

  /// Add a new expense to a vacation.
  Future<String> addExpense(String vacationId, Expense expense) async {
    final docRef = await _firestore
        .collection('vacations')
        .doc(vacationId)
        .collection('expenses')
        .add(expense.toFirestore());
    return docRef.id;
  }

  /// Get all expenses for a vacation (real-time stream, ordered by date).
  Stream<List<Expense>> getExpenses(String vacationId) {
    return _firestore
        .collection('vacations')
        .doc(vacationId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromFirestore(doc, vacationId))
            .toList());
  }

  /// Delete an expense.
  Future<void> deleteExpense(String vacationId, String expenseId) async {
    await _firestore
        .collection('vacations')
        .doc(vacationId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  /// Update an existing expense.
  Future<void> updateExpense(String vacationId, Expense expense) async {
    await _firestore
        .collection('vacations')
        .doc(vacationId)
        .collection('expenses')
        .doc(expense.id)
        .update(expense.toFirestore());
  }

  /// Record a settlement payment as an expense.
  Future<String> addSettlementPayment({
    required String vacationId,
    required String debtorId,
    required String debtorName,
    required String creditorId,
    required String creditorName,
    required double amount,
  }) async {
    final expense = Expense(
      id: '',
      vacationId: vacationId,
      payerId: debtorId,
      payerName: debtorName,
      amount: amount,
      description: 'Paid $creditorName 🤝',
      splitWith: [creditorId],
      date: DateTime.now(),
    );
    return await addExpense(vacationId, expense);
  }

  // ─── Settlement Calculations ──────────────────────────────────────

  /// Calculate how much each person spent and owes.
  /// Returns a map of userId → balance (positive = receives, negative = gives).
  Map<String, double> calculateBalances(
    List<Expense> expenses,
    Map<String, String> memberNames,
  ) {
    final balances = <String, double>{};

    // Initialize all members with 0 balance.
    for (final uid in memberNames.keys) {
      balances[uid] = 0.0;
    }

    for (final expense in expenses) {
      // The payer contributed this amount.
      balances[expense.payerId] =
          (balances[expense.payerId] ?? 0) + expense.amount;

      // Each person in the split owes their share.
      final share = expense.perPersonShare;
      for (final uid in expense.splitWith) {
        balances[uid] = (balances[uid] ?? 0) - share;
      }
    }

    return balances;
  }

  /// Calculate the minimized settlement transactions.
  /// Uses a greedy algorithm to minimize the number of transfers.
  List<Settlement> calculateSettlements(
    List<Expense> expenses,
    Map<String, String> memberNames,
  ) {
    final balances = calculateBalances(expenses, memberNames);
    final settlements = <Settlement>[];

    // Separate into debtors (negative balance) and creditors (positive balance).
    final debtors = <MapEntry<String, double>>[]; // people who owe
    final creditors = <MapEntry<String, double>>[]; // people who are owed

    for (final entry in balances.entries) {
      if (entry.value < -0.01) {
        debtors.add(MapEntry(entry.key, -entry.value)); // make positive
      } else if (entry.value > 0.01) {
        creditors.add(MapEntry(entry.key, entry.value));
      }
    }

    // Sort both by amount descending.
    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    int i = 0, j = 0;
    final debtAmounts = debtors.map((e) => e.value).toList();
    final creditAmounts = creditors.map((e) => e.value).toList();

    while (i < debtors.length && j < creditors.length) {
      final transfer = debtAmounts[i] < creditAmounts[j]
          ? debtAmounts[i]
          : creditAmounts[j];

      settlements.add(Settlement(
        fromId: debtors[i].key,
        fromName: memberNames[debtors[i].key] ?? 'Unknown',
        toId: creditors[j].key,
        toName: memberNames[creditors[j].key] ?? 'Unknown',
        amount: double.parse(transfer.toStringAsFixed(2)),
      ));

      debtAmounts[i] -= transfer;
      creditAmounts[j] -= transfer;

      if (debtAmounts[i] < 0.01) i++;
      if (creditAmounts[j] < 0.01) j++;
    }

    return settlements;
  }

  /// Calculate total spent for each member.
  Map<String, double> calculatePerPersonSpending(List<Expense> expenses) {
    final spending = <String, double>{};
    for (final expense in expenses) {
      spending[expense.payerId] =
          (spending[expense.payerId] ?? 0) + expense.amount;
    }
    return spending;
  }

  /// Calculate total of all expenses.
  double calculateTotal(List<Expense> expenses) {
    return expenses.fold(0.0, (totalSum, e) => totalSum + e.amount);
  }
}
