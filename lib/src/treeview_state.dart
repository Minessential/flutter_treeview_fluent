part of 'treeview.dart';

/// The state management class for the [FluentTreeView] widget.
///
/// This class handles the internal logic and state of the tree view, including:
/// - Node selection and deselection
/// - Expansion and collapse of nodes
/// - Filtering and sorting of nodes
/// - Handling of "Select All" functionality
/// - Managing the overall tree structure
///
/// It also provides methods for external manipulation of the tree, such as:
/// - [filter] for applying filters to the tree nodes
/// - [sort] for sorting the tree nodes
/// - [setSelectAll] for selecting or deselecting all nodes
/// - [expandAll] and [collapseAll] for expanding or collapsing all nodes
/// - [getSelectedNodes] and [getSelectedValues] for retrieving selected items
///
/// This class is not intended to be used directly by users of the [FluentTreeView] widget,
/// but rather serves as the internal state management mechanism.
class FluentTreeViewState<T> extends State<FluentTreeView<T>> {
  late List<FluentTreeNode<T>> _roots;
  bool _isAllSelected = false;
  late bool _isAllExpanded;

  @override
  void initState() {
    super.initState();
    _roots = widget.nodes;
    _initializeNodes(_roots, null);
    _setInitialExpansion(_roots, 0);
    _updateAllNodesSelectionState();
    _updateSelectAllState();
    _isAllExpanded = widget.initialExpandedLevels == 0;
  }

  /// Filters the tree nodes based on the provided filter function.
  ///
  /// The [filterFunction] should return true for nodes that should be visible.
  void filter(bool Function(FluentTreeNode<T>) filterFunction) {
    setState(() {
      _applyFilter(_roots, filterFunction);
      _updateAllNodesSelectionState();
      _updateSelectAllState();
    });
  }

  /// Sorts the tree nodes based on the provided compare function.
  ///
  /// If [compareFunction] is null, the original order is restored.
  void sort(int Function(FluentTreeNode<T>, FluentTreeNode<T>)? compareFunction) {
    setState(() {
      if (compareFunction == null) {
        _applySort(_roots, (a, b) => a._originalIndex.compareTo(b._originalIndex));
      } else {
        _applySort(_roots, compareFunction);
      }
    });
  }

  /// Sets the selection state of all nodes.
  void setSelectAll(bool isSelected) {
    setState(() {
      _setAllNodesSelection(isSelected);
      _updateSelectAllState();
    });
    _notifySelectionChanged();
  }

  /// Expands all nodes in the tree.
  void expandAll() {
    setState(() {
      _setExpansionState(_roots, true);
    });
  }

  /// Collapses all nodes in the tree.
  void collapseAll() {
    setState(() {
      _setExpansionState(_roots, false);
    });
  }

  /// Sets the selected values in the tree.
  void setSelectedValues(List<T> selectedValues) {
    for (var root in _roots) {
      _setNodeAndDescendantsSelectionByValue(root, selectedValues);
    }
    _updateSelectAllState();
    _notifySelectionChanged();
  }

  void _setNodeAndDescendantsSelectionByValue(FluentTreeNode<T> node, List<T> selectedValues) {
    if (node._hidden) return;
    node._isSelected = selectedValues.contains(node.value);
    node._isPartiallySelected = false;
    for (var child in node.children) {
      _setNodeAndDescendantsSelectionByValue(child, selectedValues);
    }
  }

  /// Returns a list of all selected nodes in the tree.
  List<FluentTreeNode<T>> getSelectedNodes() {
    return _getSelectedNodesRecursive(_roots);
  }

  /// Returns a list of all selected child nodes of the given node.
  List<FluentTreeNode<T>> getChildSelectedNodes(FluentTreeNode<T> node) {
    return _getSelectedNodesRecursive(node.children);
  }

  /// Returns a list of all selected values in the tree.
  List<T?> getSelectedValues() {
    return _getSelectedValues(_roots);
  }

  /// Returns a list of all selected child nodes values of the given node.
  List<T?> getChildSelectedValues(FluentTreeNode<T> node) {
    return _getSelectedValues(node.children);
  }

  void _initializeNodes(List<FluentTreeNode<T>> nodes, FluentTreeNode<T>? parent) {
    for (int i = 0; i < nodes.length; i++) {
      nodes[i]._originalIndex = i;
      nodes[i]._parent = parent;
      _initializeNodes(nodes[i].children, nodes[i]);
    }
  }

  void _setInitialExpansion(List<FluentTreeNode<T>> nodes, int currentLevel) {
    if (widget.initialExpandedLevels == null) {
      return;
    }
    for (var node in nodes) {
      if (widget.initialExpandedLevels == 0) {
        node._isExpanded = true;
      } else {
        node._isExpanded = currentLevel < widget.initialExpandedLevels!;
      }
      if (node._isExpanded) {
        _setInitialExpansion(node.children, currentLevel + 1);
      }
    }
  }

