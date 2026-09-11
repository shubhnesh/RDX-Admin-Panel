// // import 'package:flutter/material.dart';

// // import 'package:rdx_admin/core/theme/text_styles.dart';
// // import '../core/theme/app_colors.dart';
// // import '../core/utils/responsive_size.dart';

// // class RdxTableColumn {
// //   final String title;
// //   final double minWidth;
// //   final double flex;

// //   const RdxTableColumn({
// //     required this.title,
// //     required this.minWidth,
// //     this.flex = 1,
// //   });
// // }

// // class RdxTable extends StatelessWidget {
// //   final List<RdxTableColumn> columns;
// //   final List<List<Widget>> rows;

// //   final double? minTableWidth;
// //   final double? mobileMinTableWidth;
// //   final double? tabletMinTableWidth;

// //   final Widget? footer;

// //   final bool showFooter;
// //   final bool showRowDividers;

// //   const RdxTable({
// //     super.key,
// //     required this.columns,
// //     required this.rows,
// //     this.minTableWidth,
// //     this.mobileMinTableWidth,
// //     this.tabletMinTableWidth,
// //     this.footer,
// //     this.showFooter = false,
// //     this.showRowDividers = true,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     final colors = AppColors.of(context);

// //     return LayoutBuilder(
// //       builder: (context, constraints) {
// //         final width = constraints.maxWidth;

// //         final isMobile = width < 600;
// //         final isTablet = width >= 600 && width < 1000;

// //         final minimumWidth = isMobile
// //             ? (mobileMinTableWidth ?? 760)
// //             : isTablet
// //                 ? (tabletMinTableWidth ?? 790)
// //                 : (minTableWidth ?? 0);

// //         final tableWidth = isMobile || isTablet ? minimumWidth : width;

// //         return Container(
// //           width: double.infinity,
// //           decoration: BoxDecoration(
// //             color: colors.surface,
// //             borderRadius: BorderRadius.circular(14),
// //             border: Border.all(
// //               color: colors.border,
// //             ),
// //           ),
// //           clipBehavior: Clip.antiAlias,
// //           child: Column(
// //             children: [
// //               LayoutBuilder(
// //                 builder: (context, constraints) {
// //                   final effectiveWidth = constraints.maxWidth < tableWidth
// //                       ? tableWidth
// //                       : constraints.maxWidth;

