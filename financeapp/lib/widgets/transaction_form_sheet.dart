import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../app_theme.dart';
import '../utils/currency_formatter.dart';

class TransactionFormSheet extends ConsumerStatefulWidget {
  final TransactionModel? existing;
  final String userId;

  const TransactionFormSheet({super.key, this.existing, required this.userId});

  static Future<void> show(BuildContext context, {required String userId, TransactionModel? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFormSheet(existing: existing, userId: userId),
    );
  }

  @override
  ConsumerState<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _isIncome = true;
  DateTime _selectedDate = DateTime.now();
  TransactionCategory _selectedCategory = TransactionCategory.trabalho;
  bool _isLoading = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.existing!;
      _titleCtrl.text = t.title;
      _amountCtrl.text = t.amount.toStringAsFixed(2).replaceAll('.', ',');
      _noteCtrl.text = t.note ?? '';
      _isIncome = t.isIncome;
      _selectedDate = t.date;
      _selectedCategory = t.category;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor inválido')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          title: _titleCtrl.text,
          amount: amount,
          isIncome: _isIncome,
          date: _selectedDate,
          category: _selectedCategory,
          note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        );
        await ref.read(financeProvider(widget.userId).notifier).updateTransaction(updated);
      } else {
        final tx = TransactionModel(
          id: const Uuid().v4(),
          userId: widget.userId,
          title: _titleCtrl.text,
          amount: amount,
          isIncome: _isIncome,
          date: _selectedDate,
          category: _selectedCategory,
          note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        );
        await ref.read(financeProvider(widget.userId).notifier).addTransaction(tx);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Transação atualizada!' : 'Transação adicionada!'),
            backgroundColor: AppTheme.income,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isEditing ? 'Editar Transação' : 'Nova Transação',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        label: 'Receita',
                        icon: Icons.arrow_upward_rounded,
                        isSelected: _isIncome,
                        selectedColor: AppTheme.income,
                        onTap: () => setState(() {
                          _isIncome = true;
                          if (!_isEditing) _selectedCategory = TransactionCategory.trabalho;
                        }),
                      ),
                    ),
                    Expanded(
                      child: _TypeButton(
                        label: 'Despesa',
                        icon: Icons.arrow_downward_rounded,
                        isSelected: !_isIncome,
                        selectedColor: AppTheme.expense,
                        onTap: () => setState(() {
                          _isIncome = false;
                          if (!_isEditing) _selectedCategory = TransactionCategory.alimentacao;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o título';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$) *',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  hintText: '0,00',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o valor';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Color(0xFF757575), size: 20),
                      const SizedBox(width: 12),
                      Text(CurrencyFormatter.formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_rounded, color: AppTheme.primary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TransactionCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: TransactionCategory.values.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text('${cat.emoji} ${cat.label}'));
                }).toList(),
                onChanged: (v) { if (v != null) setState(() => _selectedCategory = v); },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isIncome ? AppTheme.income : AppTheme.expense,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Salvar Alterações' : 'Adicionar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label, required this.icon, required this.isSelected,
    required this.selectedColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF9E9E9E), size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
              fontWeight: FontWeight.w600, fontSize: 14,
            )),
          ],
        ),
      ),
    );
  }
}
