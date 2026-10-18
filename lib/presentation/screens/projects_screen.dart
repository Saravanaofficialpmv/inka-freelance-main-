import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/currency_tax_service.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/project_viewmodel.dart';
import '../widgets/tibsy_refresh_icon.dart';
import '../widgets/app_search_bar.dart';
import '../../core/theme/theme_helper.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';

  static const List<String> _statusFilters = [
    'All',
    'Active',
    'Planning',
    'Completed',
    'On Hold',
    'Cancelled',
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981); // Emerald
      case 'planning':
        return const Color(0xFFFF5722); // Orange
      case 'completed':
        return const Color(0xFF8B5CF6); // Purple
      case 'on hold':
        return const Color(0xFFF59E0B); // Amber
      case 'cancelled':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectProvider);
    final profile = ref.watch(profileProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 0,
    );
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final canPop = context.canPop();

    final filteredProjects = projects.where((p) {
      final matchesStatus = _selectedStatusFilter == 'All' || p.status.toLowerCase() == _selectedStatusFilter.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          p.projectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList().reversed.toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 24.0 : 20.0,
                isWide ? 20.0 : 12.0,
                isWide ? 24.0 : 20.0,
                12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (canPop && !isWide) ...[
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: context.circleBtnBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.cardBorder, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.textPrimary),
                            ),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            'Projects',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/add-project'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF7A50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search & Filter ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 24.0 : 20.0, vertical: 6.0),
              child: AppSearchBar(
                hintText: 'Search projects & clients...',
                onChanged: (v) => setState(() => _searchQuery = v),
                onClear: () => setState(() => _searchQuery = ''),
              ),
            ),

            const SizedBox(height: 8),

            // ── Filter Chips ──
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 20),
                itemCount: _statusFilters.length,
                itemBuilder: (context, index) {
                  final status = _statusFilters[index];
                  final isSelected = _selectedStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedStatusFilter = status);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (context.isDarkMode ? const Color(0xFF332018) : const Color(0xFFFFECE8))
                              : context.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF5722) : context.cardBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFFF5722) : context.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // ── Projects List ──
            Expanded(
              child: TibsyPullToRefresh(
                padding: EdgeInsets.fromLTRB(isWide ? 24 : 20, 0, isWide ? 24 : 20, isWide ? 32 : 100),
                onRefresh: () => syncAndRefreshEntireApp(ref),
                child: filteredProjects.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.folder_open_rounded, size: 56, color: Color(0xFFCBD5E1)),
                              SizedBox(height: 14),
                              Text('No projects found', style: TextStyle(color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final useGrid = constraints.maxWidth >= 680;
                          if (useGrid) {
                            final cardWidth = (constraints.maxWidth - 16) / 2;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: filteredProjects.map((project) {
                                return SizedBox(
                                  width: cardWidth,
                                  child: _buildProjectCard(project, currencyFormat),
                                );
                              }).toList(),
                            );
                          }
                          return Column(
                            children: filteredProjects.map((project) {
                              return _buildProjectCard(project, currencyFormat);
                            }).toList(),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(dynamic project, dynamic currencyFormat) {
    final statusColor = _getStatusColor(project.status);
    final progress = project.budget > 0 ? (project.receivedAmount / project.budget).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/project-details', extra: project),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.projectName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    project.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              project.clientName,
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}% Invoiced',
                  style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${currencyFormat.format(project.receivedAmount)} / ${currencyFormat.format(project.budget)}',
                  style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: context.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
