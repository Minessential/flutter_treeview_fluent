import 'package:checkable_treeview_fluent/checkable_treeview.dart';
import 'package:fluent_ui/fluent_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'TreeView Example',
      theme: FluentThemeData(accentColor: Colors.blue),
      home: const MyHomePage(title: 'TreeView Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum SortOrder { defaultOrder, ascending, descending }

class _MyHomePageState extends State<MyHomePage> {
  List<FluentTreeNode<String>> _nodes = [];
  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();
  final _treeViewKey = GlobalKey<FluentTreeViewState<String>>();
  SortOrder _currentSortOrder = SortOrder.defaultOrder;

  @override
  void initState() {
    super.initState();
    _nodes = [
      FluentTreeNode(
        label: const Text('Project Folder'),
        value: 'project_folder',
        trailing: (context, node) {
          return Text('(${_treeViewKey.currentState?.getChildSelectedValues(node).length} selected)');
        },
        children: [
          FluentTreeNode(
            label: const Text('src'),
            icon: const Icon(FluentIcons.folder_open),
            children: [
              FluentTreeNode(
                  label: const Text('main.js'),
                  value: 'main_js',
                  icon: const Icon(FluentIcons.file_j_a_v_a),
                  isSelected: true),
              FluentTreeNode(label: const Text('app.js'), value: 'app_js', icon: const Icon(FluentIcons.file_j_a_v_a)),
              FluentTreeNode(
                  label: const Text('styles.css'), value: 'styles_css', icon: const Icon(FluentIcons.file_c_s_s)),
            ],
          ),
          FluentTreeNode(
            label: const Text('public'),
            value: 'public_folder',
            icon: const Icon(FluentIcons.folder_open),
            children: [
              FluentTreeNode(
                  label: const Text('index.html'), value: 'index_html', icon: const Icon(FluentIcons.file_h_t_m_l)),
              FluentTreeNode(
                  label: const Text('favicon.ico'), value: 'favicon', icon: const Icon(FluentIcons.file_image)),
            ],
          ),
        ],
      ),
      FluentTreeNode(
        label: const Text('Config Files'),
        value: 'config_folder',
        children: [
          FluentTreeNode(
              label: const Text('package.json'), value: 'package_json', icon: const Icon(FluentIcons.settings)),
          FluentTreeNode(
            label: const Text('.gitignore'),
            value: 'gitignore',
            icon: const Icon(FluentIcons.red_eye),
            trailing: (context, node) {
              return Text(node.data as String);
            },
            data: '1 KB',
          ),
        ],
      ),
    ];
  }

  void _onSelectionChanged(List<String?> selectedValues) {
    print('Selected node values: $selectedValues');
  }

  bool _filterNode(FluentTreeNode<String> node) {
    if (_searchKeyword.isEmpty) {
      return true;
    }
    return node.value?.toLowerCase().contains(_searchKeyword.toLowerCase()) ?? false;
  }

  void _performSearch() {
    setState(() {
      _searchKeyword = _searchController.text;
      _treeViewKey.currentState?.filter(_filterNode);
    });
    // Add this line to print selected nodes after search
    _printSelectedNodes();
  }

  void _sortNodes(SortOrder order) {
    setState(() {
      _currentSortOrder = order;
      switch (order) {
        case SortOrder.defaultOrder:
          _treeViewKey.currentState?.sort(null);
          break;
        case SortOrder.ascending:
          _treeViewKey.currentState?.sort((a, b) => (a.value ?? '').compareTo(b.value ?? ''));
          break;
        case SortOrder.descending:
          _treeViewKey.currentState?.sort((a, b) => (b.value ?? '').compareTo(a.value ?? ''));
          break;
      }
    });
  }

  void _expandAll() {
    _treeViewKey.currentState?.expandAll();
  }

  void _collapseAll() {
    _treeViewKey.currentState?.collapseAll();
  }

  void _printSelectedNodes() {
    List<FluentTreeNode<String>> selectedNodes = _treeViewKey.currentState?.getSelectedNodes() ?? [];
    print('Selected nodes:');
    for (var node in selectedNodes) {
      print('Value: ${node.value}, Label: ${node.label}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.title),
      ),
      pane: NavigationPane(
        selected: 0,
        displayMode: PaneDisplayMode.auto,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text('Example'),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextBox(
                          controller: _searchController,
                          placeholder: 'Enter search keyword',
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _performSearch,
                        child: const Text('Search'),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 150, // 设置固定宽度
                        child: ComboBox<SortOrder>(
                          isExpanded: true,
                          value: _currentSortOrder,
                          onChanged: (SortOrder? newValue) {
                            if (newValue != null) {
                              _sortNodes(newValue);
                            }
                          },
                          items: SortOrder.values.map((SortOrder order) {
                            return ComboBoxItem<SortOrder>(
                              value: order,
                              child: Text(_getSortOrderText(order)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _expandAll,
                        child: const Text('Expand All'),
                      ),
                      FilledButton(
                        onPressed: _collapseAll,
                        child: const Text('Collapse All'),
                      ),
                      FilledButton(
                        onPressed: () {
                          _treeViewKey.currentState?.setSelectAll(true);
                        },
                        child: const Text('Select All'),
                      ),
                      FilledButton(
                        onPressed: () {
                          _treeViewKey.currentState?.setSelectAll(false);
                        },
                        child: const Text('Deselect All'),
                      ),
                      FilledButton(
                        onPressed: _printSelectedNodes,
                        child: const Text('Print Selected Nodes'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FluentTreeView<String>(
                      key: _treeViewKey,
                      nodes: _nodes,
                      onSelectionChanged: _onSelectionChanged,
                      initialExpandedLevels: 1,
                      showSelectAll: true,
                      selectAllWidget: const Text('Select All'),
                      selectAllTrailing: (context) {
                        return Text('(${_treeViewKey.currentState?.getSelectedNodes().length} selected)');
                      },
                      showExpandCollapseButton: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSortOrderText(SortOrder order) {
    switch (order) {
      case SortOrder.defaultOrder:
        return 'Default Order';
      case SortOrder.ascending:
        return 'Ascending';
      case SortOrder.descending:
        return 'Descending';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
