import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';

/// Edit the signed-in user's personal data (name, gender, birth date, weight).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _weight;
  String _gender = 'male';
  DateTime? _birthDate;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _weight = TextEditingController(
      text: user?.bodyWeightKg != null ? '${user!.bodyWeightKg}' : '',
    );
    _gender = user?.gender ?? 'male';
    if (user?.birthDate != null) {
      _birthDate = DateTime.tryParse(user!.birthDate!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = null;
      _saving = true;
    });

    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await auth.updateProfile({
        'name': _name.text.trim(),
        'gender': _gender,
        if (_birthDate != null)
          'birth_date': DateFormat('yyyy-MM-dd').format(_birthDate!),
        if (double.tryParse(_weight.text) != null)
          'body_weight_kg': double.parse(_weight.text),
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
      navigator.pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = l10n.cannotConnect);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfileData)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                      labelText: l10n.name,
                      border: const OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: InputDecoration(
                      labelText: l10n.gender,
                      border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: 'male', child: Text(l10n.genderMale)),
                    DropdownMenuItem(
                        value: 'female', child: Text(l10n.genderFemale)),
                  ],
                  onChanged: (v) => setState(() => _gender = v!),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickBirthDate,
                  icon: const Icon(Icons.cake_outlined),
                  label: Text(_birthDate == null
                      ? l10n.pickBirthDate
                      : DateFormat('d MMM yyyy').format(_birthDate!)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.bodyWeightKg,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
