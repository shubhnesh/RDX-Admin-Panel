part of 'rewards_management_screen.dart';

// ---------------------------------------------------------------------------
// Transaction screen local state.
//
// Extensions cannot declare fields, so the filter / sort / pagination state is
// stored in an Expando keyed by the State object. No change is needed in
// `_RewardsManagementScreenState`. (Previously these filters were declared as
// local variables inside the build method, so they were reset on every rebuild
// and the dropdowns never actually filtered anything.)
// ---------------------------------------------------------------------------

enum _TxRange { all, today, days7, days30, days90, custom }

class _TransactionFilters {
  String user = 'all';
  String status = 'all';
  _TxRange range = _TxRange.all;
  DateTimeRange? customRange;
  String sortField = 'date'; // 'date' | 'points'
  bool ascending = false;
  int page = 0;
  int pageSize = 10;
}

final Expando<_TransactionFilters> _transactionFilterStore =
    Expando<_TransactionFilters>('rewardsTransactionFilters');

typedef _TransactionViewData = ({
  List<RewardTransaction> filtered,
  List<String> users,
  List<String> statuses,
  String userValue,
  String statusValue,
});

extension _RewardsRecordsView on _RewardsManagementScreenState {
  _TransactionFilters get _txf =>
      _transactionFilterStore[this] ??= _TransactionFilters();

  // -------------------------------------------------------------------------
  // Transactions page
  // -------------------------------------------------------------------------

