import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helper/get_current_user_profile.dart';
import 'models/user_profile_model.dart';

class AppColors {
  static const Color primaryBg = Color(0xFF0F1417);
  static const Color surface = Color(0xFF171C1F);
  static const Color surfaceCard = Color(0xFF2B3035);
  static const Color accent = Color(0xFFD35400);
  static const Color textMain = Color(0xFFDEE2E6);
  static const Color textDim = Color(0xFFADB5BD);
  static const Color borderLowContrast = Color(0xFF3E444A);
  static const Color success = Color(0xFF81B29A);
  static const Color warning = Color(0xFFD35400);
  static const Color error = Color(0xFFE07A5F);
}

class InventorySheetScreen extends StatefulWidget {
  const InventorySheetScreen({super.key});

  @override
  State<InventorySheetScreen> createState() => _InventorySheetScreenState();
}

class _InventorySheetScreenState extends State<InventorySheetScreen> {
  static const String _inventoryCollectionName = 'inventory_sheet';
  final TextEditingController _searchController = TextEditingController();
  late final Future<UserProfile?> _currentUserProfileFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentUserProfileFuture = getCurrentUserProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isDesktop = constraints.maxWidth >= 1024;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isMobile),
                  _buildSubHeader(isMobile),
                  _buildSearchBar(isMobile),
                  _buildTableSection(isMobile, isDesktop, constraints.maxWidth),
                  _buildFooterPagination(isMobile),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 20,
        16,
        isMobile ? 16 : 20,
        14,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.textMain,
            splashRadius: 20,
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Stock Management System',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                color: AppColors.textMain,
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: _showNewInventoryItemDialog,
              child: const Row(
                children: [
                  Icon(Icons.add_box_outlined, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'New Intake',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 20,
        18,
        isMobile ? 16 : 20,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOGISTICS CENTRAL / ORGANIZATION INVENTORY SHEET',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<UserProfile?>(
            future: _currentUserProfileFuture,
            builder: (context, snapshot) {
              final organizationName = snapshot.data?.name.trim() ?? '';
              final title = organizationName.isEmpty
                  ? 'Inventory'
                  : '$organizationName Inventory';

              return Text(
                title,
                style: GoogleFonts.montserrat(
                  color: AppColors.textMain,
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 20,
        0,
        isMobile ? 16 : 20,
        16,
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: AppColors.textMain, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by SKU, description, or category...',
            hintStyle: TextStyle(
              color: AppColors.textDim.withValues(alpha: 0.55),
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: AppColors.textDim,
            ),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textDim),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildTableSection(bool isMobile, bool isDesktop, double screenWidth) {
    final horizontalPadding = isMobile ? 16.0 : 20.0;

    if (isDesktop) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          16,
        ),
        child: Center(
          child: SizedBox(
            width: screenWidth - (horizontalPadding * 2),
            child: _buildInventoryTable(),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: isMobile ? 980 : 0),
          child: _buildInventoryTable(),
        ),
      ),
    );
  }

  Widget _buildInventoryTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: _buildInventoryStreamTable(),
    );
  }

  Widget _buildInventoryTableShell(Widget child) {
    return DataTableTheme(
      data: const DataTableThemeData(dividerThickness: 0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: child,
      ),
    );
  }

  Widget _buildInventoryTableBody(
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
  ) {
    final rows = snapshot.data ?? const <Map<String, dynamic>>[];

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Unable to load inventory data.',
            style: TextStyle(color: AppColors.textDim),
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            _searchQuery.trim().isEmpty
                ? 'No inventory items found.'
                : 'No matching inventory items found.',
            style: TextStyle(color: AppColors.textDim),
          ),
        ),
      );
    }

    return DataTable(
      headingRowHeight: 56,
      dataRowMinHeight: 72,
      dataRowMaxHeight: 72,
      horizontalMargin: 20,
      columnSpacing: 24,
      dividerThickness: 0.6,
      border: const TableBorder(
        top: BorderSide.none,
        bottom: BorderSide.none,
        left: BorderSide.none,
        right: BorderSide.none,
        horizontalInside: BorderSide(color: Colors.black),
        verticalInside: BorderSide.none,
      ),
      headingTextStyle: GoogleFonts.montserrat(
        color: AppColors.textDim,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Official Item Name')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Cost (Dinar)')),
        DataColumn(label: Text('Price (Dinar)')),
        DataColumn(label: Text('Quantity')),
        DataColumn(label: Text('Alternative Names & Keywords')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: List<DataRow>.generate(rows.length, (index) {
        final item = rows[index];
        final rowColor = index.isEven
            ? AppColors.surface
            : const Color(0xFF1F2428);

        final docId = _readField(item, const ['__docId']);
        final itemId = _readField(item, const ['id', 'ID']);
        final name = _readField(item, const [
          'official item name',
          'officialItemName',
          'description',
          'sku',
        ]);
        final category = _readField(item, const ['category', 'الفئة']);
        final cost = _formatDinarField(item, const [
          'cost (dinar)',
          'costDinar',
          'cost',
        ]);
        final price = _formatDinarField(item, const [
          'price (dinar)',
          'priceDinar',
          'market',
        ]);
        final quantity = _readQuantity(item, const [
          'quantity',
          'qty',
          'count',
          'الكمية',
        ]);
        final keywords = _readField(item, const [
          'الأسماء البديلة والكلمات المفتاحية',
          'alternative names & keywords',
          'keywords',
        ]);
        final status = _statusFromQuantity(quantity);

        return DataRow(
          color: WidgetStatePropertyAll(rowColor),
          cells: [
            DataCell(
              Text(
                itemId,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: const Color(0xFFE07A5F),
                ),
              ),
            ),
            DataCell(
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            DataCell(
              Text(category, style: const TextStyle(color: AppColors.textMain)),
            ),
            DataCell(
              Text(cost, style: const TextStyle(color: AppColors.textMain)),
            ),
            DataCell(
              Text(price, style: const TextStyle(color: AppColors.textMain)),
            ),
            DataCell(
              Text(
                quantity.toString(),
                style: const TextStyle(color: AppColors.textMain),
              ),
            ),
            DataCell(
              Text(
                keywords,
                style: const TextStyle(color: AppColors.textMain, fontSize: 12),
              ),
            ),
            DataCell(_buildStatusBadge(status)),
            DataCell(
              IconButton(
                tooltip: 'Edit or restock',
                splashRadius: 20,
                icon: const Icon(
                  Icons.edit_note,
                  size: 20,
                  color: AppColors.textDim,
                ),
                onPressed: () => _showInventoryItemDialog(
                  docId: docId.isEmpty ? itemId : docId,
                  existingItem: item,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInventoryStreamTable() {
    return FutureBuilder<String?>(
      future: _organizationId(),
      builder: (context, orgSnapshot) {
        if (orgSnapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!orgSnapshot.hasData || orgSnapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No organization is linked to this account.',
                style: TextStyle(color: AppColors.textDim),
              ),
            ),
          );
        }

        final organizationId = orgSnapshot.data!;
        return _buildInventoryTableShell(
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('organizations')
                .doc(organizationId)
                .collection(_inventoryCollectionName)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Unable to load inventory data.',
                      style: TextStyle(color: AppColors.textDim),
                    ),
                  ),
                );
              }

              final rows =
                  snapshot.data?.docs
                      .map(
                        (doc) => <String, dynamic>{
                          '__docId': doc.id,
                          'id': doc.data()['id'] ?? doc.id,
                          'official item name':
                              doc.data()['official item name'] ??
                              doc.data()['officialItemName'] ??
                              doc.data()['description'] ??
                              doc.data()['sku'] ??
                              '',
                          'category':
                              doc.data()['category'] ??
                              doc.data()['الفئة'] ??
                              '',
                          'cost (dinar)':
                              doc.data()['cost (dinar)'] ??
                              doc.data()['costDinar'] ??
                              doc.data()['cost'] ??
                              '',
                          'price (dinar)':
                              doc.data()['price (dinar)'] ??
                              doc.data()['priceDinar'] ??
                              doc.data()['market'] ??
                              '',
                          'quantity':
                              doc.data()['quantity'] ??
                              doc.data()['qty'] ??
                              doc.data()['count'] ??
                              doc.data()['الكمية'] ??
                              0,
                          'الأسماء البديلة والكلمات المفتاحية':
                              doc.data()['الأسماء البديلة والكلمات المفتاحية'] ??
                              doc.data()['alternative names & keywords'] ??
                              doc.data()['keywords'] ??
                              '',
                        },
                      )
                      .toList() ??
                  const <Map<String, dynamic>>[];

              final filteredRows = rows.where(_matchesSearchQuery).toList();

              return _buildInventoryTableBody(
                AsyncSnapshot<List<Map<String, dynamic>>>.withData(
                  ConnectionState.done,
                  filteredRows,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<String?> _organizationId() async {
    final profile = await _currentUserProfileFuture;
    final organizationId = profile?.organizationId.trim();
    if (organizationId == null || organizationId.isEmpty) {
      return null;
    }
    return organizationId;
  }

  bool _matchesSearchQuery(Map<String, dynamic> item) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final haystack =
        [
              item['id'],
              item['official item name'],
              item['category'],
              item['cost (dinar)'],
              item['price (dinar)'],
              item['quantity'],
              item['الأسماء البديلة والكلمات المفتاحية'],
            ]
            .where((value) => value != null)
            .map((value) => value.toString().toLowerCase());

    return haystack.any((value) => value.contains(query));
  }

  Future<void> _showNewInventoryItemDialog() async {
    await _showInventoryItemDialog();
  }

  Future<void> _showInventoryItemDialog({
    String? docId,
    Map<String, dynamic>? existingItem,
  }) async {
    final organizationId = await _organizationId();
    if (organizationId == null || organizationId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No organization is linked to this account.'),
        ),
      );
      return;
    }

    final isEditing = existingItem != null;
    final nameController = TextEditingController(
      text: _readField(existingItem ?? const {}, const [
        'official item name',
        'officialItemName',
        'description',
        'sku',
      ]),
    );
    final categoryController = TextEditingController(
      text: _readField(existingItem ?? const {}, const ['category', 'الفئة']),
    );
    final costController = TextEditingController(
      text: _formatDinarField(existingItem ?? const {}, const [
        'cost (dinar)',
        'costDinar',
        'cost',
      ]),
    );
    final priceController = TextEditingController(
      text: _formatDinarField(existingItem ?? const {}, const [
        'price (dinar)',
        'priceDinar',
        'market',
      ]),
    );
    final keywordsController = TextEditingController(
      text: _readField(existingItem ?? const {}, const [
        'الأسماء البديلة والكلمات المفتاحية',
        'alternative names & keywords',
        'keywords',
      ]),
    );
    final quantityController = TextEditingController(
      text: _readQuantity(existingItem ?? const {}, const [
        'quantity',
        'qty',
        'count',
        'الكمية',
      ]).toString(),
    );

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var isSaving = false;

        Future<void> saveItem() async {
          final officialItemName = nameController.text.trim();
          final category = categoryController.text.trim();
          final cost = double.tryParse(costController.text.trim()) ?? 0;
          final price = double.tryParse(priceController.text.trim()) ?? 0;
          final keywords = keywordsController.text.trim();
          final quantity = int.tryParse(quantityController.text.trim()) ?? 0;

          if (officialItemName.isEmpty || category.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Official item name and category are required.'),
              ),
            );
            return;
          }

          try {
            if (isSaving) return;
            isSaving = true;

            final collection = FirebaseFirestore.instance
                .collection('organizations')
                .doc(organizationId)
                .collection(_inventoryCollectionName);

            if (isEditing) {
              final targetDocId =
                  docId ?? _readField(existingItem, const ['__docId', 'id']);
              if (targetDocId.isEmpty) {
                throw StateError(
                  'Unable to determine the inventory document id.',
                );
              }

              await collection.doc(targetDocId).set({
                'id': targetDocId,
                'official item name': officialItemName,
                'category': category,
                'cost (dinar)': cost,
                'price (dinar)': price,
                'quantity': quantity,
                'الأسماء البديلة والكلمات المفتاحية': keywords,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            } else {
              final docRef = collection.doc();
              await docRef.set({
                'id': docRef.id,
                'official item name': officialItemName,
                'category': category,
                'cost (dinar)': cost,
                'price (dinar)': price,
                'quantity': quantity,
                'الأسماء البديلة والكلمات المفتاحية': keywords,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }

            if (!mounted || !dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? 'Item updated successfully.'
                      : 'New item added successfully.',
                ),
              ),
            );
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save the inventory item.'),
              ),
            );
          } finally {
            isSaving = false;
          }
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.surface,
          title: Text(
            isEditing ? 'Edit / Restock Item' : 'New Intake',
            style: const TextStyle(color: AppColors.textMain),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(
                  controller: nameController,
                  label: 'Official Item Name',
                ),
                _buildDialogField(
                  controller: categoryController,
                  label: 'Category',
                ),
                _buildDialogField(
                  controller: costController,
                  label: 'Cost (Dinar)',
                  keyboardType: TextInputType.number,
                ),
                _buildDialogField(
                  controller: priceController,
                  label: 'Price (Dinar)',
                  keyboardType: TextInputType.number,
                ),
                _buildDialogField(
                  controller: quantityController,
                  label: 'Quantity',
                  keyboardType: TextInputType.number,
                ),
                _buildDialogField(
                  controller: keywordsController,
                  label: 'Alternative Names & Keywords',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : saveItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: Text(
                isEditing ? 'Save Changes' : 'Add Item',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    categoryController.dispose();
    costController.dispose();
    priceController.dispose();
    keywordsController.dispose();
    quantityController.dispose();
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textMain),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textDim),
          filled: true,
          fillColor: const Color(0xFF161B1E),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4A5055), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF6B737A), width: 1),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4A5055), width: 1),
          ),
        ),
      ),
    );
  }

  String _readField(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _formatDinarField(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      if (value is num) {
        return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  int _readQuantity(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  String _statusFromQuantity(int quantity) {
    if (quantity <= 0) return 'OUT OF STOCK';
    if (quantity < 10) return 'LOW STOCK';
    return 'OPTIMAL';
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'OPTIMAL':
        color = AppColors.success;
        break;
      case 'LOW STOCK':
        color = const Color(0xFFE07A5F);
        break;
      case 'OUT OF STOCK':
        color = const Color(0xFFE04F4F);
        break;
      default:
        color = AppColors.textDim;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFooterPagination(bool isMobile) {
    return const SizedBox(height: 16);
  }
}
