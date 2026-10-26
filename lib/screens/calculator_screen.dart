import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:worthwatch/providers/settings_provider.dart';
import 'package:worthwatch/theme.dart';
import 'package:worthwatch/widgets/custom_inputs.dart';
import 'package:worthwatch/widgets/monthly_time_consumption_bar.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _remainingController = TextEditingController();
  int _hours = 0;
  int _minutes = 0;
  int _days = 0;
  int _dayHours = 0;
  int _dayMinutes = 0;
  int _itemsPerMonth = 0;
  double _leftoverAfterItems = 0.0;
  double _lastParsedPrice = 0.0;

  int _budgetHours = 0;
  int _budgetMinutes = 0;
  int _budgetDays = 0;
  int _budgetDayHours = 0;
  int _budgetDayMinutes = 0;
  double _lastParsedBudget = 0.0;

  bool _syncedControllers = false;

  static const int _workingDaysPerMonth = 20;

  int get _consumedMinutes => (_hours * 60) + _minutes;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_calculateTime);
    _remainingController.addListener(_onRemainingChanged);
  }

  @override
  void dispose() {
    _priceController.removeListener(_calculateTime);
    _remainingController.removeListener(_onRemainingChanged);
    _priceController.dispose();
    _remainingController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<SettingsProvider>();
    if (!_syncedControllers && !provider.isLoading) {
      if (provider.remainingBalance > 0 && _remainingController.text.isEmpty) {
        _remainingController.text = provider.remainingBalance.toStringAsFixed(2);
      }
      _syncedControllers = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _calculateTime());
    }
  }

  void _onRemainingChanged() {
    if (!mounted) return;
    final provider = context.read<SettingsProvider>();
    final balance = double.tryParse(_remainingController.text) ?? 0.0;
    if ((balance - provider.remainingBalance).abs() < 0.005) {
      _calculateTime();
      return;
    }
    provider.setRemainingBalance(balance);
    _calculateTime();
  }

  void _calculateTime() {
    if (!mounted) return;

    final provider = context.read<SettingsProvider>();
    final isRemainingMode = provider.useRemainingBalanceMode;

    final priceText = _priceController.text;
    final price = double.tryParse(priceText) ?? 0.0;

    final result = provider.calculateTimeCost(price);
    final hours = result['hours'] ?? 0;
    final minutes = result['minutes'] ?? 0;
    final totalMinutes = (hours * 60) + minutes;

    final dailyHours = provider.monthlyHours > 0 ? provider.monthlyHours / _workingDaysPerMonth : 0.0;
    final minutesPerWorkday = (dailyHours * 60).round();

    int days = 0;
    int remHours = hours;
    int remMinutes = minutes;
    if (minutesPerWorkday > 0) {
      days = totalMinutes ~/ minutesPerWorkday;
      final remainingMinutes = totalMinutes % minutesPerWorkday;
      remHours = remainingMinutes ~/ 60;
      remMinutes = remainingMinutes % 60;
    }

    final budget = isRemainingMode ? provider.remainingBalance : provider.monthlySalary;

    int items = 0;
    double leftover = 0.0;
    if (price > 0 && budget > 0) {
      items = (budget / price).floor();
      leftover = budget - (items * price);
      if (leftover.isNaN || leftover.isInfinite) leftover = 0.0;
    }

    // Budget -> equivalent work time (mode 2) OR full-month time (mode 1)
    final budgetTime = provider.calculateTimeCost(budget);
    final bHours = budgetTime['hours'] ?? 0;
    final bMinutes = budgetTime['minutes'] ?? 0;
    final bTotalMinutes = (bHours * 60) + bMinutes;

    int bDays = 0;
    int bRemHours = bHours;
    int bRemMinutes = bMinutes;
    if (minutesPerWorkday > 0) {
      bDays = bTotalMinutes ~/ minutesPerWorkday;
      final remainingMinutes = bTotalMinutes % minutesPerWorkday;
      bRemHours = remainingMinutes ~/ 60;
      bRemMinutes = remainingMinutes % 60;
    }

    if (priceText.isEmpty) {
      setState(() {
        _hours = 0;
        _minutes = 0;
        _days = 0;
        _dayHours = 0;
        _dayMinutes = 0;
        _itemsPerMonth = 0;
        _leftoverAfterItems = 0.0;
        _lastParsedPrice = 0.0;

        _budgetHours = bHours;
        _budgetMinutes = bMinutes;
        _budgetDays = bDays;
        _budgetDayHours = bRemHours;
        _budgetDayMinutes = bRemMinutes;
        _lastParsedBudget = budget;
      });
      return;
    }

    setState(() {
      _hours = hours;
      _minutes = minutes;
      _days = days;
      _dayHours = remHours;
      _dayMinutes = remMinutes;
      _itemsPerMonth = items;
      _leftoverAfterItems = leftover;
      _lastParsedPrice = price;

      _budgetHours = bHours;
      _budgetMinutes = bMinutes;
      _budgetDays = bDays;
      _budgetDayHours = bRemHours;
      _budgetDayMinutes = bRemMinutes;
      _lastParsedBudget = budget;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SettingsProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isRemainingMode = provider.useRemainingBalanceMode;
    final monthlyMinutes = (provider.monthlyHours * 60).round();

    // In remaining-balance mode, the "total" is how much work the remaining money represents.
    final budgetTotalMinutes = isRemainingMode ? ((_budgetHours * 60) + _budgetMinutes) : monthlyMinutes;
    final pct = budgetTotalMinutes == 0 ? 0.0 : (_consumedMinutes / budgetTotalMinutes).clamp(0.0, 1.0);
    final pctLabel = (pct * 100).toStringAsFixed(1);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text(
                'True Cost',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enter a price to see how much of your life it costs.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _CalculationModeToggle(
                value: isRemainingMode,
                onChanged: (v) {
                  context.read<SettingsProvider>().setUseRemainingBalanceMode(v);
                  _calculateTime();
                },
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: isRemainingMode
                    ? Padding(
                        key: const ValueKey('remaining_balance_field'),
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: ModernTextField(
                          label: 'REMAINING BALANCE',
                          controller: _remainingController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixText: '\$ ',
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('remaining_balance_empty')),
              ),

              const SizedBox(height: AppSpacing.xl),

              ModernTextField(
                label: 'PRODUCT PRICE',
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixText: '\$ ',
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Result Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xxl,
                  horizontal: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'IT COSTS YOU',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildTimeBlock(_hours.toString(), 'hrs', theme),
                        const SizedBox(width: AppSpacing.lg),
                        _buildTimeBlock(_minutes.toString(), 'min', theme),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'OF WORK',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: theme.colorScheme.onPrimary.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 18, color: theme.colorScheme.onPrimary.withValues(alpha: 0.9)),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${_days}d ${_dayHours}h ${_dayMinutes}m',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              MonthlyTimeConsumptionBar(
                consumedMinutes: _consumedMinutes,
                monthlyMinutes: budgetTotalMinutes,
                title: isRemainingMode ? 'This purchase consumes $pctLabel% of your remaining money\'s work-time' : null,
                rangeLabel: isRemainingMode ? '0h → ${(_lastParsedBudget > 0 ? ((_budgetHours + (_budgetMinutes / 60.0))) : 0).toStringAsFixed(1)}h' : null,
                endCaption: isRemainingMode ? 'Balance exhausted' : 'End of month',
              ),
              if (isRemainingMode) ...[
                const SizedBox(height: AppSpacing.lg),
                _RemainingMoneyTimeCard(
                  remainingBalance: provider.remainingBalance,
                  days: _budgetDays,
                  hours: _budgetDayHours,
                  minutes: _budgetDayMinutes,
                  hourlyWage: provider.hourlyWage,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _ItemsPerMonthCard(
                price: _lastParsedPrice,
                monthlySalary: isRemainingMode ? provider.remainingBalance : provider.monthlySalary,
                itemsPerMonth: _itemsPerMonth,
                leftover: _leftoverAfterItems,
                label: isRemainingMode ? 'With your remaining balance, you can buy' : 'With your monthly salary, you can buy',
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Simulate scan button
              Center(
                child: GestureDetector(
                  onTap: () {
                    // Just simulate entering a random price for prototyping
                    _priceController.text = (15 + (DateTime.now().millisecond % 100)).toString();
                  },
                  child: Container(
                    padding: AppSpacing.paddingLg,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'Scan Barcode\n(Simulator)',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBlock(String value, String unit, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onPrimary,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ItemsPerMonthCard extends StatelessWidget {
  const _ItemsPerMonthCard({
    required this.price,
    required this.monthlySalary,
    required this.itemsPerMonth,
    required this.leftover,
    required this.label,
  });

  final double price;
  final double monthlySalary;
  final int itemsPerMonth;
  final double leftover;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final show = price > 0 && monthlySalary > 0;
    final strong = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface);
    final subtle = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.60));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: show
          ? Container(
              key: const ValueKey('items_per_month_card'),
              width: double.infinity,
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.10)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: theme.colorScheme.primaryContainer),
                    ),
                    child: Icon(Icons.shopping_bag_rounded, color: theme.colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: subtle),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(itemsPerMonth.toString(), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                            Text('items', style: strong),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Based on \$${monthlySalary.toStringAsFixed(0)} budget and \$${price.toStringAsFixed(2)} per item • leftover ≈ \$${leftover.toStringAsFixed(2)}',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('items_per_month_empty')),
    );
  }
}

class _CalculationModeToggle extends StatelessWidget {
  const _CalculationModeToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: theme.colorScheme.tertiaryContainer),
            ),
            child: Icon(Icons.tune_rounded, color: theme.colorScheme.tertiary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Calculation mode', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(
                  value ? 'Remaining balance (rest of period)' : 'Full month (salary + working hours)',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.60), height: 1.3),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
            inactiveThumbColor: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            inactiveTrackColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

class _RemainingMoneyTimeCard extends StatelessWidget {
  const _RemainingMoneyTimeCard({required this.remainingBalance, required this.days, required this.hours, required this.minutes, required this.hourlyWage});

  final double remainingBalance;
  final int days;
  final int hours;
  final int minutes;
  final double hourlyWage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final show = remainingBalance > 0 && hourlyWage > 0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: show
          ? Container(
              key: const ValueKey('remaining_money_time'),
              width: double.infinity,
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.10)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: theme.colorScheme.secondaryContainer),
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.secondary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Remaining balance equals', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.60))),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text('${days}d ${hours}h ${minutes}m', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
                            Text('of work', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Based on \$${remainingBalance.toStringAsFixed(2)} left and \$${hourlyWage.toStringAsFixed(2)}/hour',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('remaining_money_time_empty')),
    );
  }
}
