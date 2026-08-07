import 'package:flutter/material.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/navigation/module_add_action.dart';

class AppNavigationPanel extends StatefulWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;
  final bool drawer;

  const AppNavigationPanel({
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
    this.drawer = false,
    super.key,
  });

  @override
  State<AppNavigationPanel> createState() => _AppNavigationPanelState();
}

class _AppNavigationPanelState extends State<AppNavigationPanel> {
  late bool _incomeExpanded = _isIncomeRoute(widget.currentRoute);
  late bool _expenseExpanded = _isExpenseRoute(widget.currentRoute);
  late bool _netWorthExpanded = _isNetWorthRoute(widget.currentRoute);
  late bool _goalsExpanded = _isGoalsRoute(widget.currentRoute);
  late bool _recurringExpanded = _isRecurringRoute(widget.currentRoute);
  late bool _accountsExpanded = _isAccountsRoute(widget.currentRoute);
  late bool _transfersExpanded = _isTransfersRoute(widget.currentRoute);
  late bool _loansExpanded = _isLoanRoute(widget.currentRoute);
  late bool _toursExpanded = _isTourRoute(widget.currentRoute);

  static bool _isIncomeRoute(String route) =>
      route == Routes.income || route == Routes.addIncome;

  static bool _isExpenseRoute(String route) =>
      route == Routes.expense || route == Routes.addExpense;

  static bool _isGoalsRoute(String route) =>
      route == Routes.goals || route == Routes.addGoal;

  static bool _isNetWorthRoute(String route) =>
      route == Routes.netWorth ||
      route == Routes.netWorthAssets ||
      route == Routes.netWorthLiabilities ||
      route == Routes.netWorthDetails;

  static bool _isRecurringRoute(String route) =>
      route == Routes.recurring || route == Routes.addRecurring;

  static bool _isAccountsRoute(String route) =>
      route == Routes.accounts || route == Routes.addAccount;

  static bool _isTransfersRoute(String route) =>
      route == Routes.transfers || route == Routes.addTransfer;

  static bool _isLoanRoute(String route) =>
      route == Routes.moneyLent ||
      route == Routes.moneyBorrowed ||
      route == Routes.addLoanGiven ||
      route == Routes.addLoanTaken;

  static bool _isTourRoute(String route) => route.startsWith(Routes.tours);

