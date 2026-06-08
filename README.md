# SplitWave

Repository: https://github.com/AhmedH001/SplitWave

SplitWave is a Flutter vacation expense tracker that helps groups manage shared spending, split bills, and keep member names visible so everyone knows who paid and who owes.

Maintained by [AhmedH001](https://github.com/AhmedH001).

## Features

- Firebase Authentication with email link sign-in and Google sign-in.
- User profiles with display names and avatar emoji selection.
- Vacation groups with member lists and shared expense tracking.
- Expense creation, editing, and deletion for the payer.
- Automatic split calculations and balance summaries.
- Admin controls for creating vacations and adding members.
- Member display names are shown throughout vacations and expense details.

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK (included with Flutter)
- Firebase project configured for the app

### Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/AhmedH001/SplitWave.git
   cd SplitWave
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure Firebase:

   - Update `firebase.json`, `android/app/google-services.json`, and iOS config files as needed.
   - Add your Firebase app settings in `lib/firebase_options.dart` if required.

4. Run the app:

   ```bash
   flutter run
   ```

## Usage

- Sign in with email link or Google.
- Set your display name on first login.
- Admins can create vacations and add members.
- Add expenses and choose which members are included in each split.
- View balance summaries and see who paid each expense.

## Development

- Main app code lives in `lib/`.
- Vacation screens are under `lib/screens/`.
- Firestore access is handled in `lib/services/`.
- Models are in `lib/models/`.

## Notes

- Admin access is determined by the `role` field in Firestore user documents.
- Vacation member names are stored in each vacation to keep expense displays consistent.
