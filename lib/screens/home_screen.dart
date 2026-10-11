import 'package:flutter/material.dart';
import '../data/sample_opportunities.dart';
import '../models/opportunity.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/opportunity_card.dart';
import 'opportunity_detail_screen.dart';

/// The Home (Discover) dashboard with searching, category filtering,
/// quick impact metrics, and responsive opportunity cards.
class HomeScreen extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback onDataChanged;

  const HomeScreen({
    super.key,
    required this.userProfile,
    required this.onDataChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _onlySaved = false;

  final List<String> _categories = [
    'All',
    'Environment',
    'Education',
    'Animal Welfare',
    'Community',
    'Healthcare',
  ];

  List<Opportunity> get _filteredOpportunities {
    return sampleOpportunities.where((opp) {
      // Category match
      final matchesCategory =
          _selectedCategory == 'All' || opp.cause == _selectedCategory;

      // Saved only match
      final matchesSaved = !_onlySaved ||
          widget.userProfile.savedOpportunityIds.contains(opp.id);

      // Search match
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          opp.title.toLowerCase().contains(query) ||
          opp.cause.toLowerCase().contains(query) ||
          opp.location.toLowerCase().contains(query) ||
          opp.requiredSkills.any((s) => s.toLowerCase().contains(query));

      return matchesCategory && matchesSaved && matchesSearch;
    }).toList();
  }

  void _openDetails(Opportunity opp) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) => OpportunityDetailScreen(
          opportunity: opp,
          userProfile: widget.userProfile,
          isSaved: widget.userProfile.savedOpportunityIds.contains(opp.id),
          isJoined: widget.userProfile.joinedOpportunityIds.contains(opp.id),
          isCompleted: widget.userProfile.isOpportunityCompleted(opp.id),
          onToggleBookmark: () => _toggleBookmark(opp.id),
          onJoin: () => _joinOpportunity(opp.id),
        ),
      ),
    );
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (widget.userProfile.savedOpportunityIds.contains(id)) {
        widget.userProfile.savedOpportunityIds.remove(id);
      } else {
        widget.userProfile.savedOpportunityIds.add(id);
      }
    });
    widget.onDataChanged();
  }

  void _joinOpportunity(String id) {
    setState(() {
      widget.userProfile.joinedOpportunityIds.add(id);
    });
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOpportunities;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar & Impact Summary Strip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.paleGreen,
                        radius: 20,
                        child: Icon(Icons.volunteer_activism, color: AppTheme.forestGreenDark),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VolunteerConnect',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.forestGreenDark,
                            ),
                          ),
                          Text(
                            'Hello, ${widget.userProfile.name}',
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Quick filter toggle for saved
                      FilterChip(
                        avatar: Icon(
                          _onlySaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 16,
                          color: _onlySaved ? AppTheme.forestGreenDark : Colors.grey.shade700,
                        ),
                        label: Text(
                          'Saved (${widget.userProfile.savedOpportunityIds.length})',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _onlySaved ? AppTheme.forestGreenDark : Colors.grey.shade800,
                          ),
                        ),
                        selected: _onlySaved,
                        onSelected: (val) => setState(() => _onlySaved = val),
                        selectedColor: AppTheme.paleGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search field
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search causes, skills, or locations...',
                      hintStyle: const TextStyle(fontSize: 13.5, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.forestGreen),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.forestGreen, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Category Filter Chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.forestGreenDark : AppTheme.textDark,
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.paleGreen,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppTheme.forestGreen : Colors.grey.shade300,
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Results count and active filter indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} opportunities found',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedCategory != 'All' || _onlySaved || _searchQuery.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'All';
                          _onlySaved = false;
                          _searchQuery = '';
                        });
                      },
                      child: const Text('Reset filters', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),

            // List of Opportunities or Empty State
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _onlySaved ? Icons.bookmark_border : Icons.search_off,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _onlySaved
                                  ? 'No Bookmarked Opportunities'
                                  : 'No Matching Opportunities',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _onlySaved
                                  ? 'You haven’t saved any opportunities yet. Browse and tap the bookmark icon to save them for later.'
                                  : 'Try adjusting your search keywords or switching category filters.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final opp = filtered[i];
                        return OpportunityCard(
                          opportunity: opp,
                          isSaved: widget.userProfile.savedOpportunityIds.contains(opp.id),
                          isJoined: widget.userProfile.joinedOpportunityIds.contains(opp.id),
                          isCompleted: widget.userProfile.isOpportunityCompleted(opp.id),
                          onTap: () => _openDetails(opp),
                          onToggleBookmark: () => _toggleBookmark(opp.id),
                          onJoin: () => _joinOpportunity(opp.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
