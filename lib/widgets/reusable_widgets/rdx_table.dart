import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';

class RdxTableColumn {
  /// Logical design width (scaled at runtime via [context.w]).
  final double minWidth;

  /// Share of leftover horizontal space after min widths are applied.
  final double flex;

  final String title;
  final Alignment alignment;

  const RdxTableColumn({
    required this.title,
    required this.minWidth,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });
}

class RdxTable extends StatelessWidget {
  final List<RdxTableColumn> columns;
  final List<List<Widget>> rows;
  final Widget? footer;
  final bool showFooter;
  final bool showRowDividers;

  const RdxTable({
    super.key,
    required this.columns,
    required this.rows,
    this.footer,
    this.showFooter = false,
    this.showRowDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isNarrow = Responsive.isNarrow(context);
    final isMobile = Responsive.isMobile(context);

    // All layout metrics scale with screen size.
    final horizontalPadding = isMobile
        ? context.w(12)
        : isNarrow
            ? context.w(14)
            : context.w(18);
    final headerHeight = isMobile ? context.h(40) : context.h(46);
    final rowMinHeight = isMobile ? context.h(60) : context.h(72);
    final rowVerticalPadding = isMobile ? context.h(8) : context.h(11);
    final radius = context.h(14);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final minimumTableWidth = _minimumTableWidth(context);

        final tableWidth = availableWidth >= minimumTableWidth
            ? availableWidth
            : minimumTableWidth;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        _buildHeader(
                          context,
                          colors,
                          tableWidth,
                          headerHeight: headerHeight,
                          horizontalPadding: horizontalPadding,
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colors.divider,
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: rows.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  _buildRow(
                                    context,
                                    colors,
                                    rows[index],
                                    tableWidth,
                                    rowMinHeight: rowMinHeight,
                                    horizontalPadding: horizontalPadding,
                                    verticalPadding: rowVerticalPadding,
                                  ),
                                  if (showRowDividers &&
                                      index != rows.length - 1)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: colors.divider,
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (showFooter && footer != null) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.divider,
                ),
                footer!,
              ],
            ],
          ),
        );
      },
    );
  }

  /// Responsive pixel min-width for a column (design value → scaled).
  double _scaledMinWidth(BuildContext context, RdxTableColumn column) {
    // context.w already scales with screen width.
    // On very small phones, apply an extra slight compression so more
    // columns fit before horizontal scroll is required.
    final base = context.w(column.minWidth);
    if (Responsive.isMobile(context)) {
      return base * 0.9;
    }
    if (Responsive.isNarrow(context)) {
      return base * 0.95;
    }
    return base;
  }

  double _minimumTableWidth(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isNarrow = Responsive.isNarrow(context);
    final horizontalPadding = isMobile
        ? context.w(24)
        : isNarrow
            ? context.w(28)
            : context.w(36);

    return columns.fold<double>(
          0,
          (sum, column) => sum + _scaledMinWidth(context, column),
        ) +
        horizontalPadding;
  }

  List<double> _calculateWidths(BuildContext context, double tableWidth) {
    final isMobile = Responsive.isMobile(context);
    final isNarrow = Responsive.isNarrow(context);
    final horizontalPadding = isMobile
        ? context.w(24)
        : isNarrow
            ? context.w(28)
            : context.w(36);

    final availableWidth = tableWidth - horizontalPadding;

    final scaledMins =
        columns.map((c) => _scaledMinWidth(context, c)).toList();
    final minimumTotal = scaledMins.fold<double>(0, (sum, w) => sum + w);

    if (availableWidth <= minimumTotal) {
      return scaledMins;
    }

    final extraWidth = availableWidth - minimumTotal;
    final totalFlex = columns.fold<double>(
      0,
      (sum, column) => sum + column.flex,
    );

    if (totalFlex == 0) {
      return scaledMins;
    }

    return [
      for (int i = 0; i < columns.length; i++)
        scaledMins[i] + extraWidth * (columns[i].flex / totalFlex),
    ];
  }

  Widget _buildHeader(
    BuildContext context,
    AppColorScheme colors,
    double tableWidth, {
    required double headerHeight,
    required double horizontalPadding,
  }) {
    final widths = _calculateWidths(context, tableWidth);

    return Container(
      height: headerHeight,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      color: colors.surfaceVariant.withOpacity(0.35),
      child: Row(
        children: [
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Align(
                alignment: columns[i].alignment,
                child: Text(
                  columns[i].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textMuted,
                    fontSize: Responsive.isMobile(context) ? 12 : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    AppColorScheme colors,
    List<Widget> cells,
    double tableWidth, {
    required double rowMinHeight,
    required double horizontalPadding,
    required double verticalPadding,
  }) {
    final widths = _calculateWidths(context, tableWidth);

    return Container(
      constraints: BoxConstraints(minHeight: rowMinHeight),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      color: colors.surfaceVariant,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Align(
                alignment: columns[i].alignment,
                child: cells[i],
              ),
            ),
        ],
      ),
    );
  }
}

class RdxTableActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const RdxTableActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final size = Responsive.isMobile(context) ? context.w(28) : context.w(32);
    final iconSize =
        Responsive.isMobile(context) ? context.h(20) : context.h(22);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(context.h(6)),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RdxTableMoreButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final double? size;
  final double? iconSize;
  final Color? iconColor;
  final Color? hoverColor;

  const RdxTableMoreButton({
    super.key,
    this.tooltip = 'More',
    this.onPressed,
    this.icon = Icons.more_vert_rounded,
    this.size,
    this.iconSize,
    this.iconColor,
    this.hoverColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final resolvedSize =
        size ?? (Responsive.isMobile(context) ? context.w(28) : context.w(32));
    final resolvedIconSize = iconSize ??
        (Responsive.isMobile(context) ? context.h(18) : context.h(20));

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(context.h(6)),
          hoverColor: hoverColor ?? colors.surfaceVariant,
          child: SizedBox(
            width: resolvedSize,
            height: resolvedSize,
            child: Center(
              child: Icon(
                icon,
                size: resolvedIconSize,
                color: iconColor ?? colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}