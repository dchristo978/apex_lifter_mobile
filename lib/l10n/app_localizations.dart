import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Apex Lifter'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get navLeaderboard;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @cannotConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server.'**
  String get cannotConnect;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountRegister;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @passwordMin8Label.
  ///
  /// In en, this message translates to:
  /// **'Password (min. 8 characters)'**
  String get passwordMin8Label;

  /// No description provided for @passwordMin8.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordMin8;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @pickBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Pick birth date'**
  String get pickBirthDate;

  /// No description provided for @birthDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Birth date is required.'**
  String get birthDateRequired;

  /// No description provided for @bodyWeightOptional.
  ///
  /// In en, this message translates to:
  /// **'Body weight (kg) — optional'**
  String get bodyWeightOptional;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get register;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 💪'**
  String greeting(String name);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get addSet;

  /// No description provided for @gymCheckin.
  ///
  /// In en, this message translates to:
  /// **'Gym Check-in'**
  String get gymCheckin;

  /// No description provided for @checkedInAt.
  ///
  /// In en, this message translates to:
  /// **'You checked in at {gym}'**
  String checkedInAt(String gym);

  /// No description provided for @whoIsHere.
  ///
  /// In en, this message translates to:
  /// **'Who\'s here?'**
  String get whoIsHere;

  /// No description provided for @notCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Not checked in. Check-in is optional — you can still log sets without it.'**
  String get notCheckedIn;

  /// No description provided for @checkinWithGps.
  ///
  /// In en, this message translates to:
  /// **'Check in with GPS'**
  String get checkinWithGps;

  /// No description provided for @recentSets.
  ///
  /// In en, this message translates to:
  /// **'Recent Sets'**
  String get recentSets;

  /// No description provided for @noSetsYet.
  ///
  /// In en, this message translates to:
  /// **'No sets logged yet. Start lifting! 🏋️'**
  String get noSetsYet;

  /// No description provided for @machine.
  ///
  /// In en, this message translates to:
  /// **'Machine'**
  String get machine;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @pure1rm.
  ///
  /// In en, this message translates to:
  /// **'Pure 1RM'**
  String get pure1rm;

  /// No description provided for @est1rmMulti.
  ///
  /// In en, this message translates to:
  /// **'Est. 1RM (multi-rep)'**
  String get est1rmMulti;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @allGenders.
  ///
  /// In en, this message translates to:
  /// **'All Genders'**
  String get allGenders;

  /// No description provided for @allAges.
  ///
  /// In en, this message translates to:
  /// **'All Ages'**
  String get allAges;

  /// No description provided for @ageFilter.
  ///
  /// In en, this message translates to:
  /// **'Age {bracket}'**
  String ageFilter(String bracket);

  /// No description provided for @allWeights.
  ///
  /// In en, this message translates to:
  /// **'All BW'**
  String get allWeights;

  /// No description provided for @weightFilter.
  ///
  /// In en, this message translates to:
  /// **'BW {weightClass} kg'**
  String weightFilter(String weightClass);

  /// No description provided for @yourPosition.
  ///
  /// In en, this message translates to:
  /// **'Your current position: #{rank}'**
  String yourPosition(int rank);

  /// No description provided for @selectMachinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a machine to view the ranking.'**
  String get selectMachinePrompt;

  /// No description provided for @searchMachine.
  ///
  /// In en, this message translates to:
  /// **'Search machine'**
  String get searchMachine;

  /// No description provided for @noMachinesFound.
  ///
  /// In en, this message translates to:
  /// **'No machines match your search.'**
  String get noMachinesFound;

  /// No description provided for @noOneLogged.
  ///
  /// In en, this message translates to:
  /// **'No one has logged a set in this period yet.'**
  String get noOneLogged;

  /// No description provided for @broadenSearch.
  ///
  /// In en, this message translates to:
  /// **'Try broadening your search:'**
  String get broadenSearch;

  /// No description provided for @viewMonthly.
  ///
  /// In en, this message translates to:
  /// **'View Monthly period'**
  String get viewMonthly;

  /// No description provided for @viewEst1rm.
  ///
  /// In en, this message translates to:
  /// **'View Est. 1RM (multi-rep)'**
  String get viewEst1rm;

  /// No description provided for @viewPure1rm.
  ///
  /// In en, this message translates to:
  /// **'View Pure 1RM'**
  String get viewPure1rm;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear gender, age & BW filters'**
  String get clearFilters;

  /// No description provided for @orPickAnotherMachine.
  ///
  /// In en, this message translates to:
  /// **'or go back and choose another machine'**
  String get orPickAnotherMachine;

  /// No description provided for @youSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youSuffix(String name);

  /// No description provided for @entrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg × {reps} reps'**
  String entrySubtitle(String weight, int reps);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @ageValue.
  ///
  /// In en, this message translates to:
  /// **'{age} yr (bracket {bracket})'**
  String ageValue(int age, String bracket);

  /// No description provided for @bodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Body weight'**
  String get bodyWeight;

  /// No description provided for @updatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedOn(String date);

  /// No description provided for @weightWithClass.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg (class {weightClass})'**
  String weightWithClass(String weight, String weightClass);

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @staleWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Body weight expired'**
  String get staleWeightTitle;

  /// No description provided for @staleWeightBody.
  ///
  /// In en, this message translates to:
  /// **'It has been more than 90 days. Weigh in again so your weight-class records stay verified.'**
  String get staleWeightBody;

  /// No description provided for @tapWeightHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Body weight\" to update. Records follow your latest weight class.'**
  String get tapWeightHint;

  /// No description provided for @viewPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'View my public profile'**
  String get viewPublicProfile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get avatarUpdated;

  /// No description provided for @photoSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get photoSourceCamera;

  /// No description provided for @photoSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoSourceGallery;

  /// No description provided for @permissionNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get permissionNeededTitle;

  /// No description provided for @permissionNeededBody.
  ///
  /// In en, this message translates to:
  /// **'Access was denied. Open Settings to enable it for Apex Lifter.'**
  String get permissionNeededBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @avatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo: {error}'**
  String avatarUploadFailed(String error);

  /// No description provided for @updateBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Update body weight'**
  String get updateBodyWeight;

  /// No description provided for @bodyWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Body weight (kg)'**
  String get bodyWeightKg;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive rank change alerts'**
  String get pushNotificationsSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @editProfileData.
  ///
  /// In en, this message translates to:
  /// **'Edit personal data'**
  String get editProfileData;

  /// No description provided for @editProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Edit profile photo'**
  String get editProfilePhoto;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileUpdated;

  /// No description provided for @categoryChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get categoryChest;

  /// No description provided for @categoryBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get categoryBack;

  /// No description provided for @categoryShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get categoryShoulders;

  /// No description provided for @categoryArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get categoryArms;

  /// No description provided for @categoryLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get categoryLegs;

  /// No description provided for @categoryCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get categoryCore;

  /// No description provided for @setLogged.
  ///
  /// In en, this message translates to:
  /// **'Set logged! Estimated 1RM: {value} kg'**
  String setLogged(String value);

  /// No description provided for @chooseMachine.
  ///
  /// In en, this message translates to:
  /// **'Choose machine'**
  String get chooseMachine;

  /// No description provided for @chooseMachineFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a machine first'**
  String get chooseMachineFirst;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load (kg)'**
  String get load;

  /// No description provided for @invalidLoad.
  ///
  /// In en, this message translates to:
  /// **'Invalid load'**
  String get invalidLoad;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @reps1to100.
  ///
  /// In en, this message translates to:
  /// **'Reps 1-100'**
  String get reps1to100;

  /// No description provided for @repsHint.
  ///
  /// In en, this message translates to:
  /// **'Reps = 1 counts toward the pure 1RM leaderboard; reps ≥ 2 count toward the estimated 1RM leaderboard.'**
  String get repsHint;

  /// No description provided for @saveSet.
  ///
  /// In en, this message translates to:
  /// **'Save Set'**
  String get saveSet;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get markRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.\nHold your position! 🏆'**
  String get noNotifications;

  /// No description provided for @atGym.
  ///
  /// In en, this message translates to:
  /// **'At the Gym'**
  String get atGym;

  /// No description provided for @noRecentCheckins.
  ///
  /// In en, this message translates to:
  /// **'No one has checked in here in the last 3 hours.'**
  String get noRecentCheckins;

  /// No description provided for @liftersHere.
  ///
  /// In en, this message translates to:
  /// **'{count} lifters training here'**
  String liftersHere(int count);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'(you)'**
  String get you;

  /// No description provided for @checkedInTime.
  ///
  /// In en, this message translates to:
  /// **'Checked in {time}'**
  String checkedInTime(String time);

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress · {machine}'**
  String progressTitle(String machine);

  /// No description provided for @needTwoDays.
  ///
  /// In en, this message translates to:
  /// **'Need at least 2 training days on this machine to\nshow a progress chart. Keep lifting! 🏋️'**
  String get needTwoDays;

  /// No description provided for @est1rmOverTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM over time'**
  String get est1rmOverTime;

  /// No description provided for @deltaSince.
  ///
  /// In en, this message translates to:
  /// **'{delta} kg since {date}'**
  String deltaSince(String delta, String date);

  /// No description provided for @dailyRecord.
  ///
  /// In en, this message translates to:
  /// **'Daily record'**
  String get dailyRecord;

  /// No description provided for @est1rmValue.
  ///
  /// In en, this message translates to:
  /// **'{value} kg est. 1RM'**
  String est1rmValue(String value);

  /// No description provided for @sessionHistory.
  ///
  /// In en, this message translates to:
  /// **'Gym Session History'**
  String get sessionHistory;

  /// No description provided for @statSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get statSets;

  /// No description provided for @statMachines.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get statMachines;

  /// No description provided for @statBest1rm.
  ///
  /// In en, this message translates to:
  /// **'Best 1RM'**
  String get statBest1rm;

  /// No description provided for @totalVolume.
  ///
  /// In en, this message translates to:
  /// **'Total volume'**
  String get totalVolume;

  /// No description provided for @streakTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly streak'**
  String get streakTitle;

  /// No description provided for @weekStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No streak} =1{1 week} other{{count} weeks}}'**
  String weekStreakLabel(int count);

  /// No description provided for @streakActiveHint.
  ///
  /// In en, this message translates to:
  /// **'One session a week keeps it alive 🔥'**
  String get streakActiveHint;

  /// No description provided for @streakStartHint.
  ///
  /// In en, this message translates to:
  /// **'Train this week to start a streak 🔥'**
  String get streakStartHint;

  /// No description provided for @noBadges.
  ///
  /// In en, this message translates to:
  /// **'No champion badges yet. Badges appear when the weekly leaderboard resets.'**
  String get noBadges;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'class {weightClass}'**
  String classLabel(String weightClass);

  /// No description provided for @setCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} set'**
  String setCountLabel(int count);

  /// No description provided for @topMachineLabel.
  ///
  /// In en, this message translates to:
  /// **'top: {machine} {value}kg'**
  String topMachineLabel(String machine, String value);

  /// No description provided for @machineRecords.
  ///
  /// In en, this message translates to:
  /// **'Machine Records'**
  String get machineRecords;

  /// No description provided for @noMachineRecords.
  ///
  /// In en, this message translates to:
  /// **'No records yet. Log a set to set a record! 🏋️'**
  String get noMachineRecords;

  /// No description provided for @recordLift.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg × {reps}'**
  String recordLift(String weight, int reps);

  /// No description provided for @recordEst1rm.
  ///
  /// In en, this message translates to:
  /// **'{value} kg est. 1RM'**
  String recordEst1rm(String value);

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @featuredMachines.
  ///
  /// In en, this message translates to:
  /// **'Featured Machines'**
  String get featuredMachines;

  /// No description provided for @featuredMachinesHint.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 3 machines to pin to the top of your public profile, in the order you want them shown.'**
  String get featuredMachinesHint;

  /// No description provided for @editFeaturedMachines.
  ///
  /// In en, this message translates to:
  /// **'Edit featured machines'**
  String get editFeaturedMachines;

  /// No description provided for @noFeaturedMachines.
  ///
  /// In en, this message translates to:
  /// **'No featured machines yet'**
  String get noFeaturedMachines;

  /// No description provided for @featuredCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of 3 selected'**
  String featuredCount(int count);

  /// No description provided for @addMachine.
  ///
  /// In en, this message translates to:
  /// **'Add machine'**
  String get addMachine;

  /// No description provided for @featuredLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can feature at most 3 machines.'**
  String get featuredLimitReached;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get dragToReorder;

  /// No description provided for @challenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challenge;

  /// No description provided for @challengeArena.
  ///
  /// In en, this message translates to:
  /// **'Challenge Arena'**
  String get challengeArena;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @tabArena.
  ///
  /// In en, this message translates to:
  /// **'Arena'**
  String get tabArena;

  /// No description provided for @tabMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get tabMine;

  /// No description provided for @tabMedals.
  ///
  /// In en, this message translates to:
  /// **'Medals'**
  String get tabMedals;

  /// No description provided for @newChallenge.
  ///
  /// In en, this message translates to:
  /// **'New Challenge'**
  String get newChallenge;

  /// No description provided for @challengeOpponent.
  ///
  /// In en, this message translates to:
  /// **'Challenging {name}'**
  String challengeOpponent(String name);

  /// No description provided for @chooseOpponent.
  ///
  /// In en, this message translates to:
  /// **'Choose an opponent from the leaderboard or a profile.'**
  String get chooseOpponent;

  /// No description provided for @targetWeightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get targetWeightKgLabel;

  /// No description provided for @targetRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get targetRepsLabel;

  /// No description provided for @targetSetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get targetSetsLabel;

  /// No description provided for @sendChallenge.
  ///
  /// In en, this message translates to:
  /// **'Send Challenge'**
  String get sendChallenge;

  /// No description provided for @challengeSent.
  ///
  /// In en, this message translates to:
  /// **'Challenge sent to {name}!'**
  String challengeSent(String name);

  /// No description provided for @vs.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vs;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting proof'**
  String get statusPending;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Judging in Arena'**
  String get statusActive;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @recordProof.
  ///
  /// In en, this message translates to:
  /// **'Record proof'**
  String get recordProof;

  /// No description provided for @reRecordProof.
  ///
  /// In en, this message translates to:
  /// **'Re-record proof'**
  String get reRecordProof;

  /// No description provided for @proofSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Proof submitted ✓'**
  String get proofSubmitted;

  /// No description provided for @awaitingOpponentProof.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other lifter\'s proof.'**
  String get awaitingOpponentProof;

  /// No description provided for @watchChallengerProof.
  ///
  /// In en, this message translates to:
  /// **'Watch challenger\'s proof'**
  String get watchChallengerProof;

  /// No description provided for @watchOpponentProof.
  ///
  /// In en, this message translates to:
  /// **'Watch opponent\'s proof'**
  String get watchOpponentProof;

  /// No description provided for @declineChallenge.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineChallenge;

  /// No description provided for @judge.
  ///
  /// In en, this message translates to:
  /// **'Judge'**
  String get judge;

  /// No description provided for @alreadyJudged.
  ///
  /// In en, this message translates to:
  /// **'You\'ve judged this challenge.'**
  String get alreadyJudged;

  /// No description provided for @votingEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Voting ends {time}'**
  String votingEndsIn(String time);

  /// No description provided for @votingClosed.
  ///
  /// In en, this message translates to:
  /// **'Voting window closed — awaiting result'**
  String get votingClosed;

  /// No description provided for @winnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Winner: {name}'**
  String winnerLabel(String name);

  /// No description provided for @youWon.
  ///
  /// In en, this message translates to:
  /// **'You won this challenge! 🏅'**
  String get youWon;

  /// No description provided for @medalsWithCount.
  ///
  /// In en, this message translates to:
  /// **'{count} medals'**
  String medalsWithCount(int count);

  /// No description provided for @noMedalsYet.
  ///
  /// In en, this message translates to:
  /// **'No medals yet. Win a challenge to earn one!'**
  String get noMedalsYet;

  /// No description provided for @noArenaChallenges.
  ///
  /// In en, this message translates to:
  /// **'No challenges to judge right now.'**
  String get noArenaChallenges;

  /// No description provided for @noChallengesYet.
  ///
  /// In en, this message translates to:
  /// **'No challenges yet. Challenge someone from the leaderboard!'**
  String get noChallengesYet;

  /// No description provided for @judgementTitle.
  ///
  /// In en, this message translates to:
  /// **'Judge the lift'**
  String get judgementTitle;

  /// No description provided for @criteriaLoad.
  ///
  /// In en, this message translates to:
  /// **'Load / weight is correct'**
  String get criteriaLoad;

  /// No description provided for @criteriaForm.
  ///
  /// In en, this message translates to:
  /// **'Form is valid'**
  String get criteriaForm;

  /// No description provided for @criteriaMachine.
  ///
  /// In en, this message translates to:
  /// **'Correct machine used'**
  String get criteriaMachine;

  /// No description provided for @criteriaRepsSets.
  ///
  /// In en, this message translates to:
  /// **'Reps & sets completed'**
  String get criteriaRepsSets;

  /// No description provided for @whoWon.
  ///
  /// In en, this message translates to:
  /// **'Who performed it validly?'**
  String get whoWon;

  /// No description provided for @voteWins.
  ///
  /// In en, this message translates to:
  /// **'{name} wins'**
  String voteWins(String name);

  /// No description provided for @voteInvalid.
  ///
  /// In en, this message translates to:
  /// **'Neither — invalid'**
  String get voteInvalid;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please choose a reason.'**
  String get reasonRequired;

  /// No description provided for @reasonNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get reasonNote;

  /// No description provided for @submitJudgement.
  ///
  /// In en, this message translates to:
  /// **'Submit judgement'**
  String get submitJudgement;

  /// No description provided for @reasonLoadTooLight.
  ///
  /// In en, this message translates to:
  /// **'Load looks lighter than claimed'**
  String get reasonLoadTooLight;

  /// No description provided for @reasonIncompleteReps.
  ///
  /// In en, this message translates to:
  /// **'Reps/sets not completed'**
  String get reasonIncompleteReps;

  /// No description provided for @reasonWrongMachine.
  ///
  /// In en, this message translates to:
  /// **'Wrong machine used'**
  String get reasonWrongMachine;

  /// No description provided for @reasonBadForm.
  ///
  /// In en, this message translates to:
  /// **'Invalid form / cheating'**
  String get reasonBadForm;

  /// No description provided for @reasonPartialRange.
  ///
  /// In en, this message translates to:
  /// **'Partial range of motion'**
  String get reasonPartialRange;

  /// No description provided for @reasonVideoUnclear.
  ///
  /// In en, this message translates to:
  /// **'Video unclear / unconvincing'**
  String get reasonVideoUnclear;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @proofRequired.
  ///
  /// In en, this message translates to:
  /// **'Record a proof video to submit.'**
  String get proofRequired;

  /// No description provided for @challengeTarget.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg × {reps} reps × {sets} sets'**
  String challengeTarget(String weight, int reps, int sets);

  /// No description provided for @tallyApproveReject.
  ///
  /// In en, this message translates to:
  /// **'{approve} approve · {reject} reject'**
  String tallyApproveReject(int approve, int reject);

  /// No description provided for @couldNotOpenVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not open the video.'**
  String get couldNotOpenVideo;

  /// No description provided for @challengeCreatedRecordNow.
  ///
  /// In en, this message translates to:
  /// **'Challenge created! Record your proof now?'**
  String get challengeCreatedRecordNow;

  /// No description provided for @recordNow.
  ///
  /// In en, this message translates to:
  /// **'Record now'**
  String get recordNow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
