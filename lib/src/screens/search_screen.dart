import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/work.dart';
import '../models/search_type.dart';
import '../providers/auth_provider.dart';
import '../widgets/work_card.dart';
import '../widgets/tag_chip.dart';
import '../widgets/va_chip.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<Work> _works = [];
  List<Tag> _allTags = [];
  List<Va> _allVas = [];
  Tag? _selectedTag;
  Va? _selectedVa;

  SearchType _searchType = SearchType.keyword;

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchTextChanged);
    _loadTagsAndVas();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (_searchType == SearchType.rjNumber) {
      final text = _searchController.text.trim();
      if (text.length == 6 && int.tryParse(text) != null) {
        _search();
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadTagsAndVas() async {
    try {
      final apiService = ref.read(kikoeruApiServiceProvider);
      final tags = await apiService.getAllTags();
      final vas = await apiService.getAllVas();

      if (mounted) {
        setState(() {
          _allTags = tags.map((json) => Tag.fromJson(json)).toList();
          _allVas = vas.map((json) => Va.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Failed to load tags and vas: -Forcee');
    }
  }

  Future<void> _search({bool isNewSearch = true}) async {
    if (_isLoading) return;

    if (!_validateSearch()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (isNewSearch) {
        _works.clear();
        _currentPage = 1;
        _hasMore = true;
      }
    });

    try {
      final apiService = ref.read(kikoeruApiServiceProvider);
      Map<String, dynamic> result;

      switch (_searchType) {
        case SearchType.rjNumber:
          final rjNumber = _searchController.text.trim();
          result = await apiService.searchWorks(
              keyword: rjNumber, page: _currentPage);
          break;
        case SearchType.va:
          if (_selectedVa == null) {
            setState(() {
              _isLoading = false;
              _errorMessage = '请先选择声优';
            });
            return;
          }
          result = await apiService.getWorksByVa(
              vaId: _selectedVa!.id, page: _currentPage);
          break;
        case SearchType.tag:
          if (_selectedTag == null) {
            setState(() {
              _isLoading = false;
              _errorMessage = '请先选择标签';
            });
            return;
          }
          result = await apiService.getWorksByTag(
              tagId: _selectedTag!.id, page: _currentPage);
          break;
        case SearchType.keyword:
        default:
          final keyword = _searchController.text.trim();
          result = await apiService.searchWorks(
              keyword: keyword.isNotEmpty ? keyword : null, page: _currentPage);
          break;
      }

      if (mounted) {
        final works = (result['works'] as List)
            .map((json) => Work.fromJson(json))
            .toList();
        setState(() {
          if (isNewSearch) {
            _works = works;
          } else {
            _works.addAll(works);
          }
          _hasMore = works.length >= 20;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '搜索失败: -Forcee';
        });
      }
    }
  }

  bool _validateSearch() {
    switch (_searchType) {
      case SearchType.rjNumber:
        final text = _searchController.text.trim();
        if (text.isEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('请输入RJ号')));
          return false;
        }
        if (text.length != 6 || int.tryParse(text) == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('RJ号必须是6位数字')));
          return false;
        }
        return true;
      case SearchType.va:
        if (_selectedVa == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('请选择声优')));
          return false;
        }
        return true;
      case SearchType.tag:
        if (_selectedTag == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('请选择标签')));
          return false;
        }
        return true;
      case SearchType.keyword:
      default:
        return true;
    }
  }

  Future<void> _loadMore() async {
    await _search(isNewSearch: false);
  }

  void _showSearchTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择搜索类型'),
        children: SearchType.values.map((type) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() {
                _searchType = type;
                _searchController.clear();
                _works.clear();
                _selectedTag = null;
                _selectedVa = null;
              });
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  if (_searchType == type)
                    const Icon(Icons.check, color: Colors.blue),
                  if (_searchType == type) const SizedBox(width: 8),
                  Text(type.label),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showTagSelector() async {
    final selected = await showDialog<Tag>(
        context: context,
        builder: (context) => _TagSelectorDialog(tags: _allTags));
    if (selected != null) {
      setState(() {
        _selectedTag = selected;
      });
      _search();
    }
  }

  Future<void> _showVaSelector() async {
    final selected = await showDialog<Va>(
        context: context,
        builder: (context) => _VaSelectorDialog(vas: _allVas));
    if (selected != null) {
      setState(() {
        _selectedVa = selected;
      });
      _search();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_searchType.label),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                    onPressed: _showSearchTypeDialog,
                    icon: const Icon(Icons.tune),
                    tooltip: '切换搜索类型'),
                const SizedBox(width: 8),
                Expanded(child: _buildSearchInput()),
                const SizedBox(width: 8),
                if (_searchType != SearchType.rjNumber)
                  IconButton(
                      onPressed: _search,
                      icon: const Icon(Icons.search),
                      tooltip: '搜索'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_selectedTag != null || _selectedVa != null)
            Container(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedTag != null)
                      TagChip(
                          tag: _selectedTag!,
                          onDeleted: () {
                            setState(() {
                              _selectedTag = null;
                              _works.clear();
                            });
                          }),
                    if (_selectedVa != null)
                      VaChip(
                          va: _selectedVa!,
                          onDeleted: () {
                            setState(() {
                              _selectedVa = null;
                              _works.clear();
                            });
                          }),
                  ],
                ),
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    switch (_searchType) {
      case SearchType.rjNumber:
        return TextField(
          controller: _searchController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6)
          ],
          decoration: InputDecoration(
              hintText: _searchType.hint,
              prefixIcon: const Icon(Icons.tag),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
        );
      case SearchType.va:
        return InkWell(
          onTap: _showVaSelector,
          child: InputDecorator(
            decoration: InputDecoration(
                hintText: _searchType.hint,
                prefixIcon: const Icon(Icons.person),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
            child: Text(_selectedVa?.name ?? _searchType.hint,
                style: TextStyle(
                    color: _selectedVa == null
                        ? Theme.of(context).hintColor
                        : Theme.of(context).textTheme.bodyLarge?.color)),
          ),
        );
      case SearchType.tag:
        return InkWell(
          onTap: _showTagSelector,
          child: InputDecorator(
            decoration: InputDecoration(
                hintText: _searchType.hint,
                prefixIcon: const Icon(Icons.label),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
            child: Text(_selectedTag?.name ?? _searchType.hint,
                style: TextStyle(
                    color: _selectedTag == null
                        ? Theme.of(context).hintColor
                        : Theme.of(context).textTheme.bodyLarge?.color)),
          ),
        );
      case SearchType.keyword:
      default:
        return TextField(
          controller: _searchController,
          decoration: InputDecoration(
              hintText: _searchType.hint,
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
          onSubmitted: (_) => _search(),
        );
    }
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline,
            size: 64, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 16),
        Text(_errorMessage!),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _search, child: const Text('重试'))
      ]));
    }
    if (_works.isEmpty && !_isLoading) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.search, size: 64),
        const SizedBox(height: 16),
        Text(_getEmptyMessage())
      ]));
    }
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8),
      itemCount: _works.length + (_isLoading ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= _works.length)
          return const Center(child: CircularProgressIndicator());
        return WorkCard(work: _works[index]);
      },
    );
  }

  String _getEmptyMessage() {
    switch (_searchType) {
      case SearchType.rjNumber:
        return '输入6位RJ号开始搜索';
      case SearchType.va:
        return '选择声优开始搜索';
      case SearchType.tag:
        return '选择标签开始搜索';
      case SearchType.keyword:
      default:
        return '输入关键词开始搜索';
    }
  }
}

