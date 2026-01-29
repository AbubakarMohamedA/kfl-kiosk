import 'package:equatable/equatable.dart';

/// Domain entity for order filtering criteria
class OrderFilter extends Equatable {
  final String? statusFilter;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showOnlyActive;

  const OrderFilter({
    this.statusFilter,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.showOnlyActive = true,
  });

  const OrderFilter.all() : this(statusFilter: 'all', showOnlyActive: true);

  const OrderFilter.history() : this(showOnlyActive: false);

  OrderFilter copyWith({
    String? statusFilter,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    bool? showOnlyActive,
  }) {
    return OrderFilter(
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      showOnlyActive: showOnlyActive ?? this.showOnlyActive,
    );
  }

  bool get hasFilters =>
      searchQuery?.isNotEmpty == true ||
      statusFilter != null && statusFilter != 'all' ||
      startDate != null ||
      endDate != null;

  @override
  List<Object?> get props => [
        statusFilter,
        searchQuery,
        startDate,
        endDate,
        showOnlyActive,
      ];
}