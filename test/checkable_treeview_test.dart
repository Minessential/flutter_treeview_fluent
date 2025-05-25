import 'package:checkable_treeview_fluent/checkable_treeview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FluentTreeView initializes with correct number of nodes', (WidgetTester tester) async {
    // Create test node data
    final testNodes = [
      FluentTreeNode<String>(
        label: const Text('Root 1'),
        children: [
          FluentTreeNode<String>(label: const Text('Child 1.1')),
          FluentTreeNode<String>(label: const Text('Child 1.2')),
        ],
      ),
      FluentTreeNode<String>(
        label: const Text('Root 2'),
        children: [
          FluentTreeNode<String>(label: const Text('Child 2.1')),
          FluentTreeNode<String>(label: const Text('Child 2.2')),
        ],
      ),
    ];

    // Build the FluentTreeView widget
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FluentTreeView<String>(
            nodes: testNodes,
            onSelectionChanged: (_) {},
            initialExpandedLevels: 0, // Expand all nodes
          ),
        ),
      ),
    );

    // Wait for all animations to complete
    await tester.pumpAndSettle();

    // Verify root node count
    expect(find.text('Root 1'), findsOneWidget);
    expect(find.text('Root 2'), findsOneWidget);

    // Verify child node count
    expect(find.text('Child 1.1'), findsOneWidget);
    expect(find.text('Child 1.2'), findsOneWidget);
    expect(find.text('Child 2.1'), findsOneWidget);
    expect(find.text('Child 2.2'), findsOneWidget);

    // Verify total node count
    expect(find.byType(Text), findsNWidgets(6));
  });

  testWidgets('FluentTreeView getSelectedValues returns correct values', (WidgetTester tester) async {
    // Create test node data with values
    final testNodes = [
      FluentTreeNode<String>(
        label: const Text('Root 1'),
        value: 'value1',
        children: [
          FluentTreeNode<String>(label: const Text('Child 1.1'), value: 'value1.1'),
          FluentTreeNode<String>(label: const Text('Child 1.2'), value: 'value1.2'),
        ],
      ),
      FluentTreeNode<String>(
        label: const Text('Root 2'),
        value: 'value2',
        children: [
          FluentTreeNode<String>(label: const Text('Child 2.1'), value: 'value2.1'),
          FluentTreeNode<String>(label: const Text('Child 2.2'), value: 'value2.2'),
        ],
      ),
    ];

    // Create a GlobalKey to access the FluentTreeViewState
    final GlobalKey<FluentTreeViewState<String>> FluenttreeViewKey = GlobalKey();

    // Build the FluentTreeView widget
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FluentTreeView<String>(
            key: FluenttreeViewKey,
            nodes: testNodes,
            onSelectionChanged: (_) {},
            initialExpandedLevels: 0, // Expand all nodes
          ),
        ),
      ),
    );

    // Wait for all animations to complete
    await tester.pumpAndSettle();

    // Select some nodes
    await tester.tap(find.text('Root 1'));
    await tester.tap(find.text('Child 2.2'));
    await tester.pumpAndSettle();

    // Get selected values
    final selectedValues = FluenttreeViewKey.currentState!.getSelectedValues();

    // Verify selected values
    expect(selectedValues, containsAll(['value1', 'value1.1', 'value1.2', 'value2.2']));
    expect(selectedValues.length, 4);
  });
}
