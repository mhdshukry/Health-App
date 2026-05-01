import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config.dart';
import '../../models/entities.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/widgets.dart';
import '../../state/wellness_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _notificationsKey = 'settings_notifications_enabled';
  static const _abnormalAlertsKey = 'settings_abnormal_alerts_enabled';
  static const _weeklySummaryKey = 'settings_weekly_summary_enabled';
  static const _weightUnitKey = 'settings_weight_unit';
  static const _heightUnitKey = 'settings_height_unit';
  static const _temperatureUnitKey = 'settings_temperature_unit';
  static const _stepGoalKey = 'settings_step_goal';
  static const _waterGoalKey = 'settings_water_goal';
  static const _sleepGoalKey = 'settings_sleep_goal';
  static const _analyticsKey = 'settings_analytics_enabled';
  static const _shareWithProviderKey = 'settings_share_provider_enabled';

  bool _notifications = true;
  bool _abnormalAlerts = true;
  bool _weeklySummary = true;
  bool _analytics = false;
  bool _shareWithProvider = false;
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  String _temperatureUnit = 'C';
  final _stepGoal = TextEditingController(text: '8000');
  final _waterGoal = TextEditingController(text: '2000');
  final _sleepGoal = TextEditingController(text: '8');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _stepGoal.dispose();
    _waterGoal.dispose();
    _sleepGoal.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifications = prefs.getBool(_notificationsKey) ?? true;
      _abnormalAlerts = prefs.getBool(_abnormalAlertsKey) ?? true;
      _weeklySummary = prefs.getBool(_weeklySummaryKey) ?? true;
      _analytics = prefs.getBool(_analyticsKey) ?? false;
      _shareWithProvider = prefs.getBool(_shareWithProviderKey) ?? false;
      _weightUnit = prefs.getString(_weightUnitKey) ?? 'kg';
      _heightUnit = prefs.getString(_heightUnitKey) ?? 'cm';
      _temperatureUnit = prefs.getString(_temperatureUnitKey) ?? 'C';
      _stepGoal.text = prefs.getInt(_stepGoalKey)?.toString() ?? '8000';
      _waterGoal.text = prefs.getInt(_waterGoalKey)?.toString() ?? '2000';
      _sleepGoal.text = (prefs.getDouble(_sleepGoalKey) ?? 8).toString();
      _loading = false;
    });
  }

  Future<void> _setBool(
      String key, bool value, ValueChanged<bool> update) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (mounted) setState(() => update(value));
  }

  Future<void> _saveTargets() async {
    final steps = int.tryParse(_stepGoal.text.trim());
    final water = int.tryParse(_waterGoal.text.trim());
    final sleep = double.tryParse(_sleepGoal.text.trim());
    if (steps == null || water == null || sleep == null) {
      _showMessage('Please enter valid target values.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepGoalKey, steps);
    await prefs.setInt(_waterGoalKey, water);
    await prefs.setDouble(_sleepGoalKey, sleep);
    _showMessage('Targets saved.');
  }

  Future<void> _showUnitsSheet() async {
    var weightUnit = _weightUnit;
    var heightUnit = _heightUnit;
    var temperatureUnit = _temperatureUnit;

    await showAppModal<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Units', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _DropdownSetting(
                  label: 'Weight',
                  value: weightUnit,
                  values: const ['kg', 'lb'],
                  onChanged: (value) => setModalState(() => weightUnit = value),
                ),
                const SizedBox(height: 12),
                _DropdownSetting(
                  label: 'Height',
                  value: heightUnit,
                  values: const ['cm', 'ft/in'],
                  onChanged: (value) => setModalState(() => heightUnit = value),
                ),
                const SizedBox(height: 12),
                _DropdownSetting(
                  label: 'Temperature',
                  value: temperatureUnit,
                  values: const ['C', 'F'],
                  onChanged: (value) =>
                      setModalState(() => temperatureUnit = value),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(modalContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(_weightUnitKey, weightUnit);
                          await prefs.setString(_heightUnitKey, heightUnit);
                          await prefs.setString(
                            _temperatureUnitKey,
                            temperatureUnit,
                          );
                          if (!modalContext.mounted) return;
                          setState(() {
                            _weightUnit = weightUnit;
                            _heightUnit = heightUnit;
                            _temperatureUnit = temperatureUnit;
                          });
                          Navigator.pop(modalContext);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showTargetsSheet() async {
    final stepGoal = TextEditingController(text: _stepGoal.text);
    final waterGoal = TextEditingController(text: _waterGoal.text);
    final sleepGoal = TextEditingController(text: _sleepGoal.text);
    final formKey = GlobalKey<FormState>();

    await showAppModal<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily targets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: stepGoal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily step target',
                    prefixIcon: Icon(Icons.directions_walk_outlined),
                  ),
                  validator: (value) {
                    final number = int.tryParse(value?.trim() ?? '');
                    return number == null || number <= 0 ? 'Enter steps' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: waterGoal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily water target (ml)',
                    prefixIcon: Icon(Icons.local_drink_outlined),
                  ),
                  validator: (value) {
                    final number = int.tryParse(value?.trim() ?? '');
                    return number == null || number <= 0 ? 'Enter ml' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sleepGoal,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Sleep target (hours)',
                    prefixIcon: Icon(Icons.bedtime_outlined),
                  ),
                  validator: (value) {
                    final number = double.tryParse(value?.trim() ?? '');
                    return number == null || number <= 0 ? 'Enter hours' : null;
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          _stepGoal.text = stepGoal.text.trim();
                          _waterGoal.text = waterGoal.text.trim();
                          _sleepGoal.text = sleepGoal.text.trim();
                          await _saveTargets();
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    stepGoal.dispose();
    waterGoal.dispose();
    sleepGoal.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wellnessControllerProvider).requireValue;
    final user = state.currentUser!;

    return AppScaffold(
      title: 'Settings',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SectionCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(user.name.isEmpty
                              ? '?'
                              : user.name[0].toUpperCase()),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Profile details'),
                        subtitle:
                            const Text('Name, age, gender, height, weight'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/profile'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SettingsSection(
                  title: 'Notifications',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary:
                          const Icon(Icons.notifications_active_outlined),
                      title: const Text('Reminder notifications'),
                      subtitle: const Text(
                          'Workout, hydration, and routine reminders'),
                      value: _notifications,
                      onChanged: (value) => _setBool(
                        _notificationsKey,
                        value,
                        (next) => _notifications = next,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.warning_amber_outlined),
                      title: const Text('Abnormal health alerts'),
                      subtitle:
                          const Text('High/low vitals and missed routines'),
                      value: _abnormalAlerts,
                      onChanged: (value) => _setBool(
                        _abnormalAlertsKey,
                        value,
                        (next) => _abnormalAlerts = next,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.summarize_outlined),
                      title: const Text('Weekly summary'),
                      subtitle:
                          const Text('Progress digest for goals and trends'),
                      value: _weeklySummary,
                      onChanged: (value) => _setBool(
                        _weeklySummaryKey,
                        value,
                        (next) => _weeklySummary = next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsSection(
                  title: 'Units & Daily Targets',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.straighten_outlined),
                      title: const Text('Units'),
                      subtitle: Text(
                        'Weight $_weightUnit, height $_heightUnit, temperature $_temperatureUnit',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showUnitsSheet,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.flag_outlined),
                      title: const Text('Daily targets'),
                      subtitle: Text(
                        '${_stepGoal.text} steps, ${_waterGoal.text} ml water, ${_sleepGoal.text}h sleep',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showTargetsSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsSection(
                  title: 'Privacy & Data',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.insights_outlined),
                      title: const Text('Private analytics'),
                      subtitle:
                          const Text('Use local data to personalize trends'),
                      value: _analytics,
                      onChanged: (value) => _setBool(
                        _analyticsKey,
                        value,
                        (next) => _analytics = next,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.medical_information_outlined),
                      title: const Text('Share with care provider'),
                      subtitle:
                          const Text('Off unless you explicitly enable it'),
                      value: _shareWithProvider,
                      onChanged: (value) => _setBool(
                        _shareWithProviderKey,
                        value,
                        (next) => _shareWithProvider = next,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.ios_share_outlined),
                      title: const Text('Export health data'),
                      subtitle: const Text('Copy your account data as JSON'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportData(state),
                    ),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_outline),
                      title: Text('Security'),
                      subtitle: Text('Tokens are stored in secure storage'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SettingsSection(
                  title: 'Connected Apps & Devices',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.watch_outlined),
                      title: Text('Wearables'),
                      subtitle: Text('No device connected'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.monitor_weight_outlined),
                      title: Text('Smart scale'),
                      subtitle: Text('Manual logging enabled'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.sync_outlined),
                      title: Text('Health platform sync'),
                      subtitle: Text(
                          'Apple Health / Google Fit integration not connected'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsSection(
                  title: 'App',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_outlined),
                      title: const Text('Backend'),
                      subtitle: Text(apiBaseUrl),
                    ),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.palette_outlined),
                      title: Text('Appearance'),
                      subtitle: Text('Dark health dashboard theme'),
                    ),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.info_outline),
                      title: Text('Version'),
                      subtitle: Text('1.0.0'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(wellnessControllerProvider.notifier)
                        .logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
    );
  }

  Future<void> _exportData(WellnessState state) async {
    const encoder = JsonEncoder.withIndent('  ');
    await Clipboard.setData(
        ClipboardData(text: encoder.convert(state.toMap())));
    _showMessage('Health data copied as JSON.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  const _DropdownSetting({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}
