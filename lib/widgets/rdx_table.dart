import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/text_styles.dart';

class RdxTableColumn {
  final String title;
  final double minWidth;
  final double flex;

  const RdxTableColumn({
    required this.title,
    required this.minWidth,
    this.flex = 1,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Width required by the columns themselves.
        final minimumTableWidth = _minimumTableWidth;

        // If the screen is wide enough, table fills the available space.
        // Otherwise the table gets its calculated minimum width and
        // SingleChildScrollView handles horizontal scrolling.
        final tableWidth = availableWidth >= minimumTableWidth
            ? availableWidth
            : minimumTableWidth;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
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
                                    rows[index],
                                    tableWidth,
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

  double get _minimumTableWidth {
    const horizontalPadding = 36.0;

    return columns.fold<double>(
          0,
          (sum, column) => sum + column.minWidth,
        ) +
        horizontalPadding;
  }

  Widget _buildHeader(
    BuildContext context,
    AppColorScheme colors,
    double tableWidth,
  ) {
    final widths = _calculateWidths(tableWidth);

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: colors.surfaceVariant.withOpacity(0.35),
      child: Row(
        children: [
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Text(
                columns[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    List<Widget> cells,
    double tableWidth,
  ) {
    final widths = _calculateWidths(tableWidth);

    return Container(
      constraints: const BoxConstraints(
        minHeight: 72,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 11,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: cells[i],
            ),
        ],
      ),
    );
  }

  List<double> _calculateWidths(double tableWidth) {
    const horizontalPadding = 36.0;
    final availableWidth = tableWidth - horizontalPadding;

    final minimumTotal = columns.fold<double>(
      0,
      (sum, column) => sum + column.minWidth,
    );

    if (availableWidth <= minimumTotal) {
      return columns.map((column) => column.minWidth).toList();
    }

    final extraWidth = availableWidth - minimumTotal;

    final totalFlex = columns.fold<double>(
      0,
      (sum, column) => sum + column.flex,
    );

    return columns.map((column) {
      return column.minWidth + extraWidth * (column.flex / totalFlex);
    }).toList();
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

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: Icon(
                icon,
                size: 16,
                color: colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