// //                   return SingleChildScrollView(
// //                     scrollDirection: Axis.horizontal,
// //                     physics: const ClampingScrollPhysics(),
// //                     child: SizedBox(
// //                       width: effectiveWidth,
// //                       child: Column(
// //                         children: [
// //                           _buildHeader(
// //                             context,
// //                             colors,
// //                             effectiveWidth,
// //                           ),
// //                           Divider(
// //                             height: 1,
// //                             thickness: 1,
// //                             color: colors.divider,
// //                           ),
// //                           for (int i = 0; i < rows.length; i++) ...[
// //                             _buildRow(
// //                               context,
// //                               rows[i],
// //                               effectiveWidth,
// //                             ),
// //                             if (showRowDividers && i != rows.length - 1)
// //                               Divider(
// //                                 height: 1,
// //                                 thickness: 1,
// //                                 color: colors.divider,
// //                               ),
// //                           ],
// //                         ],
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               ),
// //               if (showFooter && footer != null) ...[
// //                 Divider(
// //                   height: 1,
// //                   thickness: 1,
// //                   color: colors.divider,
// //                 ),
// //                 footer!,
// //               ],
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   Widget _buildHeader(
// //     BuildContext context,
// //     AppColorScheme colors,
// //     double tableWidth,
// //   ) {
// //     final widths = _calculateWidths(tableWidth);

// //     return Container(
// //       height: 46,
// //       padding: const EdgeInsets.symmetric(
// //         horizontal: 18,
// //       ),
// //       color: colors.surfaceVariant.withOpacity(0.35),
// //       child: Row(
// //         children: [
// //           for (int i = 0; i < columns.length; i++)
// //             SizedBox(
// //               width: widths[i],
// //               child: Text(
// //                 columns[i].title,
// //                 maxLines: 1,
// //                 overflow: TextOverflow.ellipsis,
// //                 style: AppTextStyles.section(context).copyWith(
// //                   color: colors.textMuted,
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildRow(
// //     BuildContext context,
// //     List<Widget> cells,
// //     double tableWidth,
// //   ) {
// //     final widths = _calculateWidths(tableWidth);

// //     return Container(
// //       constraints: const BoxConstraints(
// //         minHeight: 72,
// //       ),
// //       padding: const EdgeInsets.symmetric(
// //         horizontal: 18,
// //         vertical: 11,
// //       ),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.center,
// //         children: [
// //           for (int i = 0; i < columns.length; i++)
// //             SizedBox(
// //               width: widths[i],
// //               child: cells[i],
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   List<double> _calculateWidths(double tableWidth) {
// //     const horizontalPadding = 36.0;

// //     final availableWidth = tableWidth - horizontalPadding;

// //     final minimumTotal = columns.fold<double>(
// //       0,
// //       (sum, column) => sum + column.minWidth,
// //     );

// //     if (availableWidth <= minimumTotal) {
// //       return columns.map((column) => column.minWidth).toList();
// //     }

// //     final extra = availableWidth - minimumTotal;

// //     final totalFlex = columns.fold<double>(
// //       0,
// //       (sum, column) => sum + column.flex,
// //     );

// //     return columns.map((column) {
// //       return column.minWidth + extra * (column.flex / totalFlex);
// //     }).toList();
// //   }
// // }

// import 'package:flutter/material.dart';

// import 'package:rdx_admin/core/theme/text_styles.dart';

// import '../core/theme/app_colors.dart';

// class RdxTableColumn {
//   final String title;
//   final double minWidth;
//   final double flex;

//   const RdxTableColumn({
//     required this.title,
//     required this.minWidth,
//     this.flex = 1,
//   });
// }

// class RdxTable extends StatelessWidget {
//   final List<RdxTableColumn> columns;
//   final List<List<Widget>> rows;

//   final double? minTableWidth;
//   final double? mobileMinTableWidth;
//   final double? tabletMinTableWidth;

//   final Widget? footer;
//   final bool showFooter;
//   final bool showRowDividers;

//   const RdxTable({
//     super.key,
//     required this.columns,
//     required this.rows,
//     this.minTableWidth,
//     this.mobileMinTableWidth,
//     this.tabletMinTableWidth,
//     this.footer,
//     this.showFooter = false,
//     this.showRowDividers = true,
//   })  : assert(
//           columns.length > 0,
//           'RdxTable requires at least one column.',
//         ),
//         assert(
//           showFooter == false || footer != null,
//           'footer must be provided when showFooter is true.',
//         );

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final availableWidth = constraints.maxWidth;

//         final bool isMobile = availableWidth < 600;
//         final bool isTablet = availableWidth >= 600 && availableWidth < 1000;

//         final double minimumTableWidth;

//         if (isMobile) {
//           minimumTableWidth = mobileMinTableWidth ?? 760;
//         } else if (isTablet) {
//           minimumTableWidth = tabletMinTableWidth ?? 790;
//         } else {
//           minimumTableWidth = minTableWidth ?? 0;
//         }

//         final double tableWidth;

//         if (isMobile || isTablet) {
//           tableWidth = minimumTableWidth;
//         } else {
//           tableWidth = availableWidth < minimumTableWidth
//               ? minimumTableWidth
//               : availableWidth;
//         }

//         return Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: colors.surface,
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(
//               color: colors.border,
//             ),
//           ),
//           clipBehavior: Clip.antiAlias,
//           child: Column(
//             children: [
//               LayoutBuilder(
//                 builder: (context, innerConstraints) {
//                   final effectiveWidth = innerConstraints.maxWidth < tableWidth
//                       ? tableWidth
//                       : innerConstraints.maxWidth;

//                   return SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     physics: const ClampingScrollPhysics(),
//                     child: SizedBox(
//                       width: effectiveWidth,
//                       child: Column(
//                         children: [
//                           _buildHeader(
//                             context,
//                             colors,
//                             effectiveWidth,
//                           ),
//                           Divider(
//                             height: 1,
//                             thickness: 1,
//                             color: colors.divider,
//                           ),
//                           for (int index = 0; index < rows.length; index++) ...[
//                             _buildRow(
//                               context,
//                               rows[index],
//                               effectiveWidth,
//                             ),
//                             if (showRowDividers && index != rows.length - 1)
//                               Divider(
//                                 height: 1,
//                                 thickness: 1,
//                                 color: colors.divider,
//                               ),
//                           ],
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//               if (showFooter && footer != null) ...[
//                 Divider(
//                   height: 1,
//                   thickness: 1,
//                   color: colors.divider,
//                 ),
//                 footer!,
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHeader(
//     BuildContext context,
//     AppColorScheme colors,
//     double tableWidth,
//   ) {
//     final widths = _calculateWidths(tableWidth);

//     return Container(
//       height: 46,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 18,
//       ),
//       color: colors.surfaceVariant.withOpacity(0.35),
//       child: Row(
//         children: [
//           for (int index = 0; index < columns.length; index++)
//             SizedBox(
//               width: widths[index],
//               child: Text(
//                 columns[index].title,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: AppTextStyles.section(context).copyWith(
//                   color: colors.primary,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRow(
//     BuildContext context,
//     List<Widget> cells,
//     double tableWidth,
//   ) {
//     final widths = _calculateWidths(tableWidth);

//     return Container(
//       constraints: const BoxConstraints(
//         minHeight: 72,
//       ),
//       padding: const EdgeInsets.symmetric(
//         horizontal: 18,
//         vertical: 11,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           for (int index = 0; index < columns.length; index++)
//             SizedBox(
//               width: widths[index],
//               child: cells[index],
//             ),
//         ],
//       ),
//     );
//   }

//   // List<double> _calculateWidths(double tableWidth) {
//   //   const horizontalPadding = 36.0;

//   //   final availableWidth = tableWidth - horizontalPadding;

//   //   final minimumTotal = columns.fold<double>(
//   //     0,
//   //     (sum, column) => sum + column.minWidth,
//   //   );

//   //   if (availableWidth <= minimumTotal) {
//   //     return columns.map((column) => column.minWidth).toList(growable: false);
//   //   }

//   //   final extraWidth = availableWidth - minimumTotal;

//   //   final totalFlex = columns.fold<double>(
//   //     0,
//   //     (sum, column) => sum + column.flex,
//   //   );

//   //   if (totalFlex <= 0) {
//   //     return columns.map((column) => column.minWidth).toList(growable: false);
//   //   }

//   //   return columns.map((column) {
//   //     return column.minWidth + extraWidth * (column.flex / totalFlex);
//   //   }).toList(growable: false);
//   // }

//   List<double> _calculateWidths(double tableWidth) {
//     const horizontalPadding = 36.0;
//     final availableWidth = tableWidth - horizontalPadding;

//     final minimumTotal = columns.fold<double>(
//       0,
//       (sum, column) => sum + column.minWidth,
//     );

//     // If the table is smaller than the combined minimum widths,
//     // keep the minimum widths and allow the parent horizontal scroll
//     // to handle the overflow.
//     if (availableWidth <= minimumTotal) {
//       return columns.map((column) => column.minWidth).toList();
//     }

//     final extra = availableWidth - minimumTotal;

//     final totalFlex = columns.fold<double>(
//       0,
//       (sum, column) => sum + column.flex,
//     );

//     return columns.map((column) {
//       return column.minWidth + (extra * column.flex / totalFlex);
//     }).toList();
//   }
// }

// /// Reusable action button for RdxTable rows.
// class RdxTableActionButton extends StatelessWidget {
//   final IconData icon;
//   final String tooltip;
//   final VoidCallback? onPressed;

//   const RdxTableActionButton({
//     super.key,
//     required this.icon,
//     required this.tooltip,
//     this.onPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     return Tooltip(
//       message: tooltip,
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onPressed,
//           borderRadius: BorderRadius.circular(6),
//           child: Container(
//             width: 32,
//             height: 32,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Icon(
//               icon,
//               size: 16,
//               color: colors.textMuted,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

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
