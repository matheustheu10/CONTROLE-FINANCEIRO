import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/news_provider.dart';
import '../../widgets/transaction_form_sheet.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da conta?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expense,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/auth');
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TransactionModel tx, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir transação'),
        content: Text('Deseja excluir "${tx.title}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expense,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(financeProvider(userId).notifier).deleteTransaction(tx.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação excluída'), backgroundColor: AppTheme.expense),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final financeState = ref.watch(financeProvider(userId));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Buscar transações...',
                  hintStyle: TextStyle(color: Color(0xFFA5D6A7)),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => ref.read(financeProvider(userId).notifier).setSearch(v),
              )
            : Text('Olá, ${user?.displayName?.split(' ').first ?? 'usuário'} 👋'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchCtrl.clear();
                ref.read(financeProvider(userId).notifier).setSearch('');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.pushNamed(context, '/analysis'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: financeState.isLoading
          ? _SkeletonLoader()
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () => ref.read(financeProvider(userId).notifier).loadTransactions(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _BalanceSection(state: financeState)),
                  SliverToBoxAdapter(child: _FilterBar(userId: userId)),
                  SliverToBoxAdapter(child: _NewsSection()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Transações',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('${financeState.filtered.length} registro(s)',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
                        ],
                      ),
                    ),
                  ),
                  financeState.filtered.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_long_rounded, size: 64, color: Color(0xFFBDBDBD)),
                                const SizedBox(height: 16),
                                const Text('Nenhuma transação ainda',
                                    style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E))),
                                const SizedBox(height: 8),
                                const Text('Toque em "Adicionar" para começar',
                                    style: TextStyle(fontSize: 14, color: Color(0xFFBDBDBD))),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final tx = financeState.filtered[i];
                              return _TransactionTile(
                                tx: tx,
                                onEdit: () => TransactionFormSheet.show(ctx, userId: userId, existing: tx),
                                onDelete: () => _confirmDelete(ctx, tx, userId),
                              );
                            },
                            childCount: financeState.filtered.length,
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TransactionFormSheet.show(context, userId: userId),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar'),
      ),
    );
  }
}

// ─── SKELETON LOADER ─────────────────────────────────────────────────────────

class _SkeletonLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SkeletonBox(height: 160, radius: 20),
          const SizedBox(height: 16),
          _SkeletonBox(height: 40, radius: 12),
          const SizedBox(height: 16),
          ...List.generate(4, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SkeletonBox(height: 72, radius: 16),
          )),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double height;
  final double radius;
  const _SkeletonBox({required this.height, required this.radius});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ─── NEWS SECTION ─────────────────────────────────────────────────────────────

class _NewsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);

    return news.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Notícias Financeiras',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            _SkeletonBox(height: 80, radius: 12),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (articles) {
        if (articles.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notícias Financeiras',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final a = articles[i];
                    return GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 240,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.source,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF212121),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ─── BALANCE SECTION ──────────────────────────────────────────────────────────

class _BalanceSection extends StatelessWidget {
  final FinanceState state;
  const _BalanceSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saldo Atual',
              style: TextStyle(color: Color(0xFFA5D6A7), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(state.balance),
            style: TextStyle(
              color: state.balance >= 0 ? Colors.white : const Color(0xFFFF8A80),
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  label: 'Receitas',
                  value: state.totalIncome,
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFF81C784),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniCard(
                  label: 'Despesas',
                  value: state.totalExpense,
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFFFF8A80),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _MiniCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
                Text(CurrencyFormatter.format(value),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FILTER BAR ───────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  final String userId;
  const _FilterBar({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(financeProvider(userId)).filter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _Chip(label: 'Todos', isSelected: filter == FilterType.all,
              onTap: () => ref.read(financeProvider(userId).notifier).setFilter(FilterType.all)),
          const SizedBox(width: 8),
          _Chip(label: 'Receitas', isSelected: filter == FilterType.income,
              selectedColor: AppTheme.income,
              onTap: () => ref.read(financeProvider(userId).notifier).setFilter(FilterType.income)),
          const SizedBox(width: 8),
          _Chip(label: 'Despesas', isSelected: filter == FilterType.expense,
              selectedColor: AppTheme.expense,
              onTap: () => ref.read(financeProvider(userId).notifier).setFilter(FilterType.expense)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.isSelected, this.selectedColor = AppTheme.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? selectedColor : const Color(0xFFE0E0E0)),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF757575),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            )),
      ),
    );
  }
}

// ─── TRANSACTION TILE ─────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionTile({required this.tx, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.expense, borderRadius: BorderRadius.circular(16)),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white),
            Text('Excluir', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      confirmDismiss: (_) async { onDelete(); return false; },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: tx.isIncome ? AppTheme.incomeLight : AppTheme.expenseLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(tx.category.emoji, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('${tx.category.label} · ${CurrencyFormatter.formatDate(tx.date)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                    ],
                  ),
                ),
                Text(
                  '${tx.isIncome ? '+' : '-'} ${CurrencyFormatter.format(tx.amount)}',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: tx.isIncome ? AppTheme.income : AppTheme.expense,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
