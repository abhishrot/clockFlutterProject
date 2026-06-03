import 'package:flutter/material.dart';

class Product {
  final int productId;
  final String productName;
  final String available;

  Product({
    required this.productId,
    required this.productName,
    required this.available,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      available: json['available'] ?? 'No',
    );
  }
}

class ApiScreen extends StatefulWidget {
  const ApiScreen({
    super.key,
    required this.products,
    required this.userEmail,
  });

  final List<Product> products;
  final String userEmail;

  @override
  State<ApiScreen> createState() => _ApiScreenState();
}

// Typedef to support the exact naming requested by the user
typedef API_Screen = ApiScreen;

class _ApiScreenState extends State<ApiScreen> {
  late List<Product> _filteredProducts;
  final _searchController = TextEditingController();

  bool _sortAscending = true;
  int? _sortColumnIndex;

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(widget.products);
    _searchController.addListener(_filterAndSortProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAndSortProducts() {
    final query = _searchController.text.toLowerCase();
    var filtered = widget.products
        .where((p) => p.productName.toLowerCase().contains(query))
        .toList();

    if (_sortColumnIndex != null) {
      final index = _sortColumnIndex!;
      final asc = _sortAscending;
      filtered.sort((a, b) {
        int comparison;
        if (index == 0) {
          comparison = a.productId.compareTo(b.productId);
        } else if (index == 1) {
          comparison = a.productName.toLowerCase().compareTo(b.productName.toLowerCase());
        } else {
          comparison = a.available.toLowerCase().compareTo(b.available.toLowerCase());
        }
        return asc ? comparison : -comparison;
      });
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _sortProducts(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
    _filterAndSortProducts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome User Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Welcome, ${widget.userEmail}',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Search Input Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Responsive Table of products
              Expanded(
                child: _filteredProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: DataTable(
                                    sortColumnIndex: _sortColumnIndex,
                                    sortAscending: _sortAscending,
                                    headingRowColor: WidgetStateProperty.all(
                                      isDark 
                                          ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5) 
                                          : theme.colorScheme.primaryContainer.withOpacity(0.2),
                                    ),
                                    headingTextStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.grey[200] : theme.colorScheme.primary,
                                    ),
                                    columns: [
                                      DataColumn(
                                        numeric: true,
                                        label: const Text('ID'),
                                        onSort: (columnIndex, ascending) => _sortProducts(columnIndex, ascending),
                                      ),
                                      DataColumn(
                                        label: const Text('Product Name'),
                                        onSort: (columnIndex, ascending) => _sortProducts(columnIndex, ascending),
                                      ),
                                      DataColumn(
                                        label: const Text('Availability'),
                                        onSort: (columnIndex, ascending) => _sortProducts(columnIndex, ascending),
                                      ),
                                    ],
                                    rows: _filteredProducts.map((product) {
                                      final isAvailable = product.available.toLowerCase() == 'yes';
                                      return DataRow(
                                        cells: [
                                          // ID cell
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${product.productId}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.onSecondaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Name cell
                                          DataCell(
                                            Text(
                                              product.productName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          // Availability cell
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isAvailable
                                                    ? Colors.green.withOpacity(0.15)
                                                    : Colors.red.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: isAvailable
                                                      ? Colors.green.withOpacity(0.3)
                                                      : Colors.red.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                isAvailable ? 'Available' : 'Out of Stock',
                                                style: TextStyle(
                                                  color: isAvailable
                                                      ? (isDark ? Colors.green[300] : Colors.green[800])
                                                      : (isDark ? Colors.red[300] : Colors.red[800]),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
