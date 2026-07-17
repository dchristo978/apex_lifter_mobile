// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Apex Lifter';

  @override
  String get navHome => 'Beranda';

  @override
  String get navLeaderboard => 'Peringkat';

  @override
  String get navProfile => 'Profil';

  @override
  String get cancel => 'Batal';

  @override
  String get save => 'Simpan';

  @override
  String get remove => 'Hapus';

  @override
  String get update => 'Perbarui';

  @override
  String get cannotConnect => 'Tidak bisa terhubung ke server.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get invalidEmail => 'Email tidak valid';

  @override
  String get passwordRequired => 'Password wajib diisi';

  @override
  String get login => 'Masuk';

  @override
  String get rememberMe => 'Ingat saya';

  @override
  String get noAccountRegister => 'Belum punya akun? Daftar';

  @override
  String get registerTitle => 'Daftar Akun';

  @override
  String get name => 'Nama';

  @override
  String get nameRequired => 'Nama wajib diisi';

  @override
  String get passwordMin8Label => 'Password (min. 8 karakter)';

  @override
  String get passwordMin8 => 'Minimal 8 karakter';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Pria';

  @override
  String get genderFemale => 'Wanita';

  @override
  String get pickBirthDate => 'Pilih tanggal lahir';

  @override
  String get birthDateRequired => 'Tanggal lahir wajib diisi.';

  @override
  String get bodyWeightOptional => 'Berat badan (kg) — opsional';

  @override
  String get register => 'Daftar';

  @override
  String greeting(String name) {
    return 'Halo, $name 💪';
  }

  @override
  String get notifications => 'Notifikasi';

  @override
  String get addSet => 'Tambah Set';

  @override
  String get gymCheckin => 'Check-in Gym';

  @override
  String checkedInAt(String gym) {
    return 'Kamu check-in di $gym';
  }

  @override
  String get whoIsHere => 'Siapa yang di sini?';

  @override
  String get notCheckedIn =>
      'Belum check-in. Check-in bersifat opsional — kamu tetap bisa mencatat set tanpa check-in.';

  @override
  String get checkinWithGps => 'Check-in dengan GPS';

  @override
  String get recentSets => 'Riwayat Set Terakhir';

  @override
  String get noSetsYet => 'Belum ada set tercatat. Mulai angkat! 🏋️';

  @override
  String get machine => 'Alat';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get pure1rm => '1RM Murni';

  @override
  String get est1rmMulti => 'Est. 1RM (multi-rep)';

  @override
  String get weekly => 'Mingguan';

  @override
  String get monthly => 'Bulanan';

  @override
  String get allGenders => 'Semua Gender';

  @override
  String get allAges => 'Semua Umur';

  @override
  String ageFilter(String bracket) {
    return 'Umur $bracket';
  }

  @override
  String get allWeights => 'Semua BB';

  @override
  String weightFilter(String weightClass) {
    return 'BB $weightClass kg';
  }

  @override
  String yourPosition(int rank) {
    return 'Posisimu saat ini: #$rank';
  }

  @override
  String get selectMachinePrompt => 'Pilih alat untuk melihat peringkat.';

  @override
  String get searchMachine => 'Cari alat';

  @override
  String get searchMachineByNameHint => 'Cari berdasarkan nama';

  @override
  String get allMuscleGroups => 'Semua';

  @override
  String get noMachinesFound => 'Tidak ada alat yang cocok dengan pencarian.';

  @override
  String get noOneLogged => 'Belum ada yang mencatat set di periode ini.';

  @override
  String get broadenSearch => 'Coba perluas pencarianmu:';

  @override
  String get viewMonthly => 'Lihat periode Bulanan';

  @override
  String get viewEst1rm => 'Lihat Est. 1RM (multi-rep)';

  @override
  String get viewPure1rm => 'Lihat 1RM Murni';

  @override
  String get clearFilters => 'Hapus filter gender, umur & BB';

  @override
  String get orPickAnotherMachine => 'atau kembali dan pilih alat lain';

  @override
  String youSuffix(String name) {
    return '$name (kamu)';
  }

  @override
  String entrySubtitle(String weight, int reps) {
    return '$weight kg × $reps reps';
  }

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Pengaturan';

  @override
  String get age => 'Umur';

  @override
  String ageValue(int age, String bracket) {
    return '$age th (bracket $bracket)';
  }

  @override
  String get bodyWeight => 'Berat badan';

  @override
  String updatedOn(String date) {
    return 'Diperbarui $date';
  }

  @override
  String weightWithClass(String weight, String weightClass) {
    return '$weight kg (kelas $weightClass)';
  }

  @override
  String get notSet => 'Belum diisi';

  @override
  String get staleWeightTitle => 'Berat badan kedaluwarsa';

  @override
  String get staleWeightBody =>
      'Sudah lebih dari 90 hari. Timbang ulang agar rekor kelas berat badanmu tetap terverifikasi.';

  @override
  String get tapWeightHint =>
      'Ketuk \"Berat badan\" untuk memperbarui. Rekor akan mengikuti kelas berat badan terbaru.';

  @override
  String get viewPublicProfile => 'Lihat profil publikku';

  @override
  String get logout => 'Keluar';

  @override
  String get avatarUpdated => 'Foto profil diperbarui.';

  @override
  String get photoSourceCamera => 'Ambil foto';

  @override
  String get photoSourceGallery => 'Pilih dari galeri';

  @override
  String get permissionNeededTitle => 'Izin diperlukan';

  @override
  String get permissionNeededBody =>
      'Akses ditolak. Buka Pengaturan untuk mengaktifkannya bagi Apex Lifter.';

  @override
  String get openSettings => 'Buka Pengaturan';

  @override
  String avatarUploadFailed(String error) {
    return 'Gagal mengunggah foto: $error';
  }

  @override
  String get updateBodyWeight => 'Perbarui berat badan';

  @override
  String get bodyWeightKg => 'Berat badan (kg)';

  @override
  String get pushNotifications => 'Notifikasi push';

  @override
  String get pushNotificationsSubtitle =>
      'Terima peringatan perubahan peringkat';

  @override
  String get language => 'Bahasa';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get chooseLanguage => 'Pilih bahasa';

  @override
  String get editProfileData => 'Edit data diri';

  @override
  String get editProfilePhoto => 'Edit foto profil';

  @override
  String get account => 'Akun';

  @override
  String get profileUpdated => 'Profil diperbarui.';

  @override
  String get categoryChest => 'Dada';

  @override
  String get categoryBack => 'Punggung';

  @override
  String get categoryShoulders => 'Bahu';

  @override
  String get categoryArms => 'Lengan';

  @override
  String get categoryLegs => 'Kaki';

  @override
  String get categoryCore => 'Core';

  @override
  String setLogged(String value) {
    return 'Set tercatat! Estimated 1RM: $value kg';
  }

  @override
  String get chooseMachine => 'Pilih alat';

  @override
  String get chooseMachineFirst => 'Pilih alat dulu';

  @override
  String get load => 'Beban (kg)';

  @override
  String get invalidLoad => 'Beban tidak valid';

  @override
  String get reps => 'Repetisi';

  @override
  String get reps1to100 => 'Reps 1-100';

  @override
  String get repsHint =>
      'Reps = 1 masuk leaderboard 1RM murni; reps ≥ 2 masuk leaderboard estimated 1RM.';

  @override
  String get saveSet => 'Simpan Set';

  @override
  String get markRead => 'Tandai dibaca';

  @override
  String get noNotifications =>
      'Belum ada notifikasi.\nTetap jaga posisimu! 🏆';

  @override
  String get atGym => 'Sedang di Gym';

  @override
  String get noRecentCheckins =>
      'Belum ada yang check-in di sini dalam 3 jam terakhir.';

  @override
  String liftersHere(int count) {
    return '$count lifter sedang latihan di sini';
  }

  @override
  String get you => '(kamu)';

  @override
  String checkedInTime(String time) {
    return 'Check-in $time';
  }

  @override
  String progressTitle(String machine) {
    return 'Progres · $machine';
  }

  @override
  String get needTwoDays =>
      'Butuh minimal 2 hari latihan di alat ini untuk\nmenampilkan grafik progres. Terus angkat! 🏋️';

  @override
  String get est1rmOverTime => 'Estimasi 1RM dari waktu ke waktu';

  @override
  String deltaSince(String delta, String date) {
    return '$delta kg sejak $date';
  }

  @override
  String get dailyRecord => 'Rekor per hari';

  @override
  String est1rmValue(String value) {
    return '$value kg est. 1RM';
  }

  @override
  String get sessionHistory => 'Riwayat Sesi Gym';

  @override
  String get statSets => 'Set';

  @override
  String get statMachines => 'Alat';

  @override
  String get statBest1rm => 'Best 1RM';

  @override
  String get totalVolume => 'Total volume';

  @override
  String get streakTitle => 'Streak mingguan';

  @override
  String weekStreakLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minggu',
      one: '1 minggu',
      zero: 'Belum ada streak',
    );
    return '$_temp0';
  }

  @override
  String get streakActiveHint => 'Satu sesi seminggu untuk menjaganya 🔥';

  @override
  String get streakStartHint => 'Latihan minggu ini untuk memulai streak 🔥';

  @override
  String get noBadges =>
      'Belum ada badge juara. Badge muncul saat leaderboard mingguan direset.';

  @override
  String classLabel(String weightClass) {
    return 'kelas $weightClass';
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
  String get machineRecords => 'Rekor Alat';

  @override
  String get noMachineRecords =>
      'Belum ada rekor. Catat set untuk membuat rekor! 🏋️';

  @override
  String recordLift(String weight, int reps) {
    return '$weight kg × $reps';
  }

  @override
  String recordEst1rm(String value) {
    return '$value kg est. 1RM';
  }

  @override
  String get featured => 'Unggulan';

  @override
  String get featuredMachines => 'Alat Unggulan';

  @override
  String get featuredMachinesHint =>
      'Pilih maksimal 3 alat untuk disematkan di bagian atas profil publikmu, sesuai urutan yang kamu inginkan.';

  @override
  String get editFeaturedMachines => 'Atur alat unggulan';

  @override
  String get noFeaturedMachines => 'Belum ada alat unggulan';

  @override
  String featuredCount(int count) {
    return '$count dari 3 dipilih';
  }

  @override
  String get addMachine => 'Tambah alat';

  @override
  String get featuredLimitReached =>
      'Kamu hanya bisa menyematkan maksimal 3 alat.';

  @override
  String get dragToReorder => 'Seret untuk mengubah urutan';

  @override
  String get challenge => 'Tantang';

  @override
  String get challengeArena => 'Arena Challenge';

  @override
  String get challenges => 'Challenge';

  @override
  String get tabArena => 'Arena';

  @override
  String get tabMine => 'Milikku';

  @override
  String get tabMedals => 'Medali';

  @override
  String get newChallenge => 'Challenge Baru';

  @override
  String challengeOpponent(String name) {
    return 'Menantang $name';
  }

  @override
  String get chooseOpponent => 'Pilih lawan dari papan peringkat atau profil.';

  @override
  String get targetWeightKgLabel => 'Beban (kg)';

  @override
  String get targetRepsLabel => 'Repetisi';

  @override
  String get targetSetsLabel => 'Set';

  @override
  String get sendChallenge => 'Kirim Challenge';

  @override
  String challengeSent(String name) {
    return 'Challenge dikirim ke $name!';
  }

  @override
  String get vs => 'VS';

  @override
  String get statusPending => 'Menunggu bukti';

  @override
  String get statusActive => 'Dinilai di Arena';

  @override
  String get statusCompleted => 'Selesai';

  @override
  String get statusDeclined => 'Ditolak';

  @override
  String get statusCancelled => 'Dibatalkan';

  @override
  String get recordProof => 'Rekam bukti';

  @override
  String get reRecordProof => 'Rekam ulang bukti';

  @override
  String get proofSubmitted => 'Bukti terkirim ✓';

  @override
  String get awaitingOpponentProof => 'Menunggu bukti dari lawan.';

  @override
  String get watchChallengerProof => 'Lihat bukti penantang';

  @override
  String get watchOpponentProof => 'Lihat bukti lawan';

  @override
  String get declineChallenge => 'Tolak';

  @override
  String get judge => 'Nilai';

  @override
  String get alreadyJudged => 'Kamu sudah menilai challenge ini.';

  @override
  String votingEndsIn(String time) {
    return 'Voting berakhir $time';
  }

  @override
  String get votingClosed => 'Jendela voting ditutup — menunggu hasil';

  @override
  String winnerLabel(String name) {
    return 'Pemenang: $name';
  }

  @override
  String get youWon => 'Kamu memenangkan challenge ini! 🏅';

  @override
  String medalsWithCount(int count) {
    return '$count medali';
  }

  @override
  String get noMedalsYet =>
      'Belum ada medali. Menangkan challenge untuk mendapatkannya!';

  @override
  String get medalCase => 'Koleksi Medali';

  @override
  String get viewMedalCase => 'Lihat koleksi medali';

  @override
  String medalDefeated(String name) {
    return 'Mengalahkan $name';
  }

  @override
  String medalWonOn(String date) {
    return 'Menang $date';
  }

  @override
  String get medalStoryTitle => 'Ceritanya';

  @override
  String get addMedalStory => 'Tulis cerita';

  @override
  String get editMedalStory => 'Ubah cerita';

  @override
  String get medalStoryHint =>
      'Cerita di balik kemenangan ini — maksimal 100 kata';

  @override
  String wordsOf100(int count) {
    return '$count/100 kata';
  }

  @override
  String get storyTooLong => 'Maksimal 100 kata';

  @override
  String get noArenaChallenges => 'Belum ada challenge untuk dinilai saat ini.';

  @override
  String get noChallengesYet =>
      'Belum ada challenge. Tantang seseorang dari papan peringkat!';

  @override
  String get judgementTitle => 'Nilai angkatan';

  @override
  String get criteriaLoad => 'Beban / berat sesuai';

  @override
  String get criteriaForm => 'Form sah';

  @override
  String get criteriaMachine => 'Alat yang dipakai benar';

  @override
  String get criteriaRepsSets => 'Repetisi & set terpenuhi';

  @override
  String get whoWon => 'Siapa yang melakukannya dengan sah?';

  @override
  String voteWins(String name) {
    return '$name menang';
  }

  @override
  String get voteInvalid => 'Tidak keduanya — tidak sah';

  @override
  String get reasonLabel => 'Alasan';

  @override
  String get reasonRequired => 'Silakan pilih alasan.';

  @override
  String get reasonNote => 'Tambahkan catatan';

  @override
  String get submitJudgement => 'Kirim penilaian';

  @override
  String get reasonLoadTooLight => 'Beban terlihat lebih ringan dari klaim';

  @override
  String get reasonIncompleteReps => 'Repetisi/set tidak terpenuhi';

  @override
  String get reasonWrongMachine => 'Alat yang digunakan salah';

  @override
  String get reasonBadForm => 'Form tidak sah / curang';

  @override
  String get reasonPartialRange => 'Rentang gerak tidak penuh';

  @override
  String get reasonVideoUnclear => 'Video tidak jelas / tidak meyakinkan';

  @override
  String get reasonOther => 'Lainnya';

  @override
  String get proofRequired => 'Rekam video bukti untuk mengirim.';

  @override
  String challengeTarget(String weight, int reps, int sets) {
    return '$weight kg × $reps rep × $sets set';
  }

  @override
  String tallyApproveReject(int approve, int reject) {
    return '$approve setuju · $reject tolak';
  }

  @override
  String get couldNotOpenVideo => 'Tidak dapat membuka video.';

  @override
  String get challengeCreatedRecordNow =>
      'Challenge dibuat! Rekam buktimu sekarang?';

  @override
  String get recordNow => 'Rekam sekarang';

  @override
  String get later => 'Nanti';

  @override
  String get gymLocations => 'Lokasi Gym';

  @override
  String get exploreGyms => 'Jelajahi gym';

  @override
  String get noGymsFound => 'Belum ada gym terdaftar.';

  @override
  String get gymLeaderboardEmpty => 'Belum ada angkatan tercatat di gym ini.';

  @override
  String gymEntrySubtitle(String weight, int reps, String machine) {
    return '$weight kg × $reps reps · $machine';
  }

  @override
  String get challengeAction => 'Tantang';

  @override
  String get loginToChallenge => 'Masuk untuk menantang lifter lain.';

  @override
  String get onboardingTitle1 => 'Catat Setiap Repetisi';

  @override
  String get onboardingBody1 =>
      'Catat set-mu dalam hitungan detik dan lihat estimasi 1RM-mu terus naik — progresmu tercatat dalam grafik.';

  @override
  String get onboardingTitle2 => 'Kuasai Gym-mu';

  @override
  String get onboardingBody2 =>
      'Check-in dengan GPS, lihat siapa yang sedang latihan, dan panjat papan peringkat mingguan di setiap mesin.';

  @override
  String get onboardingTitle3 => 'Tantang Siapa Saja';

  @override
  String get onboardingBody3 =>
      'Duel satu lawan satu, unggah video bukti, dan biarkan arena menentukan pemenangnya.';

  @override
  String get skip => 'Lewati';

  @override
  String get next => 'Lanjut';

  @override
  String get getStarted => 'Mulai Sekarang';

  @override
  String get forgotPassword => 'Lupa password?';

  @override
  String get forgotPasswordTitle => 'Atur ulang password';

  @override
  String get forgotPasswordIntro =>
      'Masukkan email akun Anda dan kami akan mengirimkan kode reset.';

  @override
  String get sendResetCode => 'Kirim kode reset';

  @override
  String get resetCodeSent =>
      'Jika email tersebut terdaftar, kode reset sedang dikirim. Masukkan kode di bawah beserta password baru Anda.';

  @override
  String get resetCode => 'Kode reset';

  @override
  String get resetCodeRequired => 'Masukkan kode dari email';

  @override
  String get newPassword => 'Password baru';

  @override
  String get resetPassword => 'Atur ulang password';

  @override
  String get resetPasswordDone => 'Password diperbarui. Anda sudah masuk.';

  @override
  String get deleteAccount => 'Hapus akun';

  @override
  String get deleteAccountTitle => 'Hapus akun?';

  @override
  String get deleteAccountWarning =>
      'Ini menghapus permanen akun, riwayat latihan, check-in, tantangan, dan medali Anda. Tindakan ini tidak bisa dibatalkan.';

  @override
  String get deleteAccountPasswordPrompt =>
      'Masukkan password Anda untuk konfirmasi.';

  @override
  String get deleteAccountConfirm => 'Hapus permanen';

  @override
  String get dangerZone => 'Zona berbahaya';

  @override
  String get deleteSet => 'Hapus set';

  @override
  String get deleteSetTitle => 'Hapus set ini?';

  @override
  String get deleteSetWarning =>
      'Ini menghapus set dari riwayat dan papan peringkatmu. Tindakan ini tidak bisa dibatalkan.';

  @override
  String get deleteSetConfirm => 'Hapus';

  @override
  String get deleteSetSuccess => 'Set dihapus.';

  @override
  String get navFeed => 'Beranda';

  @override
  String get feedTitle => 'Beranda';

  @override
  String get feedEmpty =>
      'Berandamu masih sepi. Ikuti lifter lain untuk melihat PR, medali, dan check-in mereka di sini.';

  @override
  String get feedEmptyAction => 'Cari lifter di papan peringkat';

  @override
  String get follow => 'Ikuti';

  @override
  String get following => 'Mengikuti';

  @override
  String get unfollow => 'Berhenti ikuti';

  @override
  String get followers => 'Pengikut';

  @override
  String followersCount(int count) {
    return '$count pengikut';
  }

  @override
  String followingCount(int count) {
    return '$count diikuti';
  }

  @override
  String get noFollowers => 'Belum ada pengikut.';

  @override
  String get noFollowing => 'Belum mengikuti siapa pun.';

  @override
  String feedPr(String machine, String weight, int reps) {
    return 'mencetak PR baru di $machine: $weight kg × $reps';
  }

  @override
  String feedPrNoMachine(String weight, int reps) {
    return 'mencetak PR baru: $weight kg × $reps';
  }

  @override
  String feedMedal(String machine) {
    return 'memenangkan medali di $machine';
  }

  @override
  String feedMedalVs(String machine, String name) {
    return 'memenangkan medali di $machine, mengalahkan $name';
  }

  @override
  String feedCheckin(String gym) {
    return 'check-in di $gym';
  }

  @override
  String get kudos => 'Kudos';

  @override
  String get comments => 'Komentar';

  @override
  String get commentsTitle => 'Komentar';

  @override
  String get noComments =>
      'Belum ada komentar. Jadilah yang pertama menyemangati.';

  @override
  String get addCommentHint => 'Tulis komentar…';

  @override
  String get send => 'Kirim';

  @override
  String get deleteComment => 'Hapus komentar';

  @override
  String get suggestedLifters => 'Lifter yang disarankan';

  @override
  String get suggestionReasonGym => 'Latihan di gym-mu';

  @override
  String get suggestionReasonPopular => 'Lifter populer';

  @override
  String suggestionFollowers(int count) {
    return '$count pengikut';
  }

  @override
  String get muscleModelTitle => 'Peta otot';

  @override
  String get muscleModelSubtitle =>
      'Otot yang kamu latih dalam 7 hari terakhir.';

  @override
  String muscleModelTrainedCount(int count) {
    return '$count kelompok otot dilatih minggu ini';
  }

  @override
  String get viewIn3d => 'Lihat dalam 3D';

  @override
  String get frontView => 'DEPAN';

  @override
  String get backView => 'BELAKANG';

  @override
  String get swipeToRotate => 'Geser untuk memutar';

  @override
  String get noMuscleTrained =>
      'Belum ada otot yang dilatih dalam 7 hari terakhir. Waktunya ke gym!';

  @override
  String get trainedThisWeek => 'Dilatih minggu ini';

  @override
  String get insightsTitle => 'Wawasan';

  @override
  String get insightsSubtitle =>
      'Frekuensi, keseimbangan otot & standar kekuatan';

  @override
  String get trainingFrequency => 'Frekuensi latihan';

  @override
  String heatmapSummary(int total, int days) {
    return '$total set dalam $days hari aktif setahun terakhir';
  }

  @override
  String get less => 'Sedikit';

  @override
  String get more => 'Banyak';

  @override
  String get muscleBalance => 'Keseimbangan otot';

  @override
  String muscleBalanceCaption(int days) {
    return 'Set per kelompok otot dalam $days hari terakhir';
  }

  @override
  String neglectedMuscles(String groups, int days) {
    return 'Kamu melewatkan $groups dalam $days hari terakhir 😏';
  }

  @override
  String get strengthStandards => 'Standar kekuatan';

  @override
  String get standardsNeedProfile =>
      'Atur berat badan dan jenis kelamin di profilmu untuk melihat perbandingan angkatanmu.';

  @override
  String get standardsNoLifts =>
      'Catat Bench Press, Squat, Deadlift, atau Overhead Press (barbell) untuk melihat standarmu.';

  @override
  String standardsBest(String kg, String ratio) {
    return '1RM terbaik $kg kg · $ratio× berat badan';
  }

  @override
  String standardsNext(String level, String kg) {
    return 'Berikutnya: $level di $kg kg';
  }

  @override
  String get levelUntrained => 'Belum terlatih';

  @override
  String get levelBeginner => 'Pemula';

  @override
  String get levelNovice => 'Dasar';

  @override
  String get levelIntermediate => 'Menengah';

  @override
  String get levelAdvanced => 'Mahir';

  @override
  String get levelElite => 'Elit';
}