  void _applySort(List<FluentTreeNode<T>> nodes, int Function(FluentTreeNode<T>, FluentTreeNode<T>) compareFunction) {
    nodes.sort(compareFunction);
    for (var node in nodes) {
      if (node.children.isNotEmpty) {
        _applySort(node.children, compareFunction);
      }
    }
  }

  void _applyFilter(List<FluentTreeNode<T>> nodes, bool Function(FluentTreeNode<T>) filterFunction) {
    for (var node in nodes) {
      bool shouldShow = filterFunction(node) || _hasVisibleDescendant(node, filterFunction);
      node._hidden = !shouldShow;
      _applyFilter(node.children, filterFunction);
    }
  }

  void _updateAllNodesSelectionState() {
    for (var root in _roots) {
      _updateNodeSelectionStateBottomUp(root);
    }
  }

  void _updateNodeSelectionStateBottomUp(FluentTreeNode<T> node) {
    for (var child in node.children) {
      _updateNodeSelectionStateBottomUp(child);
    }
    _updateSingleNodeSelectionState(node);
  }

  void _updateNodeSelection(FluentTreeNode<T> node, bool? isSelected) {
    setState(() {
      if (isSelected == null) {
        _handlePartialSelection(node);
      } else {
        _updateNodeAndDescendants(node, isSelected);
      }
      _updateAncestorsRecursively(node);
      _updateSelectAllState();
    });
    _notifySelectionChanged();
  }

  void _handlePartialSelection(FluentTreeNode<T> node) {
    if (node._isSelected || node._isPartiallySelected) {
      _updateNodeAndDescendants(node, false);
    } else {
      _updateNodeAndDescendants(node, true);
    }
  }

  void _updateNodeAndDescendants(FluentTreeNode<T> node, bool isSelected) {
    if (!node._hidden) {
      node._isSelected = isSelected;
      node._isPartiallySelected = false;
      for (var child in node.children) {
        _updateNodeAndDescendants(child, isSelected);
      }
    }
  }

  void _updateAncestorsRecursively(FluentTreeNode<T> node) {
    FluentTreeNode<T>? parent = node._parent;
    if (parent != null) {
      _updateSingleNodeSelectionState(parent);
      _updateAncestorsRecursively(parent);
    }
  }

  void _notifySelectionChanged() {
    List<T?> selectedValues = _getSelectedValues(_roots);
    widget.onSelectionChanged?.call(selectedValues);
  }

  List<T?> _getSelectedValues(List<FluentTreeNode<T>> nodes) {
    List<T?> selectedValues = [];
    for (var node in nodes) {
      if (node._isSelected && !node._hidden) {
        selectedValues.add(node.value);
      }
      selectedValues.addAll(_getSelectedValues(node.children));
    }
    return selectedValues;
  }

