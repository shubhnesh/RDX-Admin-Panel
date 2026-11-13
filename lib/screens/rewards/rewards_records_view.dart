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
          // No leftover gap when the summary cards are not available, so the
          // filter row starts at the same top edge as the sections panel.
          if (provider.analytics != null) ...[
            _transactionSummary(provider),
            SizedBox(height: context.h(12)),
          ],

          // Chips, search and dropdowns share one row (scrolls when narrow).
          LayoutBuilder(
            builder: (context, constraints) {
              final searchHeight = RdxSearchBar.standardHeight(context);
              final dropdownWidth = context.w(170).clamp(150.0, 200.0);

              // No `label` is passed: RdxDropdown only skips its label row
              // (and the 6px gap under it) when `label` is null. An empty
              // string '' still reserves that space. Every control is given
              // the same height so the row lines up with the sections panel.
              final row = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: dropdownWidth,
                    child: RdxDropdown<String>(
                      value: _transactionType ?? 'all',
                      items: ['all', ..._txTypeOptions.keys],
                      labelBuilder: (v) =>
                          v == 'all' ? 'All Types' : (_txTypeOptions[v] ?? v),
                      hint: 'All Types',
                      height: searchHeight,
                      onChanged: (value) => _selectTransactionType(
                        provider,
                        value == null || value == 'all' ? null : value,
                      ),
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  Expanded(
                    child: RdxSearchBar(
                      controller: _transactionSearchController,
                      hintText: 'Search transactions',
                      height: searchHeight,
                      onChanged: (value) => _updateState(() {
                        _transactionSearch = value;
                        f.page = 0;
                      }),
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  SizedBox(
                    width: dropdownWidth,
                    child: RdxDropdown<String>(
                      value: userValue,
                      items: ['all', ...users],
                      labelBuilder: (v) =>
                          v == 'all' ? 'All Users' : _shortId(v),
                      hint: 'All Users',
                      searchable: true,
                      height: searchHeight,
                      onChanged: (value) => _updateState(() {
                        f.user = value ?? 'all';
                        f.page = 0;
                      }),
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  SizedBox(
                    width: dropdownWidth,
                    child: RdxDropdown<String>(
                      value: statusValue,
                      items: ['all', ...statuses],
                      labelBuilder: (v) => v == 'all' ? 'All Status' : v,
                      hint: 'All Status',
                      height: searchHeight,
                      onChanged: (value) => _updateState(() {
                        f.status = value ?? 'all';
                        f.page = 0;
                      }),
                    ),
                  ),
                ],
              );

              final minWidth = context.w(800).clamp(760.0, 950.0);
              return constraints.maxWidth >= minWidth
                  ? row
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(width: minWidth, child: row),
                    );
            },
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

            // The table gets all remaining height, down to the bottom of the
            // screen. Every loaded record is in this one table and it scrolls
            // inside itself.
            Expanded(
              child: _transactionTable(filtered),
            ),

            // Only shown when the server still has older records to fetch.
            if (provider.hasMoreTransactions) ...[
              SizedBox(height: context.h(8)),
              _transactionLoadMore(provider),
            ],
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

  /// Strip describing the records currently in view (after filters).
  /// Four equal cells that span the full row width, styled like the metric
  /// cards above (tinted icon circle, bold value, muted label).
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
    const positive = Color(0xFF138A4A);

    Widget cell({
      required IconData icon,
      required Color accent,
      required String value,
      required String label,
    }) =>
        Row(
          children: [
            Container(
              width: context.w(34),
              height: context.w(34),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: context.h(18)),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.section(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

    final cells = <Widget>[
      cell(
        icon: Icons.receipt_long_rounded,
        accent: AppColors.primary,
        value: _number(filtered.length),
        label: 'Records in view',
      ),
      cell(
        icon: Icons.trending_up_rounded,
        accent: positive,
        value: '+${_number(credits)}',
        label: 'Points credited',
      ),
      cell(
        icon: Icons.trending_down_rounded,
        accent: AppColors.danger,
        value: _number(debits),
        label: 'Points debited',
      ),
      cell(
        icon: Icons.account_balance_wallet_rounded,
        accent: net < 0 ? AppColors.danger : positive,
        value: net > 0 ? '+${_number(net)}' : _number(net),
        label: 'Net points',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(10),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Narrow: 2 x 2 grid. Wide: one row, equal cells with dividers.
          if (constraints.maxWidth < 620) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cells[0]),
                    SizedBox(width: context.w(12)),
                    Expanded(child: cells[1]),
                  ],
                ),
                SizedBox(height: context.h(10)),
                Row(
                  children: [
                    Expanded(child: cells[2]),
                    SizedBox(width: context.w(12)),
                    Expanded(child: cells[3]),
                  ],
                ),
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0)
                    VerticalDivider(
                      width: context.w(24),
                      thickness: 1,
                      color: colors.divider,
                    ),
                  Expanded(child: cells[i]),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Table
  // -------------------------------------------------------------------------

  // Same RdxTable as the Inventory screen: (title, minWidth, flex, sortKey).
  static const List<(String, double, double, String?)> _txColumns = [
    ('DATE & TIME', 150, 1, 'date'),
    ('USER', 160, 1.2, null),
    ('TYPE', 150, 1, null),
    ('POINTS', 110, 0.8, 'points'),
    ('ORDER ID', 170, 1.2, null),
    ('DETAILS', 220, 1.6, null),
    ('STATUS', 130, 1, null),
    ('ACTIONS', 90, 0.6, null),
  ];

  Widget _transactionTable(List<RewardTransaction> items) {
    return RdxTable(
      showFooter: false,
      columns: [
        for (final c in _txColumns)
          RdxTableColumn(
            title: c.$1,
            minWidth: c.$2,
            flex: c.$3,
            header: c.$4 == null ? null : _sortableHeader(c.$1, c.$4!),
          ),
      ],
      rows: items
          .map(
            (item) => <Widget>[
              _plainCell(_date(item.createdAt)),
              _copyCell(item.userId, _shortId(item.userId), 'User ID copied'),
              _transactionTypeBadge(item.type),
              _pointsCell(item.points),
              item.orderId == null || item.orderId!.isEmpty
                  ? _plainCell('—')
                  : _copyCell(item.orderId!, item.orderId!, 'Order ID copied'),
              _transactionDetails(item),
              _transactionStatus(item.status),
              _transactionActions(item),
            ],
          )
          .toList(),
      onRowTap: (index) => _showTransactionDetails(items[index]),
    );
  }

  Widget _plainCell(String text) => Text(
        text,
        style: AppTextStyles.bodySecondary(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

  Widget _copyCell(String fullValue, String label, String toast) => Tooltip(
        message: '$fullValue\n(tap to copy)',
        child: InkWell(
          onTap: () => _copyText(fullValue, toast),
          child: _plainCell(label),
        ),
      );

  /// Sortable header placed inside RdxTableColumn.header.
  Widget _sortableHeader(String title, String key) {
    final colors = AppColors.of(context);
    final f = _txf;
    final active = f.sortField == key;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _updateState(() {
        if (active) {
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
              title,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label(context).copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          SizedBox(width: context.w(3)),
          Icon(
            active
                ? (f.ascending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded)
                : Icons.unfold_more_rounded,
            size: context.h(14),
            color: active ? AppColors.primary : colors.textMuted,
          ),
        ],
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
  // Load more (server-side paging only)
  // -------------------------------------------------------------------------

  Widget _transactionLoadMore(RewardsAdminProvider provider) {
    return Align(
      alignment: Alignment.center,
      child: OutlinedButton.icon(
        onPressed: provider.isLoading
            ? null
            : () => provider.loadTransactions(
                  type: _transactionType,
                  search: _transactionSearch,
                  nextPage: true,
                ),
        icon: const Icon(Icons.expand_more_rounded, size: 18),
        label: Text(provider.isLoading ? 'Loading...' : 'Load more records'),
      ),
    );
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
        'qualified': 'Qualified',
        'reversed': 'Reversed',
        'rejected': 'Rejected',
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
  }) {
    // No section heading — matches Transactions (title lives in the app header).
    final filtersAndBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (headerAction != null)
          Align(
            alignment: Alignment.centerRight,
            child: headerAction,
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final searchHeight = RdxSearchBar.standardHeight(context);
            final dropdownWidth = context.w(170).clamp(150.0, 200.0);
            final filterKeys = filterOptions.keys.toList();

            final row = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: RdxSearchBar(
                    controller: searchController,
                    hintText: searchHint,
                    height: searchHeight,
                    onChanged: onSearch,
                    onSubmitted: (_) => onSearchSubmit(),
                  ),
                ),
                SizedBox(width: context.w(10)),
                SizedBox(
                  width: dropdownWidth,
                  child: RdxDropdown<String>(
                    value: filter ?? 'all',
                    items: ['all', ...filterKeys],
                    labelBuilder: (v) => v == 'all'
                        ? 'All Status'
                        : (filterOptions[v] ?? v),
                    hint: 'All Status',
                    height: searchHeight,
                    onChanged: (value) {
                      if (value == null || value == 'all') {
                        onFilter(null);
                      } else {
                        onFilter(value);
                      }
                    },
                  ),
                ),
              ],
            );

            final minWidth = context.w(520).clamp(480.0, 700.0);
            return constraints.maxWidth >= minWidth
                ? row
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: minWidth, child: row),
                  );
          },
        ),
        if (error != null) ...[
          SizedBox(height: context.h(10)),
          _inlineError(error),
        ],
        // Same gap as Transactions between filter row and content.
        SizedBox(height: context.h(10)),
        if (loading && !hasItems)
          const LoadingIndicator()
        else if (!hasItems)
          EmptyState(message: '$emptyTitle. $emptyMessage')
        else
          table,
        if (onNextPage != null) ...[
          SizedBox(height: context.h(8)),
          Align(
            alignment: Alignment.center,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onNextPage,
              icon: const Icon(Icons.expand_more),
              label: Text(loading ? 'Loading...' : 'Load more'),
            ),
          ),
        ],
      ],
    );

    return _pageList(
      children: [filtersAndBody],
    );
  }

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
  // Redemption / referral tables (same RdxTable design as Transactions)
  // -------------------------------------------------------------------------

  // (title, minWidth, flex)
  static const List<(String, double, double)> _redemptionColumns = [
    ('CUSTOMER', 160, 1.2),
    ('REWARD', 180, 1.3),
    ('POINTS USED', 120, 0.9),
    ('ORDER ID', 160, 1.2),
    ('DATE & TIME', 150, 1),
    ('STATUS', 130, 1),
  ];

  Widget _redemptionTable(List<RewardRedemptionRecord> items) {
    return SizedBox(
      height: context.h(420),
      child: RdxTable(
        showFooter: false,
        columns: [
          for (final c in _redemptionColumns)
            RdxTableColumn(
              title: c.$1,
              minWidth: c.$2,
              flex: c.$3,
            ),
        ],
        rows: items
            .map(
              (item) => <Widget>[
                _copyCell(item.userId, _shortId(item.userId), 'User ID copied'),
                _plainCell(item.rewardName),
                _pointsCell(-item.pointsUsed.abs()), // shown as debit style
                item.orderId == null || item.orderId!.isEmpty
                    ? _plainCell('—')
                    : _copyCell(item.orderId!, item.orderId!, 'Order ID copied'),
                _plainCell(_date(item.createdAt)),
                _transactionStatus(item.status),
              ],
            )
            .toList(),
      ),
    );
  }

  // (title, minWidth, flex)
  static const List<(String, double, double)> _referralColumns = [
    ('REFERRER', 160, 1.2),
    ('REFERRED CUSTOMER', 180, 1.3),
    ('CODE', 130, 1),
    ('STATUS', 120, 0.9),
    ('QUALIFYING ORDER', 160, 1.2),
    ('POINTS AWARDED', 130, 1),
    ('REFERRAL DATE', 150, 1),
  ];

  Widget _referralTable(List<RewardReferralRecord> items) {
    return SizedBox(
      height: context.h(420),
      child: RdxTable(
        showFooter: false,
        columns: [
          for (final c in _referralColumns)
            RdxTableColumn(
              title: c.$1,
              minWidth: c.$2,
              flex: c.$3,
            ),
        ],
        rows: items
            .map(
              (item) => <Widget>[
                _copyCell(
                  item.referrerId,
                  _shortId(item.referrerId),
                  'Referrer ID copied',
                ),
                _copyCell(
                  item.referredUserId,
                  _shortId(item.referredUserId),
                  'Referred user ID copied',
                ),
                _copyCell(item.referralCode, item.referralCode, 'Referral code copied'),
                _transactionStatus(item.status),
                item.qualifyingOrderId == null || item.qualifyingOrderId!.isEmpty
                    ? _plainCell('—')
                    : _copyCell(
                        item.qualifyingOrderId!,
                        item.qualifyingOrderId!,
                        'Order ID copied',
                      ),
                _pointsCell(item.pointsAwarded),
                _plainCell(_date(item.createdAt)),
              ],
            )
            .toList(),
      ),
    );
  }
}
