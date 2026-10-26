import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_inputs.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _salaryController;
  late TextEditingController _hoursController;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      _salaryController = TextEditingController(text: provider.monthlySalary.toStringAsFixed(0));
      _hoursController = TextEditingController(text: provider.monthlyHours.toStringAsFixed(0));
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final salary = double.tryParse(_salaryController.text) ?? 0.0;
    final hours = double.tryParse(_hoursController.text) ?? 0.0;
    
    if (salary > 0 && hours > 0) {
      context.read<SettingsProvider>().updateSettings(
        salary: salary,
        hours: hours,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings updated successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SettingsProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Your Value',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tell us about your work to calculate the true cost of things.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              ModernTextField(
                label: 'MONTHLY NET SALARY',
                controller: _salaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixText: '\$ ',
              ),
              const SizedBox(height: AppSpacing.lg),
              
              ModernTextField(
                label: 'MONTHLY WORKING HOURS',
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffixText: ' hrs',
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: theme.colorScheme.primaryContainer,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Hourly Wage',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${provider.hourlyWage.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              ModernButton(
                text: 'Save Details',
                icon: Icons.check_circle_outline,
                onPressed: _saveSettings,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