  Widget _buildFluentTreeNode(FluentTreeNode<T> node, {double leftPadding = 0}) {
    if (node._hidden) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              onPressed: () => _updateNodeSelection(node, !node._isSelected),
              icon: Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: node.children.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              node._isExpanded
                                  ? FluentIcons.chevron_down_16_regular
                                  : FluentIcons.chevron_right_16_regular,
                              size: 16,
                            ),
                            onPressed: () => _toggleNodeExpansion(node),
                            // padding: EdgeInsets.zero,
                            // constraints: const BoxConstraints(),
                          )
                        : null,
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: Checkbox(
                      checked: node._isSelected ? true : (node._isPartiallySelected ? null : false),
                      // tristate: true,
                      onChanged: (bool? value) => _updateNodeSelection(node, value ?? false),
                      // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (node.icon != null) ...[node.icon!, const SizedBox(width: 8)],
                  Expanded(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      node.label,
                      if (node.trailing != null)
                        Padding(
                            padding: const EdgeInsetsDirectional.only(end: 12), child: node.trailing!(context, node)),
                    ],
                  )),
                ],
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: node._isExpanded ? 0 : 1,
              end: node._isExpanded ? 1 : 0,
            ),
            builder: (context, value, child) {
              return ClipRect(
                child: Align(
                  heightFactor: value,
                  child: child,
                ),
              );
            },
            child: node.children.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: node.children.map((child) => _buildFluentTreeNode(child)).toList(),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  void _toggleNodeExpansion(FluentTreeNode<T> node) {
    setState(() {
      node._isExpanded = !node._isExpanded;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _hasVisibleDescendant(FluentTreeNode<T> node, bool Function(FluentTreeNode<T>) filterFunction) {
    for (var child in node.children) {
      if (filterFunction(child) || _hasVisibleDescendant(child, filterFunction)) {
        return true;
      }
    }
    return false;
  }

  void _updateSingleNodeSelectionState(FluentTreeNode<T> node) {
    if (node.children.isEmpty || node.children.every((child) => child._hidden)) {
      return;
    }

    List<FluentTreeNode<T>> visibleChildren = node.children.where((child) => !child._hidden).toList();
    bool allSelected = visibleChildren.every((child) => child._isSelected);
    bool anySelected = visibleChildren.any((child) => child._isSelected || child._isPartiallySelected);

    if (allSelected) {
      node._isSelected = true;
      node._isPartiallySelected = false;
    } else if (anySelected) {
      node._isSelected = false;
      node._isPartiallySelected = true;
    } else {
      node._isSelected = false;
      node._isPartiallySelected = false;
    }
  }

  void _setExpansionState(List<FluentTreeNode<T>> nodes, bool isExpanded) {
    for (var node in nodes) {
      node._isExpanded = isExpanded;
      _setExpansionState(node.children, isExpanded);
    }
  }

  void _updateSelectAllState() {
    if (!widget.showSelectAll) return;
    bool allSelected = _roots.where((node) => !node._hidden).every((node) => _isNodeFullySelected(node));
    setState(() {
      _isAllSelected = allSelected;
    });
  }

  bool _isNodeFullySelected(FluentTreeNode<T> node) {
    if (node._hidden) return true;
    if (!node._isSelected) return false;
    return node.children.where((child) => !child._hidden).every(_isNodeFullySelected);
  }

  void _handleSelectAll(bool? value) {
    if (value == null) return;
    _setAllNodesSelection(value);
    _updateSelectAllState();
    _notifySelectionChanged();
  }

  void _setAllNodesSelection(bool isSelected) {
    for (var root in _roots) {
      _setNodeAndDescendantsSelection(root, isSelected);
    }
  }

  void _setNodeAndDescendantsSelection(FluentTreeNode<T> node, bool isSelected) {
    if (node._hidden) return;
    node._isSelected = isSelected;
    node._isPartiallySelected = false;
    for (var child in node.children) {
      _setNodeAndDescendantsSelection(child, isSelected);
    }
  }

  void _toggleExpandCollapseAll() {
    setState(() {
      _isAllExpanded = !_isAllExpanded;
      _setExpansionState(_roots, _isAllExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final verticalController = ScrollController();
    final horizontalController = ScrollController();

    return FluentTheme(
        data: widget.theme ?? FluentTheme.of(context),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Scrollbar(
              controller: horizontalController,
              child: Scrollbar(
                controller: verticalController,
                notificationPredicate: (notification) => notification.depth >= 0,
                child: SingleChildScrollView(
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: verticalController,
                    scrollDirection: Axis.vertical,
                    child: IntrinsicWidth(
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.showSelectAll || widget.showExpandCollapseButton)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: IconButton(
                                    onPressed: () {
                                      if (widget.showSelectAll) {
                                        setState(() {
                                          _isAllSelected = !_isAllSelected;
                                        });
                                        _handleSelectAll(_isAllSelected);
                                      }
                                    },
                                    icon: Row(
                                      children: [
                                        SizedBox(
                                          height: 28,
                                          width: 28,
                                          child: widget.showExpandCollapseButton
                                              ? IconButton(
                                                  icon: Icon(
                                                    _isAllExpanded
                                                        ? FluentIcons.chevron_down_up_16_filled
                                                        : FluentIcons.chevron_up_down_16_filled,
                                                    size: 16,
                                                  ),
                                                  onPressed: _toggleExpandCollapseAll,
                                                )
                                              : null,
                                        ),
                                        if (widget.showSelectAll)
                                          Container(
                                            width: 28,
                                            height: 28,
                                            alignment: Alignment.center,
                                            child: Checkbox(
                                              checked: _isAllSelected,
                                              onChanged: _handleSelectAll,
                                            ),
                                          ),
                                        if (widget.showSelectAll)
                                          Expanded(
                                            child: Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    if (widget.selectAllWidget != null) widget.selectAllWidget!,
                                                    if (widget.selectAllTrailing != null)
                                                      Expanded(
                                                        child: Padding(
                                                            padding: const EdgeInsetsDirectional.only(end: 12),
                                                            child: widget.selectAllTrailing!(context)),
                                                      ),
                                                  ],
                                                )),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ..._roots.map((root) => _buildFluentTreeNode(root)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ));
  }

  List<FluentTreeNode<T>> _getSelectedNodesRecursive(List<FluentTreeNode<T>> nodes) {
    List<FluentTreeNode<T>> selectedNodes = [];
    for (var node in nodes) {
      if (node._isSelected && !node._hidden) {
        selectedNodes.add(node);
      }
      if (node.children.isNotEmpty) {
        selectedNodes.addAll(_getSelectedNodesRecursive(node.children));
      }
    }
    return selectedNodes;
  }
}
