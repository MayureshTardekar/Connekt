import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/campus_model.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../theme/app_theme.dart';

class CampusSelectionScreen extends ConsumerStatefulWidget {
  const CampusSelectionScreen({super.key});

  @override
  ConsumerState<CampusSelectionScreen> createState() =>
      _CampusSelectionScreenState();
}

class _CampusSelectionScreenState extends ConsumerState<CampusSelectionScreen> {
  final _searchController = TextEditingController();
  final _campusNameController = TextEditingController();
  final _uidController = TextEditingController();
  final _customCourseController = TextEditingController();
  final _customBranchController = TextEditingController();
  final _pinController = TextEditingController();

  String? _selectedCourse;
  String? _selectedBranch;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _campusNameController.dispose();
    _uidController.dispose();
    _customCourseController.dispose();
    _customBranchController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  final List<String> _courses = [
    'B.Tech',
    'M.Tech',
    'BCA',
    'MCA',
    'B.Sc',
    'M.Sc',
    'MBA',
    'Others',
  ];
  final List<String> _branches = [
    'Civil Engineering',
    'Computer Engineering',
    'Electrical Engineering',
    'Electronics & Communication Engineering (ECE)',
    'Mechanical Engineering',
    'Production & Industrial Engineering',
    'Artificial Intelligence & Machine Learning (AI & ML)',
    'Artificial Intelligence & Data Science',
    'Mathematics & Computing',
    'Industrial Internet of Things (IIoT)',
    'Others',
  ];

  void _showJoinDialog(Campus campus) {
    // Reset controllers and local state before showing dialog
    _uidController.clear();
    _pinController.clear();
    _customCourseController.clear();
    _customBranchController.clear();
    _selectedCourse = null;
    _selectedBranch = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Join ${campus.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your college details to join the community.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                _buildTextField(
                  _uidController,
                  'Roll No / UID',
                  Icons.badge_outlined,
                ),
                const SizedBox(height: 16),

                _buildDropdown('Select Course', _courses, _selectedCourse, (
                  val,
                ) {
                  setModalState(() {
                    _selectedCourse = val;
                  });
                }),
                if (_selectedCourse == 'Others') ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    _customCourseController,
                    'Enter your course',
                    Icons.edit_note_rounded,
                  ),
                ],
                const SizedBox(height: 16),

                _buildDropdown('Select Branch', _branches, _selectedBranch, (
                  val,
                ) {
                  setModalState(() {
                    _selectedBranch = val;
                  });
                }),
                if (_selectedBranch == 'Others') ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    _customBranchController,
                    'Enter your branch/dept',
                    Icons.account_tree_outlined,
                  ),
                ],
                const SizedBox(height: 16),

                // PIN Field for Gatekeeping
                _buildTextField(
                  _pinController,
                  'Campus Join PIN (Ask Admin)',
                  Icons.lock_outline_rounded,
                  isObscure: true,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _joinCampus(campus.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Confirm & Join',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _joinCampus(String campusId) async {
    final finalCourse = _selectedCourse == 'Others'
        ? _customCourseController.text
        : _selectedCourse;
    final finalBranch = _selectedBranch == 'Others'
        ? _customBranchController.text
        : _selectedBranch;

    if (_uidController.text.isEmpty ||
        finalCourse == null ||
        finalCourse.isEmpty ||
        finalBranch == null ||
        finalBranch.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all details')));
      return;
    }

    try {
      await ref
          .read(campusRepositoryProvider)
          .joinCampus(
            campusId: campusId,
            uid: _uidController.text,
            course: finalCourse,
            branch: finalBranch,
            pin: _pinController.text.trim().isEmpty ? null : _pinController.text.trim(),
          );
      
      // Invalidate membership providers to fetch fresh data
      ref.invalidate(myCampusesProvider);
      ref.invalidate(myMembershipsProvider);
      
      // Auto-select the newly joined campus
      ref.read(selectedCampusIdProvider.notifier).selectCampus(campusId);

      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /*
  /// Institute PIN before [joinCampus] — campus gatekeeper (not used inside Communities).
  Future<String?> _showInstitutePinDialog() {
    String pin = '';
    final theme = Theme.of(context);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Institute PIN',
          style: theme.textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the PIN issued by your campus admin to unlock this institute on Connekt.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 6),
              decoration: InputDecoration(
                hintText: '••••',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => pin = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, pin),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  */

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    Widget? suffixIcon,
    int? maxLength,
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        counterStyle: const TextStyle(color: Colors.white54, fontSize: 10),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: AppTheme.primary),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          dropdownColor: const Color(0xFF1E293B),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCampuses = ref.watch(allCampusesProvider);
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Select Campus',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    _searchController,
                    'Search College Name...',
                    Icons.search,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Popular Campuses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _isCreating = !_isCreating),
                        child: Text(
                          _isCreating ? 'Cancel' : '+ Create New',
                          style: const TextStyle(color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                  if (_isCreating) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      _campusNameController,
                      'New Campus Name (e.g. SPIT)',
                      Icons.school_outlined,
                      maxLength: 50,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_campusNameController.text.isNotEmpty) {
                            await ref
                                .read(campusRepositoryProvider)
                                .createCampus(_campusNameController.text);
                            ref.invalidate(allCampusesProvider);
                            ref.invalidate(myCampusesProvider);
                            ref.invalidate(myMembershipsProvider);
                            setState(() => _isCreating = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                        child: const Text(
                          'Create Campus',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          allCampuses.when(
            data: (campuses) {
              final filteredCampuses = query.isEmpty
                  ? campuses
                  : campuses
                        .where(
                          (campus) => campus.name.toLowerCase().contains(query),
                        )
                        .toList();

              if (filteredCampuses.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No campuses match your search.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final campus = filteredCampuses[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_city_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      title: Text(
                        campus.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: const Text(
                        'Tap to join this community',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white24,
                        size: 16,
                      ),
                      onTap: () => _showJoinDialog(campus),
                    ),
                  );
                }, childCount: filteredCampuses.length),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