  static const _destinations = <_NavigationDestination>[
    _NavigationDestination(
      route: Routes.home,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    _NavigationDestination(
      route: Routes.transactionSearch,
      label: 'Search',
      icon: Icons.manage_search_outlined,
      selectedIcon: Icons.manage_search_rounded,
    ),
  ];

  @override
  void didUpdateWidget(covariant AppNavigationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isIncomeRoute(widget.currentRoute)) {
      _incomeExpanded = true;
    }
    if (_isExpenseRoute(widget.currentRoute)) {
      _expenseExpanded = true;
    }
    if (_isNetWorthRoute(widget.currentRoute)) _netWorthExpanded = true;
    if (_isGoalsRoute(widget.currentRoute)) _goalsExpanded = true;
    if (_isRecurringRoute(widget.currentRoute)) _recurringExpanded = true;
    if (_isAccountsRoute(widget.currentRoute)) _accountsExpanded = true;
    if (_isTransfersRoute(widget.currentRoute)) _transfersExpanded = true;
    if (_isLoanRoute(widget.currentRoute)) {
      _loansExpanded = true;
    }
    if (_isTourRoute(widget.currentRoute)) _toursExpanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = SafeArea(
      child: Scrollbar(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('RunEarn', style: theme.textTheme.titleLarge),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OVERVIEW',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final destination in _destinations)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                child: _NavigationTile(
                  destination: destination,
                  selected: widget.currentRoute == destination.route,
                  onTap: () => widget.onNavigate(destination.route),
                ),
              ),
            _NavigationSection(
              label: 'Income',
              icon: Icons.trending_up_outlined,
              selected: _isIncomeRoute(widget.currentRoute),
              expanded: _incomeExpanded,
              onToggle: () =>
                  setState(() => _incomeExpanded = !_incomeExpanded),
              children: [
                _SubNavigationTile(
                  label: 'View Income',
                  icon: Icons.receipt_long_outlined,
                  selected: widget.currentRoute == Routes.income,
                  onTap: () => widget.onNavigate(Routes.income),
                ),
                _SubNavigationTile(
                  label: 'Add Income',
                  icon: Icons.add_circle_outline_rounded,
                  selected: false,
                  onTap: () => _openAddAction(context, Routes.addIncome),
                ),
              ],
            ),
            _NavigationSection(
              label: 'Expenses',
              icon: Icons.trending_down_outlined,
              selected: _isExpenseRoute(widget.currentRoute),
              expanded: _expenseExpanded,
              onToggle: () =>
                  setState(() => _expenseExpanded = !_expenseExpanded),
              children: [
                _SubNavigationTile(
                  label: 'View Expenses',
                  icon: Icons.receipt_long_outlined,
                  selected: widget.currentRoute == Routes.expense,
                  onTap: () => widget.onNavigate(Routes.expense),
                ),
                _SubNavigationTile(
                  label: 'Add Expense',
                  icon: Icons.add_circle_outline_rounded,
                  selected: false,
                  onTap: () => _openAddAction(context, Routes.addExpense),
                ),
              ],
            ),
            _NavigationSection(
              label: 'Net Worth',
              icon: Icons.insights_outlined,
              selected: _isNetWorthRoute(widget.currentRoute),
              expanded: _netWorthExpanded,
              onToggle: () =>
                  setState(() => _netWorthExpanded = !_netWorthExpanded),
              children: [
                _SubNavigationTile(
                  label: 'Overview',
                  icon: Icons.insights_outlined,
                  selected: widget.currentRoute == Routes.netWorth,
                  onTap: () => widget.onNavigate(Routes.netWorth),
                ),
                _SubNavigationTile(
                  label: 'Assets',
                  icon: Icons.trending_up_rounded,
                  selected: widget.currentRoute == Routes.netWorthAssets,
                  onTap: () => widget.onNavigate(Routes.netWorthAssets),
                ),
                _SubNavigationTile(
                  label: 'Liabilities',
                  icon: Icons.trending_down_rounded,
                  selected: widget.currentRoute == Routes.netWorthLiabilities,
                  onTap: () => widget.onNavigate(Routes.netWorthLiabilities),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: _NavigationTile(
                destination: const _NavigationDestination(
                  route: Routes.budgets,
                  label: 'Budgets',
                  icon: Icons.savings_outlined,
                  selectedIcon: Icons.savings_rounded,
                ),
                selected: widget.currentRoute == Routes.budgets,
                onTap: () => widget.onNavigate(Routes.budgets),
              ),
            ),
            _NavigationSection(
              label: 'Savings Goals',
              icon: Icons.flag_outlined,
              selected: _isGoalsRoute(widget.currentRoute),
              expanded: _goalsExpanded,
              onToggle: () => setState(() => _goalsExpanded = !_goalsExpanded),
              children: [
                _SubNavigationTile(
                  label: 'View Goals',
                  icon: Icons.flag_outlined,
                  selected: widget.currentRoute == Routes.goals,
                  onTap: () => widget.onNavigate(Routes.goals),
                ),
                _SubNavigationTile(
                  label: 'Add Goal',
                  icon: Icons.add_circle_outline_rounded,
                  selected: false,
                  onTap: () => _openAddAction(context, Routes.addGoal),
                ),
              ],
            ),
            _NavigationSection(
              label: 'Bills & Recurring',
              icon: Icons.event_repeat_outlined,
              selected: _isRecurringRoute(widget.currentRoute),
              expanded: _recurringExpanded,
              onToggle: () =>
                  setState(() => _recurringExpanded = !_recurringExpanded),
              children: [
                _SubNavigationTile(
                  label: 'View Schedules',
                  icon: Icons.event_note_outlined,
                  selected: widget.currentRoute == Routes.recurring,
                  onTap: () => widget.onNavigate(Routes.recurring),
                ),
                _SubNavigationTile(
                  label: 'Add Schedule',
                  icon: Icons.add_circle_outline_rounded,
                  selected: false,
                  onTap: () => _openAddAction(context, Routes.addRecurring),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: _NavigationTile(
                destination: const _NavigationDestination(
                  route: Routes.reports,
                  label: 'Reports',
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart_rounded,
                ),
                selected: widget.currentRoute == Routes.reports,
                onTap: () => widget.onNavigate(Routes.reports),
              ),
            ),
            _NavigationSection(
              label: 'Accounts',
              icon: Icons.account_balance_wallet_outlined,
              selected: _isAccountsRoute(widget.currentRoute),
              expanded: _accountsExpanded,
              onToggle: () =>
                  setState(() => _accountsExpanded = !_accountsExpanded),
              children: [
                _SubNavigationTile(
                  label: 'View Accounts',
                  icon: Icons.account_balance_wallet_outlined,
                  selected: widget.currentRoute == Routes.accounts,
                  onTap: () => widget.onNavigate(Routes.accounts),
                ),
                _SubNavigationTile(
                  label: 'Add Account',
                  icon: Icons.add_circle_outline_rounded,
                  selected: false,
                  onTap: () => _openAddAction(context, Routes.addAccount),
                ),
              ],
            ),
            _NavigationSection(
              label: 'Transfers',
              icon: Icons.swap_horiz_outlined,
              selected: _isTransfersRoute(widget.currentRoute),
              expanded: _transfersExpanded,
              onToggle: () =>
                  setState(() => _transfersExpanded = !_transfersExpanded),
              children: [
                _SubNavigationTile(
                  label: 'View Transfers',
                  icon: Icons.swap_horiz_rounded,
                  selected: widget.currentRoute == Routes.transfers,
                  onTap: () => widget.onNavigate(Routes.transfers),
                ),
                _SubNavigationTile(
                  label: 'New Transfer',
                  icon: Icons.add_circle_outline_rounded,
                  selected: false,
                  onTap: () => _openAddAction(context, Routes.addTransfer),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: _ExpandableNavigationTile(
                label: 'Loans',
                icon: Icons.handshake_outlined,
                selected: _isLoanRoute(widget.currentRoute),
                expanded: _loansExpanded,
                onTap: () {
                  setState(() => _loansExpanded = !_loansExpanded);
                },
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _loansExpanded
                  ? Column(
                      children: [
                        _SubNavigationTile(
                          label: 'Loans Given',
                          icon: Icons.call_made_rounded,
                          selected: widget.currentRoute == Routes.moneyLent,
                          onTap: () => widget.onNavigate(Routes.moneyLent),
                        ),
                        _SubNavigationTile(
                          label: 'Add Loan Given',
                          icon: Icons.add_circle_outline_rounded,
                          selected: false,
                          onTap: () =>
                              _openAddAction(context, Routes.addLoanGiven),
                        ),
                        _SubNavigationTile(
                          label: 'Loans Taken',
                          icon: Icons.call_received_rounded,
                          selected: widget.currentRoute == Routes.moneyBorrowed,
                          onTap: () => widget.onNavigate(Routes.moneyBorrowed),
                        ),
                        _SubNavigationTile(
                          label: 'Add Loan Taken',
                          icon: Icons.add_circle_outline_rounded,
                          selected: false,
                          onTap: () =>
                              _openAddAction(context, Routes.addLoanTaken),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            _NavigationSection(
              label: 'Tours',
              icon: Icons.travel_explore_outlined,
              selected: _isTourRoute(widget.currentRoute),
              expanded: _toursExpanded,
              onToggle: () => setState(() => _toursExpanded = !_toursExpanded),
              children: [
                _SubNavigationTile(
                  label: 'View Tours',
                  icon: Icons.luggage_outlined,
                  selected: widget.currentRoute == Routes.tours,
                  onTap: () => widget.onNavigate(Routes.tours),
                ),
                _SubNavigationTile(
                  label: 'Plan Tour',
                  icon: Icons.add_circle_outline_rounded,
                  selected: false,
                  onTap: () => _openAddAction(context, Routes.addTour),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: _NavigationTile(
                destination: const _NavigationDestination(
                  route: Routes.profile,
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                ),
                selected: widget.currentRoute == Routes.profile,
                onTap: () => widget.onNavigate(Routes.profile),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: _NavigationTile(
                destination: const _NavigationDestination(
                  route: Routes.settings,
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                ),
                selected: widget.currentRoute.startsWith(Routes.settings),
                onTap: () => widget.onNavigate(Routes.settings),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Logout'),
                textColor: theme.colorScheme.error,
                iconColor: theme.colorScheme.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: widget.onLogout,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Track today. Grow tomorrow.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.drawer) {
      return Drawer(width: 290, child: content);
    }

    return Material(
      color: theme.colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: theme.dividerColor)),
        ),
        child: content,
      ),
    );
  }

  void _openAddAction(BuildContext context, String route) {
    final navigator = Navigator.of(context);
    if (widget.drawer) {
      navigator.pop();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => showModuleAddAction(navigator.context, route),
      );
      return;
    }
    showModuleAddAction(context, route);
  }
}

class _NavigationSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _NavigationSection({
    required this.label,
    required this.icon,
    required this.selected,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: _ExpandableNavigationTile(
            label: label,
            icon: icon,
            selected: selected,
            expanded: expanded,
            onTap: onToggle,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: expanded
              ? Column(children: children)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ExpandableNavigationTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _ExpandableNavigationTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      selected: selected,
      selectedColor: colors.onPrimary,
      selectedTileColor: colors.primary,
      leading: Icon(icon),
      title: Text(label),
      trailing: AnimatedRotation(
        turns: expanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 220),
        child: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}

class _SubNavigationTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SubNavigationTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 10, bottom: 3),
      child: ListTile(
        dense: true,
        selected: selected,
        selectedColor: colors.onPrimary,
        selectedTileColor: colors.primary,
        leading: Icon(icon, size: 19),
        title: Text(label),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final _NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      selected: selected,
      selectedColor: colors.onPrimary,
      selectedTileColor: colors.primary,
      leading: Icon(selected ? destination.selectedIcon : destination.icon),
      title: Text(destination.label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}

class _NavigationDestination {
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavigationDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
