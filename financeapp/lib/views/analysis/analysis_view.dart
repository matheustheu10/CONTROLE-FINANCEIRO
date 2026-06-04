import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';
import '../../viewmodels/finance_viewmodel.dart';

class AnalysisView extends StatelessWidget {
  const AnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise Financeira'),
        leading: const BackButton(),
      ),
      body: Consumer<FinanceViewModel>(
        builder: (_, vm, __) {
          if (vm.allTransactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 64, color: Color(0xFFBDBDBD)),
                  SizedBox(height: 12),
                  Text(
                    'Nenhuma transação para analisar',
                    style:
                        TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Period Summary ──
                _SectionHeader(title: 'Resumo do Período'),
                const SizedBox(height: 12),
                _SummaryCard(vm: vm),
                const SizedBox(height: 24),

                // ── Category Breakdown ──
                if (vm.expenseByCategory.isNotEmpty) ...[
                  _SectionHeader(title: 'Despesas por Categoria'),
                  const SizedBox(height: 12),
                  _CategoryBreakdown(vm: vm),
                  const SizedBox(height: 24),
                ],

                // ── All Transactions ──
                _SectionHeader(
                  title: 'Todas as Movimentações',
                  subtitle: '${vm.allTransactions.length} registros',
                ),
                const SizedBox(height: 12),
                _TransactionsList(transactions: vm.allTransactions),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── SECTION HEADER ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF212121),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
          ),
        ],
      ],
    );
  }
}

// ─── SUMMARY CARD ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final FinanceViewModel vm;

  const _SummaryCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final total = vm.totalIncome + vm.totalExpense;
    final incomeRatio = total == 0 ? 0.0 : vm.totalIncome / total;
    final expenseRatio = total == 0 ? 0.0 : vm.totalExpense / total;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ProgressRow(
            icon: Icons.trending_up_rounded,
            label: 'Receitas',
            value: vm.totalIncome,
            progress: incomeRatio,
            color: AppTheme.income,
            percentage: '${(incomeRatio * 100).toStringAsFixed(1)}% do total',
          ),
          const SizedBox(height: 20),
          _ProgressRow(
            icon: Icons.trending_down_rounded,
            label: 'Despesas',
            value: vm.totalExpense,
            progress: expenseRatio,
            color: AppTheme.expense,
            percentage: '${(expenseRatio * 100).toStringAsFixed(1)}% do total',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Líquido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              Text(
                CurrencyFormatter.format(vm.balance),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: vm.balance >= 0
                      ? AppTheme.income
                      : AppTheme.expense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double progress;
  final Color color;
  final String percentage;

  const _ProgressRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
            Text(
              CurrencyFormatter.format(value),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          percentage,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}

// ─── CATEGORY BREAKDOWN ──────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final FinanceViewModel vm;

  const _CategoryBreakdown({required this.vm});

  @override
  Widget build(BuildContext context) {
    final map = vm.expenseByCategory;
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: sorted.map((entry) {
          final ratio = entry.value / maxVal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.key.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(entry.value),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.expense,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.expense),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── TRANSACTIONS LIST ───────────────────────────────────────────────────────

class _TransactionsList extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _TransactionsList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) {
          final tx = transactions[i];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tx.isIncome
                    ? AppTheme.incomeLight
                    : AppTheme.expenseLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(tx.category.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            title: Text(
              tx.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${tx.category.label} · ${CurrencyFormatter.formatDate(tx.date)}',
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
            trailing: Text(
              '${tx.isIncome ? '+' : '-'} ${CurrencyFormatter.format(tx.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: tx.isIncome ? AppTheme.income : AppTheme.expense,
              ),
            ),
          );
        },
      ),
    );
  }
}
