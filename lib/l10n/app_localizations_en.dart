// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Apex Lifter';

  @override
  String get navHome => 'Home';

  @override
  String get navLeaderboard => 'Leaderboard';

  @override
  String get navProfile => 'Profile';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get remove => 'Remove';

  @override
  String get update => 'Update';

  @override
  String get cannotConnect => 'Could not connect to the server.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get login => 'Log in';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get noAccountRegister => 'Don\'t have an account? Sign up';

  @override
  String get registerTitle => 'Create account';

  @override
  String get name => 'Name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get passwordMin8Label => 'Password (min. 8 characters)';

  @override
  String get passwordMin8 => 'At least 8 characters';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get pickBirthDate => 'Pick birth date';

  @override
  String get birthDateRequired => 'Birth date is required.';

  @override
  String get bodyWeightOptional => 'Body weight (kg) — optional';

  @override
  String get register => 'Sign up';

  @override
  String greeting(String name) {
    return 'Hi, $name 💪';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get addSet => 'Add Set';

  @override
  String get gymCheckin => 'Gym Check-in';

  @override
  String checkedInAt(String gym) {
    return 'You checked in at $gym';
  }

  @override
  String get whoIsHere => 'Who\'s here?';

  @override
  String get notCheckedIn =>
      'Not checked in. Check-in is optional — you can still log sets without it.';

  @override
  String get checkinWithGps => 'Check in with GPS';

  @override
  String get recentSets => 'Recent Sets';

  @override
  String get noSetsYet => 'No sets logged yet. Start lifting! 🏋️';

  @override
  String get machine => 'Machine';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get pure1rm => 'Pure 1RM';

  @override
  String get est1rmMulti => 'Est. 1RM (multi-rep)';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get allGenders => 'All Genders';

  @override
  String get allAges => 'All Ages';

  @override
  String ageFilter(String bracket) {
    return 'Age $bracket';
  }

  @override
  String get allWeights => 'All BW';

  @override
  String weightFilter(String weightClass) {
    return 'BW $weightClass kg';
  }

  @override
  String yourPosition(int rank) {
    return 'Your current position: #$rank';
  }

  @override
  String get selectMachinePrompt => 'Select a machine to view the ranking.';

  @override
  String get searchMachine => 'Search machine';

  @override
  String get noMachinesFound => 'No machines match your search.';

  @override
  String get noOneLogged => 'No one has logged a set in this period yet.';

  @override
  String get broadenSearch => 'Try broadening your search:';

  @override
  String get viewMonthly => 'View Monthly period';

  @override
  String get viewEst1rm => 'View Est. 1RM (multi-rep)';

  @override
  String get viewPure1rm => 'View Pure 1RM';

  @override
  String get clearFilters => 'Clear gender, age & BW filters';

  @override
  String get orPickAnotherMachine => 'or go back and choose another machine';

  @override
  String youSuffix(String name) {
    return '$name (you)';
  }

  @override
  String entrySubtitle(String weight, int reps) {
    return '$weight kg × $reps reps';
  }

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get age => 'Age';

  @override
  String ageValue(int age, String bracket) {
    return '$age yr (bracket $bracket)';
  }

  @override
  String get bodyWeight => 'Body weight';

  @override
  String updatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String weightWithClass(String weight, String weightClass) {
    return '$weight kg (class $weightClass)';
  }

  @override
  String get notSet => 'Not set';

  @override
  String get staleWeightTitle => 'Body weight expired';

  @override
  String get staleWeightBody =>
      'It has been more than 90 days. Weigh in again so your weight-class records stay verified.';

  @override
  String get tapWeightHint =>
      'Tap \"Body weight\" to update. Records follow your latest weight class.';

  @override
  String get viewPublicProfile => 'View my public profile';

  @override
  String get logout => 'Log out';

  @override
  String get avatarUpdated => 'Profile photo updated.';

  @override
  String get photoSourceCamera => 'Take a photo';

  @override
  String get photoSourceGallery => 'Choose from gallery';

  @override
  String get permissionNeededTitle => 'Permission needed';

  @override
  String get permissionNeededBody =>
      'Access was denied. Open Settings to enable it for Apex Lifter.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String avatarUploadFailed(String error) {
    return 'Failed to upload photo: $error';
  }

  @override
  String get updateBodyWeight => 'Update body weight';

  @override
  String get bodyWeightKg => 'Body weight (kg)';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get pushNotificationsSubtitle => 'Receive rank change alerts';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get editProfileData => 'Edit personal data';

  @override
  String get editProfilePhoto => 'Edit profile photo';

  @override
  String get account => 'Account';

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get categoryChest => 'Chest';

  @override
  String get categoryBack => 'Back';

  @override
  String get categoryShoulders => 'Shoulders';

  @override
  String get categoryArms => 'Arms';

  @override
  String get categoryLegs => 'Legs';

  @override
  String get categoryCore => 'Core';

  @override
  String setLogged(String value) {
    return 'Set logged! Estimated 1RM: $value kg';
  }

  @override
  String get chooseMachine => 'Choose machine';

  @override
  String get chooseMachineFirst => 'Choose a machine first';

  @override
  String get load => 'Load (kg)';

  @override
  String get invalidLoad => 'Invalid load';

  @override
  String get reps => 'Reps';

  @override
  String get reps1to100 => 'Reps 1-100';

  @override
  String get repsHint =>
      'Reps = 1 counts toward the pure 1RM leaderboard; reps ≥ 2 count toward the estimated 1RM leaderboard.';

  @override
  String get saveSet => 'Save Set';

  @override
  String get markRead => 'Mark read';

  @override
  String get noNotifications => 'No notifications yet.\nHold your position! 🏆';

  @override
  String get atGym => 'At the Gym';

  @override
  String get noRecentCheckins =>
      'No one has checked in here in the last 3 hours.';

  @override
  String liftersHere(int count) {
    return '$count lifters training here';
  }

  @override
  String get you => '(you)';

  @override
  String checkedInTime(String time) {
    return 'Checked in $time';
  }

  @override
  String progressTitle(String machine) {
    return 'Progress · $machine';
  }

  @override
  String get needTwoDays =>
      'Need at least 2 training days on this machine to\nshow a progress chart. Keep lifting! 🏋️';

  @override
  String get est1rmOverTime => 'Estimated 1RM over time';

  @override
  String deltaSince(String delta, String date) {
    return '$delta kg since $date';
  }

  @override
  String get dailyRecord => 'Daily record';

  @override
  String est1rmValue(String value) {
    return '$value kg est. 1RM';
  }

  @override
  String get sessionHistory => 'Gym Session History';

  @override
  String get statSets => 'Sets';

  @override
  String get statMachines => 'Machines';

  @override
  String get statBest1rm => 'Best 1RM';

  @override
  String get totalVolume => 'Total volume';

  @override
  String get streakTitle => 'Weekly streak';

  @override
  String weekStreakLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
      zero: 'No streak',
    );
    return '$_temp0';
  }

  @override
  String get streakActiveHint => 'One session a week keeps it alive 🔥';

  @override
  String get streakStartHint => 'Train this week to start a streak 🔥';

  @override
  String get noBadges =>
      'No champion badges yet. Badges appear when the weekly leaderboard resets.';

  @override
  String classLabel(String weightClass) {
    return 'class $weightClass';
  }

  @override
  String setCountLabel(int count) {
    return '$count set';
  }

  @override
  String topMachineLabel(String machine, String value) {
    return 'top: $machine ${value}kg';
  }

  @override
  String get machineRecords => 'Machine Records';

  @override
  String get noMachineRecords =>
      'No records yet. Log a set to set a record! 🏋️';

  @override
  String recordLift(String weight, int reps) {
    return '$weight kg × $reps';
  }

  @override
  String recordEst1rm(String value) {
    return '$value kg est. 1RM';
  }

  @override
  String get featured => 'Featured';

  @override
  String get featuredMachines => 'Featured Machines';

  @override
  String get featuredMachinesHint =>
      'Pick up to 3 machines to pin to the top of your public profile, in the order you want them shown.';

  @override
  String get editFeaturedMachines => 'Edit featured machines';

  @override
  String get noFeaturedMachines => 'No featured machines yet';

  @override
  String featuredCount(int count) {
    return '$count of 3 selected';
  }

  @override
  String get addMachine => 'Add machine';

  @override
  String get featuredLimitReached => 'You can feature at most 3 machines.';

  @override
  String get dragToReorder => 'Drag to reorder';

  @override
  String get challenge => 'Challenge';

  @override
  String get challengeArena => 'Challenge Arena';

  @override
  String get challenges => 'Challenges';

  @override
  String get tabArena => 'Arena';

  @override
  String get tabMine => 'Mine';

  @override
  String get tabMedals => 'Medals';

  @override
  String get newChallenge => 'New Challenge';

  @override
  String challengeOpponent(String name) {
    return 'Challenging $name';
  }

  @override
  String get chooseOpponent =>
      'Choose an opponent from the leaderboard or a profile.';

  @override
  String get targetWeightKgLabel => 'Weight (kg)';

  @override
  String get targetRepsLabel => 'Reps';

  @override
  String get targetSetsLabel => 'Sets';

  @override
  String get sendChallenge => 'Send Challenge';

  @override
  String challengeSent(String name) {
    return 'Challenge sent to $name!';
  }

  @override
  String get vs => 'VS';

  @override
  String get statusPending => 'Awaiting proof';

  @override
  String get statusActive => 'Judging in Arena';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusDeclined => 'Declined';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get recordProof => 'Record proof';

  @override
  String get reRecordProof => 'Re-record proof';

  @override
  String get proofSubmitted => 'Proof submitted ✓';

  @override
  String get awaitingOpponentProof => 'Waiting for the other lifter\'s proof.';

  @override
  String get watchChallengerProof => 'Watch challenger\'s proof';

  @override
  String get watchOpponentProof => 'Watch opponent\'s proof';

  @override
  String get declineChallenge => 'Decline';

  @override
  String get judge => 'Judge';

  @override
  String get alreadyJudged => 'You\'ve judged this challenge.';

  @override
  String votingEndsIn(String time) {
    return 'Voting ends $time';
  }

  @override
  String get votingClosed => 'Voting window closed — awaiting result';

  @override
  String winnerLabel(String name) {
    return 'Winner: $name';
  }

  @override
  String get youWon => 'You won this challenge! 🏅';

  @override
  String medalsWithCount(int count) {
    return '$count medals';
  }

  @override
  String get noMedalsYet => 'No medals yet. Win a challenge to earn one!';

  @override
  String get noArenaChallenges => 'No challenges to judge right now.';

  @override
  String get noChallengesYet =>
      'No challenges yet. Challenge someone from the leaderboard!';

  @override
  String get judgementTitle => 'Judge the lift';

  @override
  String get criteriaLoad => 'Load / weight is correct';

  @override
  String get criteriaForm => 'Form is valid';

  @override
  String get criteriaMachine => 'Correct machine used';

  @override
  String get criteriaRepsSets => 'Reps & sets completed';

  @override
  String get whoWon => 'Who performed it validly?';

  @override
  String voteWins(String name) {
    return '$name wins';
  }

  @override
  String get voteInvalid => 'Neither — invalid';

  @override
  String get reasonLabel => 'Reason';

  @override
  String get reasonRequired => 'Please choose a reason.';

  @override
  String get reasonNote => 'Add a note';

  @override
  String get submitJudgement => 'Submit judgement';

  @override
  String get reasonLoadTooLight => 'Load looks lighter than claimed';

  @override
  String get reasonIncompleteReps => 'Reps/sets not completed';

  @override
  String get reasonWrongMachine => 'Wrong machine used';

  @override
  String get reasonBadForm => 'Invalid form / cheating';

  @override
  String get reasonPartialRange => 'Partial range of motion';

  @override
  String get reasonVideoUnclear => 'Video unclear / unconvincing';

  @override
  String get reasonOther => 'Other';

  @override
  String get proofRequired => 'Record a proof video to submit.';

  @override
  String challengeTarget(String weight, int reps, int sets) {
    return '$weight kg × $reps reps × $sets sets';
  }

  @override
  String tallyApproveReject(int approve, int reject) {
    return '$approve approve · $reject reject';
  }

  @override
  String get couldNotOpenVideo => 'Could not open the video.';

  @override
  String get challengeCreatedRecordNow =>
      'Challenge created! Record your proof now?';

  @override
  String get recordNow => 'Record now';

  @override
  String get later => 'Later';

  @override
  String get gymLocations => 'Gym Locations';

  @override
  String get exploreGyms => 'Explore gyms';

  @override
  String get noGymsFound => 'No gyms registered yet.';

  @override
  String get gymLeaderboardEmpty => 'No lifts logged at this gym yet.';

  @override
  String gymEntrySubtitle(String weight, int reps, String machine) {
    return '$weight kg × $reps reps · $machine';
  }

  @override
  String get challengeAction => 'Challenge';

  @override
  String get loginToChallenge => 'Log in to challenge other lifters.';

  @override
  String get onboardingTitle1 => 'Track Every Rep';

  @override
  String get onboardingBody1 =>
      'Log your sets in seconds and watch your estimated 1RM climb — your progress, charted.';

  @override
  String get onboardingTitle2 => 'Rule Your Gym';

  @override
  String get onboardingBody2 =>
      'Check in with GPS, see who\'s training right now, and climb the weekly leaderboard on every machine.';

  @override
  String get onboardingTitle3 => 'Challenge Anyone';

  @override
  String get onboardingBody3 =>
      'Go head-to-head, upload proof videos, and let the arena decide the winner.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';
}
