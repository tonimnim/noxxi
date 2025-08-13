import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/search/services/search_service.dart';
import 'package:noxxi/features/search/widgets/search_bar.dart';
import 'package:noxxi/features/search/widgets/filter_sheet.dart';
import 'package:noxxi/features/search/widgets/recent_searches.dart';
import 'package:noxxi/features/search/widgets/search_results_grid.dart';
import 'package:noxxi/features/search/widgets/section_header.dart';
import 'dart:async';

/// Pinterest-style search screen with clean architecture
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchService = SearchService();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;
  
  List<SearchResult> _searchResults = [];
  List<SearchResult> _popularEvents = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _currentQuery = '';
  
  // Filters
  RangeValues? _priceRange;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    // Load in parallel for speed
    final results = await Future.wait([
      _searchService.getPopularEvents(limit: 20),
      _searchService.getRecentSearches(limit: 4),
    ]);
    
    if (mounted) {
      setState(() {
        _popularEvents = results[0] as List<SearchResult>;
        _recentSearches = results[1] as List<String>;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query == _currentQuery) return;
    _currentQuery = query;
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    
    // Start searching after 300ms of no typing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) return;
    
    setState(() => _isSearching = true);
    
    final results = await _searchService.searchEvents(
      query: query,
      minPrice: _priceRange?.start,
      maxPrice: _priceRange?.end,
      startDate: _selectedDate,
      limit: 30,
    );
    
    if (mounted && _currentQuery == query) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _onRecentSearchTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _currentQuery = '';
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterSheet(
        initialPriceRange: _priceRange,
        initialSelectedDate: _selectedDate,
        onApply: (priceRange, selectedDate) {
          setState(() {
            _priceRange = priceRange;
            _selectedDate = selectedDate;
          });
          if (_currentQuery.isNotEmpty) {
            _performSearch(_currentQuery);
          }
        },
      ),
    );
  }

  void _onEventTap(SearchResult event) {
    Navigator.pushNamed(
      context,
      '/event-details',
      arguments: event.id,
    );
  }

  Future<void> _clearRecentSearches() async {
    await _searchService.clearRecentSearches();
    setState(() => _recentSearches = []);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
      ),
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            top: true,
            bottom: false,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  SearchBarWidget(
                    controller: _searchController,
                    onClear: _clearSearch,
                    onFilterTap: _showFilterSheet,
                    hasActiveFilters: _priceRange != null || _selectedDate != null,
                  ),
                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Recent Searches (only show when not searching)
        if (!_isSearching && _searchResults.isEmpty && _recentSearches.isNotEmpty)
          SliverToBoxAdapter(
            child: RecentSearches(
              searches: _recentSearches,
              onSearchTap: _onRecentSearchTap,
              onClear: _clearRecentSearches,
            ),
          ),
        
        // Section Header
        SliverToBoxAdapter(
          child: SectionHeader(
            title: _isSearching || _searchResults.isNotEmpty
                ? 'Search Results'
                : 'Popular on Noxxi',
          ),
        ),
        
        // Results Grid
        SearchResultsGrid(
          events: _searchResults.isNotEmpty ? _searchResults : _popularEvents,
          isSearching: _isSearching,
          title: 'Search Results',
          onEventTap: _onEventTap,
        ),
      ],
    );
  }
}