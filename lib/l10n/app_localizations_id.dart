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
  String get orPickAnotherMachine =>
      'atau pilih alat lain lewat dropdown di atas';

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
}