  _TransactionViewData _transactionViewData(RewardsAdminProvider provider) {
    final f = _txf;
    final query = _transactionSearch.trim().toLowerCase();

    final users = provider.transactions
        .map((item) => item.userId)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final statuses = provider.transactions
        .map((item) => item.status?.trim() ?? '')
        .where((status) => status.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Guard against a stale selection after the data reloads.
    final userValue =
        (f.user == 'all' || users.contains(f.user)) ? f.user : 'all';
    final statusValue =
        (f.status == 'all' || statuses.contains(f.status)) ? f.status : 'all';

    final rangeStart = _txRangeStart(f);
    final rangeEnd = _txRangeEnd(f);

    final filtered = provider.transactions.where((item) {
      final matchesSearch = query.isEmpty ||
          item.userId.toLowerCase().contains(query) ||
          (item.orderId?.toLowerCase().contains(query) ?? false) ||
          (item.referralId?.toLowerCase().contains(query) ?? false) ||
          item.description.toLowerCase().contains(query);

      final matchesUser = userValue == 'all' || item.userId == userValue;

      final matchesType = _transactionType == null ||
          _transactionTypeKey(item.type) == _transactionType;

      final matchesStatus = statusValue == 'all' ||
          (item.status ?? '').toLowerCase().trim() ==
              statusValue.toLowerCase().trim();

      var matchesDate = true;
      if (rangeStart != null || rangeEnd != null) {
        final date = _txParseDate(item.createdAt);
        if (date == null) {
          matchesDate = false;
        } else {
          if (rangeStart != null && date.isBefore(rangeStart)) {
            matchesDate = false;
          }
          if (rangeEnd != null && !date.isBefore(rangeEnd)) {
            matchesDate = false;
          }
        }
      }

      return matchesSearch &&
          matchesUser &&
          matchesType &&
          matchesStatus &&
          matchesDate;
    }).toList();

    filtered.sort((a, b) {
      int result;
      if (f.sortField == 'points') {
        result = a.points.compareTo(b.points);
      } else {
        final da = _txParseDate(a.createdAt);
        final db = _txParseDate(b.createdAt);
        if (da == null && db == null) {
          result = 0;
        } else if (da == null) {
          result = -1;
        } else if (db == null) {
          result = 1;
        } else {
          result = da.compareTo(db);
        }
      }
      return f.ascending ? result : -result;
    });

    return (
      filtered: filtered,
      users: users,
      statuses: statuses,
      userValue: userValue,
      statusValue: statusValue,
    );
  }

  Widget _transactions(
    RewardsAdminProvider provider,
    _TransactionViewData data,
  ) {
    final f = _txf;
    final colors = AppColors.of(context);
    final query = _transactionSearch.trim().toLowerCase();
    final filtered = data.filtered;
    final users = data.users;
    final statuses = data.statuses;
    final userValue = data.userValue;
    final statusValue = data.statusValue;

    // Pagination (client-side over the loaded records).
    final totalPages =
        filtered.isEmpty ? 1 : (filtered.length / f.pageSize).ceil();
    final currentPage = f.page.clamp(0, totalPages - 1);
    final pageStart = currentPage * f.pageSize;
    final pageItems =
        filtered.skip(pageStart).take(f.pageSize).toList(growable: false);

    final hasActiveFilters = _transactionType != null ||
        userValue != 'all' ||
        statusValue != 'all' ||
        f.range != _TxRange.all ||
        query.isNotEmpty;

    return Padding(
      padding: Responsive.pagePadding(context, bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _transactionSummary(provider),
          SizedBox(height: context.h(12)),

          // Transaction filters.
          Container(
            padding: EdgeInsets.all(context.w(15)),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _transactionTypeChip(
                        label: 'All',
                        icon: Icons.apps_rounded,
                        selected: _transactionType == null,
                        onSelected: () =>
                            _selectTransactionType(provider, null),
                      ),
                      for (final entry in _txTypeOptions.entries)
                        Padding(
                          padding: EdgeInsets.only(left: context.w(8)),
                          child: _transactionTypeChip(
                            label: entry.value,
                            icon: _txTypeStyle(entry.key).icon,
                            selected: _transactionType == entry.key,
                            onSelected: () =>
                                _selectTransactionType(provider, entry.key),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: context.h(13)),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 900;
                    final searchWidth = compact
                        ? constraints.maxWidth
                        : constraints.maxWidth * 0.34;
                    final dropdownWidth = compact
                        ? (constraints.maxWidth - context.w(10)) / 2
                        : 170.0;

                    return Wrap(
                      spacing: context.w(10),
                      runSpacing: context.h(10),
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: searchWidth,
                          child: _transactionSearchField(provider),
                        ),
                        SizedBox(
                          width: dropdownWidth,
                          child: _transactionDropdown(
                            value: userValue,
                            icon: Icons.person_outline_rounded,
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'all',
                                child: Text('All Users'),
                              ),
                              ...users.map(
                                (user) => DropdownMenuItem<String>(
                                  value: user,
                                  child: Text(
                                    _shortId(user),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) => _updateState(() {
                              f.user = value ?? 'all';
                              f.page = 0;
                            }),
                          ),
                        ),
                        SizedBox(
                          width: dropdownWidth,
                          child: _transactionDropdown(
                            value: statusValue,
                            icon: Icons.filter_alt_outlined,
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'all',
                                child: Text('All Status'),
                              ),
                              ...statuses.map(
                                (status) => DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(
                                    status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) => _updateState(() {
                              f.status = value ?? 'all';
                              f.page = 0;
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (hasActiveFilters) ...[
                  SizedBox(height: context.h(12)),
                  _activeFilterRow(
                    provider,
                    userValue: userValue,
                    statusValue: statusValue,
                  ),
                ],
              ],
            ),
          ),

          if (provider.errorMessage != null) ...[
            SizedBox(height: context.h(10)),
            _inlineError(provider.errorMessage!),
          ],

          SizedBox(height: context.h(10)),

          if (provider.isLoading && filtered.isEmpty)
            const Expanded(
              child: Center(child: LoadingIndicator()),
            )
          else if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmptyState(
                        message: 'No transactions found. '
                            'Try changing the search text or filters. '
                            'A qualifying paid and delivered order, checkout '
                            'redemption, or referral bonus creates these '
                            'records automatically.',
                      ),
                      if (hasActiveFilters)
                        Padding(
                          padding: EdgeInsets.only(top: context.h(8)),
                          child: OutlinedButton.icon(
                            onPressed: () => _clearTransactionFilters(provider),
                            icon: const Icon(
                              Icons.filter_alt_off_rounded,
                              size: 17,
                            ),
                            label: const Text('Clear all filters'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            _transactionViewSummary(filtered),
            SizedBox(height: context.h(8)),

            // The table receives all remaining height in the screen.
            Expanded(
              child: _transactionTable(pageItems),
            ),

            SizedBox(height: context.h(8)),
            _transactionFooter(
              provider,
              total: filtered.length,
              pageStart: pageStart,
              pageCount: pageItems.length,
              currentPage: currentPage,
              totalPages: totalPages,
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------

  Widget _transactionHeader(
    RewardsAdminProvider provider,
    List<RewardTransaction> filtered,
  ) {
    final f = _txf;

    final actions = Wrap(
      spacing: context.w(10),
      runSpacing: context.h(10),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PopupMenuButton<_TxRange>(
          tooltip: 'Date range',
          position: PopupMenuPosition.under,
          onSelected: (range) async {
            if (range == _TxRange.custom) {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 1),
                initialDateRange: f.customRange,
              );
              if (picked == null || !mounted) return;
              _updateState(() {
                f.range = _TxRange.custom;
                f.customRange = picked;
                f.page = 0;
              });
            } else {
              _updateState(() {
                f.range = range;
                f.page = 0;
              });
            }
          },
          itemBuilder: (context) => [
            for (final range in _TxRange.values)
              CheckedPopupMenuItem<_TxRange>(
                value: range,
                checked: f.range == range,
                child: Text(_txRangeLabel(range, null)),
              ),
          ],
          child: _headerPill(
            icon: Icons.calendar_today_outlined,
            label: _txRangeLabel(f.range, f.customRange),
            trailing: Icons.keyboard_arrow_down_rounded,
          ),
        ),
        OutlinedButton.icon(
          onPressed:
              filtered.isEmpty ? null : () => _exportTransactions(filtered),
          icon: const Icon(Icons.file_download_outlined, size: 17),
          label: const Text('Export'),
          style: _headerButtonStyle(),
        ),
        if (provider.canConfigure)
          OutlinedButton.icon(
            onPressed: provider.isMutating || provider.isLoading
                ? null
                : () => _reconcileOrderRewards(provider),
            icon: const Icon(Icons.sync_rounded, size: 17),
            label: const Text('Sync delivered order'),
            style: _headerButtonStyle(),
          ),
      ],
    );

    return actions;
  }

  ButtonStyle _headerButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      side: BorderSide(color: AppColors.border),
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(12),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _headerPill({
    required IconData icon,
    required String label,
    IconData? trailing,
  }) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(13),
        vertical: context.h(11),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.h(16), color: colors.textSecondary),
          SizedBox(width: context.w(8)),
          Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: context.w(4)),
            Icon(trailing, size: context.h(18), color: colors.textSecondary),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Filters
  // -------------------------------------------------------------------------

  static const Map<String, String> _txTypeOptions = {
    'earned': 'Earned',
    'redeemed': 'Redeemed',
    'referral_bonus': 'Referral bonus',
  };

  void _selectTransactionType(RewardsAdminProvider provider, String? type) {
    _updateState(() {
      _transactionType = type;
      _txf.page = 0;
    });
    provider.loadTransactions(type: type, search: _transactionSearch);
  }

  void _clearTransactionFilters(RewardsAdminProvider provider) {
    final f = _txf;
    final hadType = _transactionType != null;
    final hadSearch = _transactionSearch.trim().isNotEmpty;
    _transactionSearchController.clear();
    _updateState(() {
      _transactionSearch = '';
      _transactionType = null;
      f.user = 'all';
      f.status = 'all';
      f.range = _TxRange.all;
      f.customRange = null;
      f.page = 0;
    });
    if (hadType || hadSearch) {
      provider.loadTransactions(type: null, search: '');
    }
  }

  Widget _transactionSearchField(RewardsAdminProvider provider) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: context.h(44),
      child: TextField(
        controller: _transactionSearchController,
        style: AppTextStyles.caption(context).copyWith(
          color: colors.textPrimary,
        ),
        textInputAction: TextInputAction.search,
        onChanged: (value) => _updateState(() {
          _transactionSearch = value;
          _txf.page = 0;
        }),
        onSubmitted: (_) => provider.loadTransactions(
          type: _transactionType,
          search: _transactionSearch,
        ),
        decoration: InputDecoration(
          hintText: 'Search user, order, referral or description',
          hintStyle: AppTextStyles.caption(context).copyWith(
            color: colors.textMuted,
          ),
          filled: true,
          fillColor: colors.surfaceVariant,
          isDense: true,
          prefixIcon: Icon(
            Icons.search_rounded,
            size: context.h(19),
            color: colors.textMuted,
          ),
          suffixIcon: _transactionSearch.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: Icon(Icons.close_rounded, size: context.h(17)),
                  onPressed: () {
                    _transactionSearchController.clear();
                    _updateState(() {
                      _transactionSearch = '';
                      _txf.page = 0;
                    });
                    provider.loadTransactions(
                      type: _transactionType,
                      search: '',
                    );
                  },
                ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.w(11),
            vertical: context.h(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _transactionDropdown({
    required String value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colors = AppColors.of(context);

    return SizedBox(
      height: context.h(44),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.surface,
          prefixIcon: Icon(icon, size: context.h(17), color: colors.textMuted),
          prefixIconConstraints: BoxConstraints(
            minWidth: context.w(36),
            minHeight: context.h(20),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.w(11),
            vertical: context.h(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
        style: AppTextStyles.caption(context).copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _activeFilterRow(
    RewardsAdminProvider provider, {
    required String userValue,
    required String statusValue,
  }) {
    final f = _txf;
    final colors = AppColors.of(context);
    final query = _transactionSearch.trim();

    Widget chip(String label, VoidCallback onRemove) => InputChip(
          label: Text(label),
          onDeleted: onRemove,
          deleteIcon: const Icon(Icons.close_rounded, size: 15),
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          labelStyle: AppTextStyles.caption(context).copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
          visualDensity: VisualDensity.compact,
        );

    return Wrap(
      spacing: context.w(8),
      runSpacing: context.h(6),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Active filters:',
          style: AppTextStyles.caption(context).copyWith(
            color: colors.textMuted,
          ),
        ),
        if (query.isNotEmpty)
          chip('Search: "$query"', () {
            _transactionSearchController.clear();
            _updateState(() {
              _transactionSearch = '';
              f.page = 0;
            });
            provider.loadTransactions(type: _transactionType, search: '');
          }),
        if (_transactionType != null)
          chip(
            'Type: ${_txTypeOptions[_transactionType] ?? _transactionType}',
            () => _selectTransactionType(provider, null),
          ),
        if (userValue != 'all')
          chip('User: ${_shortId(userValue)}', () {
            _updateState(() {
              f.user = 'all';
              f.page = 0;
            });
          }),
        if (statusValue != 'all')
          chip('Status: $statusValue', () {
            _updateState(() {
              f.status = 'all';
              f.page = 0;
            });
          }),
        if (f.range != _TxRange.all)
          chip('Date: ${_txRangeLabel(f.range, f.customRange)}', () {
            _updateState(() {
              f.range = _TxRange.all;
              f.customRange = null;
              f.page = 0;
            });
          }),
        TextButton.icon(
          onPressed: () => _clearTransactionFilters(provider),
          icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
          label: const Text('Clear all'),
        ),
      ],
    );
  }

  Widget _transactionTypeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final colors = AppColors.of(context);
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: context.h(15),
        color: selected ? AppColors.primaryDark : colors.textMuted,
      ),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundColor: colors.surface,
      side: BorderSide(color: selected ? AppColors.primary : colors.border),
      labelStyle: AppTextStyles.caption(context).copyWith(
        color: selected ? AppColors.primaryDark : colors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Summary cards
  // -------------------------------------------------------------------------

  Widget _transactionSummary(RewardsAdminProvider provider) {
    final analytics = provider.analytics;
    if (analytics == null) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: Responsive.statColumns(context, max: 4),
      crossAxisSpacing: context.w(12),
      mainAxisSpacing: context.h(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: Responsive.isMobile(context) ? 1.8 : 2.4,
      children: [
        _transactionMetric(
          'Lifetime points issued',
          _number(analytics.totalPointsIssued),
          'All-time credited points',
          Icons.stars_rounded,
          const Color(0xFFFFF1DF),
          const Color(0xFFF39A24),
        ),
        _transactionMetric(
          'Lifetime points redeemed',
          _number(analytics.totalPointsRedeemed),
          'All-time redeemed points',
          Icons.card_giftcard_rounded,
          const Color(0xFFE7F8ED),
          const Color(0xFF16A05A),
        ),
        _transactionMetric(
          'Users with balances',
          _number(analytics.usersWithBalances),
          'Customers with wallet points',
          Icons.people_alt_rounded,
          const Color(0xFFEAF2FF),
          const Color(0xFF3276E5),
        ),
        _transactionMetric(
          'Outstanding points',
          _number(analytics.outstandingPointsLiability),
          'Current points liability',
          Icons.diamond_rounded,
          const Color(0xFFF2EAFE),
          const Color(0xFF8747D6),
        ),
      ],
    );
  }

  Widget _transactionMetric(
    String label,
    String value,
    String hint,
    IconData icon,
    Color background,
    Color accent,
  ) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background,
            Color.lerp(background, colors.surface, 0.55) ?? background,
          ],
        ),
        borderRadius: BorderRadius.circular(context.h(14)),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: context.w(42),
            height: context.w(42),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: context.h(22)),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.section(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2430),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: const Color(0xFF4A5160),
                  ),
                ),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: accent,
                    fontSize: context.sp(11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small strip describing the records currently in view (after filters).
  Widget _transactionViewSummary(List<RewardTransaction> filtered) {
    final colors = AppColors.of(context);
    var credits = 0;
    var debits = 0;
    for (final item in filtered) {
      if (item.points >= 0) {
        credits += item.points;
      } else {
        debits += item.points;
      }
    }
    final net = credits + debits;

    Widget stat(String label, String value, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: context.w(6)),
            Text(
              '$label ',
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(10),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Wrap(
        spacing: context.w(20),
        runSpacing: context.h(6),
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'In current view',
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          stat('Records', _number(filtered.length), AppColors.primary),
          stat(
            'Credited',
            '+${_number(credits)}',
            const Color(0xFF138A4A),
          ),
          stat('Debited', _number(debits), AppColors.danger),
          stat(
            'Net',
            net > 0 ? '+${_number(net)}' : _number(net),
            net < 0 ? AppColors.danger : const Color(0xFF138A4A),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Table
  // -------------------------------------------------------------------------

  // (title, width, sortKey)
  static const List<(String, double, String?)> _txColumns = [
    ('Date & time', 150, 'date'),
    ('User', 215, null),
    ('Type', 150, null),
    ('Points', 110, 'points'),
    ('Order ID', 190, null),
    ('Details', 250, null),
    ('Status', 130, null),
    ('Actions', 64, null),
  ];

  Widget _transactionTable(List<RewardTransaction> items) {
    final colors = AppColors.of(context);
    final totalMin = _txColumns.fold<double>(0, (sum, c) => sum + c.$2);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth > totalMin ? constraints.maxWidth : totalMin;
          final scale = width / totalMin;
          final widths = [for (final c in _txColumns) c.$2 * scale];

          return Scrollbar(
            thumbVisibility: width > constraints.maxWidth,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The header remains fixed while transaction rows scroll.
                    _transactionHeaderRow(widths),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: items.length > 1,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            children: [
                              for (var i = 0; i < items.length; i++)
                                _transactionRow(
                                  items[i],
                                  widths,
                                  isLast: i == items.length - 1,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _transactionHeaderRow(List<double> widths) {
    final colors = AppColors.of(context);
    final f = _txf;

    return Container(
      color: colors.surfaceVariant,
      padding: EdgeInsets.symmetric(vertical: context.h(12)),
      child: Row(
        children: [
          for (var i = 0; i < _txColumns.length; i++)
            SizedBox(
              width: widths[i],
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(12)),
                child: _txColumns[i].$3 == null
                    ? Text(
                        _txColumns[i].$1,
                        style: _headerTextStyle(),
                      )
                    : InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _updateState(() {
                          final key = _txColumns[i].$3!;
                          if (f.sortField == key) {
                            f.ascending = !f.ascending;
                          } else {
                            f.sortField = key;
                            f.ascending = false;
                          }
                          f.page = 0;
                        }),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _txColumns[i].$1,
                                overflow: TextOverflow.ellipsis,
                                style: _headerTextStyle(),
                              ),
                            ),
                            SizedBox(width: context.w(3)),
                            Icon(
                              f.sortField == _txColumns[i].$3
                                  ? (f.ascending
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded)
                                  : Icons.unfold_more_rounded,
                              size: context.h(14),
                              color: f.sortField == _txColumns[i].$3
                                  ? AppColors.primary
                                  : colors.textMuted,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _headerTextStyle() {
    final colors = AppColors.of(context);
    return AppTextStyles.caption(context).copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w700,
    );
  }

  Widget _transactionRow(
    RewardTransaction item,
    List<double> widths, {
    required bool isLast,
  }) {
    final colors = AppColors.of(context);

    Widget cell(int index, Widget child) => SizedBox(
          width: widths[index],
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(12)),
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        );

    return InkWell(
      onTap: () => _showTransactionDetails(item),
      child: Container(
        constraints: BoxConstraints(minHeight: context.h(68)),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.border.withValues(alpha: 0.7)),
          ),
        ),
        child: Row(
          children: [
            cell(0, _transactionDateCell(item.createdAt)),
            cell(1, _transactionUserCell(item.userId)),
            cell(2, _transactionTypeBadge(item.type)),
            cell(3, _pointsCell(item.points)),
            cell(4, _transactionOrderCell(item.orderId)),
            cell(5, _transactionDetails(item)),
            cell(6, _transactionStatus(item.status)),
            cell(7, _transactionActions(item)),
          ],
        ),
      ),
    );
  }

  Widget _transactionDateCell(dynamic createdAt) {
    final colors = AppColors.of(context);
    final text = _date(createdAt);
    final parts = text.split(' ');
    if (parts.length < 2) {
      return Text(text, style: AppTextStyles.caption(context));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          parts.first,
          style: AppTextStyles.caption(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.h(2)),
        Text(
          parts.sublist(1).join(' '),
          style: AppTextStyles.caption(context).copyWith(
            color: colors.textMuted,
            fontSize: context.sp(11),
          ),
        ),
      ],
    );
  }

  Widget _transactionUserCell(String userId) {
    final colors = AppColors.of(context);
    final avatarColor = _avatarColor(userId);
    final initial =
        userId.trim().isEmpty ? '?' : userId.trim()[0].toUpperCase();

    return Tooltip(
      message: '$userId\n(tap to copy)',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _copyText(userId, 'User ID copied'),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.h(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.w(30),
                height: context.w(30),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: AppTextStyles.caption(context).copyWith(
                    color: avatarColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: context.w(8)),
              Flexible(
                child: Text(
                  _shortId(userId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: context.w(4)),
              Icon(
                Icons.copy_rounded,
                size: context.h(12),
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionOrderCell(String? orderId) {
    final colors = AppColors.of(context);
    if (orderId == null || orderId.isEmpty) {
      return Text(
        '—',
        style: AppTextStyles.caption(context).copyWith(color: colors.textMuted),
      );
    }
    return Tooltip(
      message: '$orderId\n(tap to copy)',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _copyText(orderId, 'Order ID copied'),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.h(6)),
          child: Text(
            orderId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  ({String label, IconData icon, Color color}) _txTypeStyle(String key) {
    switch (key) {
      case 'earned':
        return (
          label: 'Earned',
          icon: Icons.star_rounded,
          color: const Color(0xFF138A4A),
        );
      case 'redeemed':
        return (
          label: 'Redeemed',
          icon: Icons.card_giftcard_rounded,
          color: const Color(0xFFD04A2B),
        );
      case 'referral_bonus':
        return (
          label: 'Referral bonus',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF2868CB),
        );
      case 'reversal':
        return (
          label: 'Reversal',
          icon: Icons.undo_rounded,
          color: const Color(0xFF9A4BB8),
        );
      default:
        return (
          label: 'Adjustment',
          icon: Icons.tune_rounded,
          color: const Color(0xFF9A6A08),
        );
    }
  }

  Widget _transactionTypeBadge(RewardTransactionType type) {
    final style = _txTypeStyle(_transactionTypeKey(type));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(9),
        vertical: context.h(6),
      ),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: context.h(14), color: style.color),
          SizedBox(width: context.w(5)),
          Flexible(
            child: Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: style.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointsCell(int points) {
    final color = points < 0 ? AppColors.danger : const Color(0xFF138A4A);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          points < 0
              ? Icons.remove_circle_outline_rounded
              : Icons.add_circle_outline_rounded,
          size: context.h(14),
          color: color,
        ),
        SizedBox(width: context.w(5)),
        Text(
          points > 0 ? '+${_number(points)}' : _number(points),
          style: AppTextStyles.caption(context).copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _transactionDetails(RewardTransaction item) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.description.isEmpty ? '—' : item.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            color: colors.textPrimary,
          ),
        ),
        if (item.referralId != null && item.referralId!.isNotEmpty) ...[
          SizedBox(height: context.h(3)),
          Text(
            'Referral: ${item.referralId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textMuted,
              fontSize: context.sp(11),
            ),
          ),
        ],
      ],
    );
  }

  Widget _transactionStatus(String? status) {
    final colors = AppColors.of(context);
    final normalized = status?.toLowerCase().trim();
    final isSuccessful = normalized == 'completed' || normalized == 'complete';
    final isFailed = normalized == 'failed' ||
        normalized == 'reversed' ||
        normalized == 'cancelled';
    final isPending = normalized == 'pending' || normalized == 'reserved';

    final Color foreground = isSuccessful
        ? const Color(0xFF138A4A)
        : isFailed
            ? AppColors.danger
            : isPending
                ? const Color(0xFF9A6A08)
                : colors.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(9),
        vertical: context.h(6),
      ),
      decoration: BoxDecoration(
        color: isSuccessful || isFailed || isPending
            ? foreground.withValues(alpha: 0.12)
            : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuccessful
                ? Icons.check_circle_rounded
                : isFailed
                    ? Icons.error_outline_rounded
                    : isPending
                        ? Icons.schedule_rounded
                        : Icons.info_outline_rounded,
            size: context.h(13),
            color: foreground,
          ),
          SizedBox(width: context.w(5)),
          Flexible(
            child: Text(
              status?.trim().isNotEmpty == true ? status!.trim() : 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionActions(RewardTransaction item) {
    final colors = AppColors.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: Icon(Icons.more_vert_rounded,
          size: context.h(19), color: colors.textSecondary),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        switch (value) {
          case 'view':
            _showTransactionDetails(item);
          case 'user':
            _copyText(item.userId, 'User ID copied');
          case 'order':
            _copyText(item.orderId ?? '', 'Order ID copied');
          case 'referral':
            _copyText(item.referralId ?? '', 'Referral ID copied');
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.visibility_outlined, size: 18),
            title: Text('View details'),
          ),
        ),
        const PopupMenuItem(
          value: 'user',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline_rounded, size: 18),
            title: Text('Copy user ID'),
          ),
        ),
        if (item.orderId != null && item.orderId!.isNotEmpty)
          const PopupMenuItem(
            value: 'order',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.receipt_long_outlined, size: 18),
              title: Text('Copy order ID'),
            ),
          ),
        if (item.referralId != null && item.referralId!.isNotEmpty)
          const PopupMenuItem(
            value: 'referral',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.people_outline_rounded, size: 18),
              title: Text('Copy referral ID'),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Footer / pagination
  // -------------------------------------------------------------------------

  Widget _transactionFooter(
    RewardsAdminProvider provider, {
    required int total,
    required int pageStart,
    required int pageCount,
    required int currentPage,
    required int totalPages,
  }) {
    final colors = AppColors.of(context);
    final f = _txf;

    final info = Text(
      'Showing ${_number(pageStart + 1)}–${_number(pageStart + pageCount)} '
      'of ${_number(total)} loaded transaction${total == 1 ? '' : 's'}',
      style: AppTextStyles.caption(context),
    );

    Widget pageButton(int? page) {
      if (page == null) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(4)),
          child: Text('…', style: AppTextStyles.caption(context)),
        );
      }
      final selected = page == currentPage;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.w(2)),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: selected ? null : () => _updateState(() => f.page = page),
          child: Container(
            width: context.w(32),
            height: context.w(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.primary : colors.border,
              ),
            ),
            child: Text(
              '${page + 1}',
              style: AppTextStyles.caption(context).copyWith(
                color: selected ? Colors.white : colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    Widget arrow(IconData icon, bool enabled, VoidCallback onTap) => IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, size: context.h(19)),
        );

    final pager = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        arrow(
          Icons.chevron_left_rounded,
          currentPage > 0,
          () => _updateState(() => f.page = currentPage - 1),
        ),
        for (final page in _pageNumbers(currentPage, totalPages))
          pageButton(page),
        arrow(
          Icons.chevron_right_rounded,
          currentPage < totalPages - 1,
          () => _updateState(() => f.page = currentPage + 1),
        ),
      ],
    );

    final rowsPerPage = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Rows', style: AppTextStyles.caption(context)),
        SizedBox(width: context.w(8)),
        DropdownButton<int>(
          value: f.pageSize,
          underline: const SizedBox.shrink(),
          isDense: true,
          style: AppTextStyles.caption(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          items: const [10, 15, 25, 50, 100]
              .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
              .toList(),
          onChanged: (value) => _updateState(() {
            f.pageSize = value ?? 10;
            f.page = 0;
          }),
        ),
      ],
    );

    final loadMore = provider.hasMoreTransactions
        ? OutlinedButton.icon(
            onPressed: provider.isLoading
                ? null
                : () => provider.loadTransactions(
                      type: _transactionType,
                      search: _transactionSearch,
                      nextPage: true,
                    ),
            icon: const Icon(Icons.expand_more_rounded, size: 18),
            label:
                Text(provider.isLoading ? 'Loading...' : 'Load more records'),
          )
        : null;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: context.w(16),
      runSpacing: context.h(10),
      children: [
        info,
        Wrap(
          spacing: context.w(14),
          runSpacing: context.h(8),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            rowsPerPage,
            if (totalPages > 1) pager,
            if (loadMore != null) loadMore,
          ],
        ),
      ],
    );
  }

  List<int?> _pageNumbers(int current, int total) {
    if (total <= 7) return List<int?>.generate(total, (i) => i);
    final pages = <int?>[0];
    final start = (current - 1).clamp(1, total - 2);
    final end = (current + 1).clamp(1, total - 2);
    if (start > 1) pages.add(null);
    for (var i = start; i <= end; i++) {
      pages.add(i);
    }
    if (end < total - 2) pages.add(null);
    pages.add(total - 1);
    return pages;
  }

  // -------------------------------------------------------------------------
  // Details dialog / export / helpers
  // -------------------------------------------------------------------------

  Future<void> _showTransactionDetails(RewardTransaction item) {
    final colors = AppColors.of(context);
    final style = _txTypeStyle(_transactionTypeKey(item.type));

    Widget row(String label, Widget value) => Padding(
          padding: EdgeInsets.symmetric(vertical: context.h(7)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: context.w(110),
                child: Text(
                  label,
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
              Expanded(child: value),
            ],
          ),
        );

    Widget textValue(String? text) => SelectableText(
          (text == null || text.isEmpty) ? '—' : text,
          style: AppTextStyles.caption(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        );

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(style.icon, color: style.color),
            const SizedBox(width: 10),
            Text('${style.label} transaction'),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                row('Date & time', textValue(_date(item.createdAt))),
                row('User ID', textValue(item.userId)),
                row('Type', _transactionTypeBadge(item.type)),
                row('Points', _pointsCell(item.points)),
                row('Order ID', textValue(item.orderId)),
                row('Referral ID', textValue(item.referralId)),
                row('Description', textValue(item.description)),
                row('Status', _transactionStatus(item.status)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTransactions(List<RewardTransaction> items) async {
    String esc(String? value) {
      final text = value ?? '';
      if (text.contains(',') || text.contains('"') || text.contains('\n')) {
        return '"${text.replaceAll('"', '""')}"';
      }
      return text;
    }

    final buffer = StringBuffer(
      'Date & time,User ID,Type,Points,Order ID,Referral ID,Description,Status\n',
    );
    for (final item in items) {
      buffer.writeln([
        esc(_date(item.createdAt)),
        esc(item.userId),
        esc(_txTypeStyle(_transactionTypeKey(item.type)).label),
        item.points.toString(),
        esc(item.orderId),
        esc(item.referralId),
        esc(item.description),
        esc(item.status),
      ].join(','));
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    _showMessage(
      'Copied ${items.length} transaction${items.length == 1 ? '' : 's'} '
      'as CSV to the clipboard.',
    );
  }

  Future<void> _copyText(String text, String message) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showMessage(message);
  }

  String _shortId(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 9)}…${id.substring(id.length - 4)}';
  }

  Color _avatarColor(String seed) {
    const palette = [
      Color(0xFFF26A1B),
      Color(0xFF3276E5),
      Color(0xFF16A05A),
      Color(0xFF8747D6),
      Color(0xFFD04A2B),
      Color(0xFF0E9AA7),
    ];
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }

  DateTime? _txParseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  DateTime? _txRangeStart(_TransactionFilters f) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (f.range) {
      case _TxRange.all:
        return null;
      case _TxRange.today:
        return today;
      case _TxRange.days7:
        return today.subtract(const Duration(days: 6));
      case _TxRange.days30:
        return today.subtract(const Duration(days: 29));
      case _TxRange.days90:
        return today.subtract(const Duration(days: 89));
      case _TxRange.custom:
        final r = f.customRange;
        return r == null
            ? null
            : DateTime(r.start.year, r.start.month, r.start.day);
    }
  }

  DateTime? _txRangeEnd(_TransactionFilters f) {
    if (f.range == _TxRange.all) return null;
    if (f.range == _TxRange.custom) {
      final r = f.customRange;
      return r == null
          ? null
          : DateTime(r.end.year, r.end.month, r.end.day + 1);
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  String _txRangeLabel(_TxRange range, DateTimeRange? custom) {
    switch (range) {
      case _TxRange.all:
        return 'All time';
      case _TxRange.today:
        return 'Today';
      case _TxRange.days7:
        return 'Last 7 days';
      case _TxRange.days30:
        return 'Last 30 days';
      case _TxRange.days90:
        return 'Last 90 days';
      case _TxRange.custom:
        if (custom == null) return 'Custom range';
        String d(DateTime v) =>
            '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
        return '${d(custom.start)} → ${d(custom.end)}';
    }
  }

  String _transactionTypeKey(RewardTransactionType type) {
    return switch (type) {
      RewardTransactionType.earned => 'earned',
      RewardTransactionType.redeemed => 'redeemed',
      RewardTransactionType.referralBonus => 'referral_bonus',
      RewardTransactionType.reversal => 'reversal',
      RewardTransactionType.adjustment => 'adjustment',
    };
  }

  // -------------------------------------------------------------------------
  // Redemptions (unchanged)
  // -------------------------------------------------------------------------

  Widget _redemptions(RewardsAdminProvider provider) {
    final filtered = provider.redemptions.where((item) {
      final query = _redemptionSearch.toLowerCase();
      return query.isEmpty ||
          item.userId.toLowerCase().contains(query) ||
          item.rewardName.toLowerCase().contains(query) ||
          (item.orderId?.toLowerCase().contains(query) ?? false);
    }).toList();
    return _recordPage(
      title: 'Redemptions',
      subtitle: 'Read-only history of points spent at customer checkout.',
      searchHint: 'Search customer, reward or order',
      onSearch: (value) => _updateState(() => _redemptionSearch = value),
      searchController: _redemptionSearchController,
      onSearchSubmit: () => provider.loadRedemptions(
        status: _redemptionStatus,
        search: _redemptionSearch,
      ),
      filter: _redemptionStatus,
      filterOptions: const {
        'reserved': 'Reserved',
        'completed': 'Completed',
        'released': 'Released',
        'reversed': 'Reversed',
      },
      onFilter: (value) {
        _updateState(() => _redemptionStatus = value);
        provider.loadRedemptions(status: value, search: _redemptionSearch);
      },
      loading: provider.isLoading,
      emptyTitle: 'No redemptions found',
      emptyMessage:
          'A record appears when a customer spends points at checkout. Redemption history is not entered manually.',
      hasItems: filtered.isNotEmpty,
      compactTitle: true,
      table: _redemptionTable(filtered),
      onNextPage: provider.hasMoreRedemptions
          ? () => provider.loadRedemptions(
                status: _redemptionStatus,
                nextPage: true,
              )
          : null,
      error: provider.errorMessage,
    );
  }

  // -------------------------------------------------------------------------
  // Referrals (unchanged)
  // -------------------------------------------------------------------------

  Widget _referrals(RewardsAdminProvider provider) {
    final filtered = provider.referrals.where((item) {
      final query = _referralSearch.toLowerCase();
      return query.isEmpty ||
          item.referrerId.toLowerCase().contains(query) ||
          item.referredUserId.toLowerCase().contains(query) ||
          item.referralCode.toLowerCase().contains(query) ||
          (item.qualifyingOrderId?.toLowerCase().contains(query) ?? false);
    }).toList();
    return _recordPage(
      title: 'Referral management',
      subtitle: 'Read-only history of customer referral attributions.',
      searchHint: 'Search customer, code or qualifying order',
      onSearch: (value) => _updateState(() => _referralSearch = value),
      searchController: _referralSearchController,
      onSearchSubmit: () => provider.loadReferrals(
        status: _referralStatus,
        search: _referralSearch,
      ),
      filter: _referralStatus,
      filterOptions: const {
        'pending': 'Pending',
        'rewarded': 'Rewarded',
        'skipped': 'Skipped',
      },
      onFilter: (value) {
        _updateState(() => _referralStatus = value);
        provider.loadReferrals(status: value, search: _referralSearch);
      },
      loading: provider.isLoading,
      emptyTitle: 'No referral records found',
      emptyMessage:
          'A record appears after a customer applies another customer’s referral code. The bonus is issued after the qualifying order is paid and delivered.',
      hasItems: filtered.isNotEmpty,
      table: _referralTable(filtered),
      onNextPage: provider.hasMoreReferrals
          ? () => provider.loadReferrals(
                status: _referralStatus,
                nextPage: true,
              )
          : null,
      error: provider.errorMessage,
    );
  }

  Widget _recordPage({
    required String title,
    required String subtitle,
    Widget? headerAction,
    required String searchHint,
    required TextEditingController searchController,
    required ValueChanged<String> onSearch,
    required VoidCallback onSearchSubmit,
    required String? filter,
    required Map<String, String> filterOptions,
    required ValueChanged<String?> onFilter,
    required bool loading,
    required String emptyTitle,
    required String emptyMessage,
    required bool hasItems,
    required Widget table,
    required VoidCallback? onNextPage,
    bool compactTitle = false,
    String? error,
  }) =>
      _pageList(
        children: [
          if (headerAction == null)
            compactTitle
                ? _compactRecordTitle(title, subtitle)
                : _sectionTitle(title, subtitle)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle(title, subtitle),
                Align(
                  alignment: Alignment.centerRight,
                  child: headerAction,
                ),
              ],
            ),
          Wrap(
            spacing: context.w(12),
            runSpacing: context.h(10),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: Responsive.isMobile(context)
                    ? MediaQuery.sizeOf(context).width -
                        2 * Responsive.pageHorizontal(context)
                    : context.w(380),
                child: RdxSearchBar(
                  controller: searchController,
                  hintText: searchHint,
                  height: RdxSearchBar.standardHeight(context),
                  onChanged: onSearch,
                  onSubmitted: (_) => onSearchSubmit(),
                ),
              ),
              SizedBox(
                width: context.w(190),
                child: DropdownButtonFormField<String?>(
                  value: filter,
                  decoration: const InputDecoration(
                    labelText: 'Filter',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...filterOptions.entries.map(
                      (entry) => DropdownMenuItem<String?>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: onFilter,
                ),
              ),
            ],
          ),
          if (error != null) _inlineError(error),
          SizedBox(height: context.h(12)),
          if (loading && !hasItems)
            const LoadingIndicator()
          else if (!hasItems)
            EmptyState(message: '$emptyTitle. $emptyMessage')
          else
            table,
          if (onNextPage != null)
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                onPressed: loading ? null : onNextPage,
                icon: const Icon(Icons.expand_more),
                label: Text(loading ? 'Loading...' : 'Load more'),
              ),
            ),
        ],
      );

  Widget _compactRecordTitle(String title, String subtitle) {
    final colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.label(context).copyWith(
              color: colors.textPrimary,
              fontSize: context.sp(13),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            subtitle,
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textMuted,
              fontSize: context.sp(10),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Sync a delivered order (unchanged)
  // -------------------------------------------------------------------------

  Future<void> _reconcileOrderRewards(
    RewardsAdminProvider provider,
  ) async {
    final controller = TextEditingController();
    final orderId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync a delivered order'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Order ID',
            hintText: 'Enter the customer order ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Sync'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (orderId == null || orderId.isEmpty || !mounted) return;

    try {
      final result = await ref
          .read(rewardsAdminServiceProvider)
          .reconcileOrderRewards(orderId);
      await provider.load();
      await provider.loadTransactions(
        type: _transactionType,
        search: _transactionSearch,
      );
      if (!mounted) return;
      if (result.pointsEarned > 0) {
        _showMessage(
          result.reason == 'already_awarded'
              ? 'This order was already credited with ${result.pointsEarned} points.'
              : 'Order synced. ${result.pointsEarned} points were credited.',
        );
      } else {
        final message = switch (result.reason) {
          'order_not_eligible' =>
            'No points credited. The order must be both paid and delivered.',
          'no_customer' =>
            'No points credited. This order is not linked to a customer account.',
          'rewards_disabled' =>
            'No points credited. Enable the rewards program in Configuration.',
          'below_threshold' =>
            'No points credited. Check the minimum order and earning rate in Configuration.',
          'item_allocation_unavailable' =>
            'No points credited. This older order lacks the server-calculated item discount details needed for your item-specific rules.',
          _ => 'No points were credited for this order.',
        };
        _showMessage(message);
      }
    } catch (error) {
      if (mounted) _showMessage('Unable to sync order rewards: $error');
    }
  }

  // -------------------------------------------------------------------------
  // Redemption / referral tables (unchanged)
  // -------------------------------------------------------------------------

  Widget _redemptionTable(List<RewardRedemptionRecord> items) {
    final colors = AppColors.of(context);
    Widget header(String title) => Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label(context).copyWith(
            color: colors.textMuted,
            fontSize: context.sp(11),
            fontWeight: FontWeight.w700,
          ),
        );

    return SizedBox(
      height: context.h(390),
      child: RdxTable(
        columns: [
          RdxTableColumn(
            title: 'Customer',
            minWidth: 170,
            header: header('Customer'),
          ),
          RdxTableColumn(
            title: 'Reward',
            minWidth: 180,
            header: header('Reward'),
          ),
          RdxTableColumn(
            title: 'Points used',
            minWidth: 110,
            header: header('Points used'),
          ),
          RdxTableColumn(
            title: 'Order',
            minWidth: 160,
            header: header('Order'),
          ),
          RdxTableColumn(
            title: 'Date',
            minWidth: 155,
            header: header('Date'),
          ),
          RdxTableColumn(
            title: 'Status',
            minWidth: 120,
            header: header('Status'),
          ),
        ],
        rows: [
          for (final item in items)
            [
              _redemptionCell(item.userId),
              _redemptionCell(item.rewardName),
              _redemptionCell(_number(item.pointsUsed)),
              _redemptionCell(item.orderId ?? '—'),
              _redemptionCell(_date(item.createdAt)),
              _redemptionCell(item.status),
            ],
        ],
      ),
    );
  }

  Widget _redemptionCell(String text) {
    final colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(context).copyWith(
          color: colors.textSecondary,
          fontSize: context.sp(10),
        ),
      ),
    );
  }

  Widget _referralTable(List<RewardReferralRecord> items) => SizedBox(
        height: context.h(390),
        child: RdxTable(
          columns: const [
            RdxTableColumn(title: 'Referred By', minWidth: 160),
            RdxTableColumn(title: 'Referred To', minWidth: 180),
            RdxTableColumn(title: 'Code', minWidth: 130),
            RdxTableColumn(title: 'Status', minWidth: 120),
            RdxTableColumn(title: 'Qualifying order', minWidth: 160),
            RdxTableColumn(title: 'Points awarded', minWidth: 130),
            RdxTableColumn(title: 'Referral date', minWidth: 155),
          ],
          rows: [
            for (final item in items)
              [
                _cell(item.referrerId),
                _cell(item.referredUserId),
                _cell(item.referralCode),
                _cell(item.status),
                _cell(item.qualifyingOrderId ?? '—'),
                _cell(
                  '${_number(item.referrerPointsAwarded)}+'
                  '${_number(item.referredPointsAwarded)}',
                ),
                _cell(_date(item.createdAt)),
              ],
          ],
        ),
      );

  Widget _cell(String text) => Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context),
        ),
      );
}
