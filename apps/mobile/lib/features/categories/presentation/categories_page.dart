import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  CategoryType type = CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(allCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('分类管理')),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-category'),
        onPressed: () => _showCategoryDialog(context, type: type),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<CategoryType>(
              segments: const [
                ButtonSegment(value: CategoryType.expense, label: Text('支出')),
                ButtonSegment(value: CategoryType.income, label: Text('收入')),
              ],
              selected: {type},
              onSelectionChanged: (value) =>
                  setState(() => type = value.single),
            ),
          ),
          Expanded(
            child: categories.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (items) => ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                children: items
                    .where((item) => item.type == type)
                    .map(
                      (item) => Card(
                        child: ListTile(
                          key: Key('category-${item.id}'),
                          title: Text(item.name),
                          subtitle: item.systemKey == null
                              ? null
                              : const Text('内置分类'),
                          onTap: () => _showCategoryDialog(
                            context,
                            type: type,
                            category: item,
                          ),
                          trailing: Switch(
                            key: Key('category-enabled-${item.id}'),
                            value: item.enabled,
                            onChanged: (value) => ref
                                .read(saveCategoryUseCaseProvider)
                                .setEnabled(item.id, value),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCategoryDialog(
  BuildContext context, {
  required CategoryType type,
  LedgerCategory? category,
}) => showDialog<void>(
  context: context,
  builder: (_) => _CategoryDialog(type: type, category: category),
);

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog({required this.type, this.category});

  final CategoryType type;
  final LedgerCategory? category;

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  late final TextEditingController name;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? '新增分类' : '编辑分类'),
      content: TextField(
        key: const Key('category-name'),
        controller: name,
        autofocus: true,
        decoration: const InputDecoration(labelText: '名称'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('save-category'),
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    try {
      final useCase = ref.read(saveCategoryUseCaseProvider);
      if (widget.category == null) {
        await useCase.create(name: name.text, type: widget.type);
      } else {
        await useCase.update(id: widget.category!.id, name: name.text);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