class _TagSelectorDialog extends StatefulWidget {
  final List<Tag> tags;
  const _TagSelectorDialog({required this.tags});
  @override
  State<_TagSelectorDialog> createState() => _TagSelectorDialogState();
}

class _TagSelectorDialogState extends State<_TagSelectorDialog> {
  final _searchController = TextEditingController();
  List<Tag> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _filteredTags = widget.tags;
    _searchController.addListener(_filterTags);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTags() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTags = widget.tags;
      } else {
        _filteredTags = widget.tags
            .where((tag) => tag.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                      hintText: '搜索标签...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder()))),
          Expanded(
              child: ListView.builder(
                  itemCount: _filteredTags.length,
                  itemBuilder: (context, index) {
                    final tag = _filteredTags[index];
                    return ListTile(
                        title: Text(tag.name),
                        onTap: () => Navigator.pop(context, tag));
                  })),
        ],
      ),
    );
  }
}

class _VaSelectorDialog extends StatefulWidget {
  final List<Va> vas;
  const _VaSelectorDialog({required this.vas});
  @override
  State<_VaSelectorDialog> createState() => _VaSelectorDialogState();
}

class _VaSelectorDialogState extends State<_VaSelectorDialog> {
  final _searchController = TextEditingController();
  List<Va> _filteredVas = [];

  @override
  void initState() {
    super.initState();
    _filteredVas = widget.vas;
    _searchController.addListener(_filterVas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterVas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredVas = widget.vas;
      } else {
        _filteredVas = widget.vas
            .where((va) => va.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                      hintText: '搜索声优...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder()))),
          Expanded(
              child: ListView.builder(
                  itemCount: _filteredVas.length,
                  itemBuilder: (context, index) {
                    final va = _filteredVas[index];
                    return ListTile(
                        title: Text(va.name),
                        onTap: () => Navigator.pop(context, va));
                  })),
        ],
      ),
    );
  }
}
