// Aseprite
// Copyright (C) 2026  Nordtal
//
// This program is distributed under the terms of
// the End-User License Agreement for Aseprite.

#include "tests/app_test.h"

#include "app/script/tree_widget.h"

using namespace app::script;

namespace {

std::unique_ptr<TreeNode> node(const std::string& id, TreeNodes children = {})
{
  auto n = std::make_unique<TreeNode>();
  n->id = id;
  n->expanded = !children.empty();
  n->children = std::move(children);
  return n;
}

// Folder "a" with the leaf "b"
TreeNodes nodes()
{
  TreeNodes children;
  children.push_back(node("b"));
  TreeNodes list;
  list.push_back(node("a", std::move(children)));
  return list;
}

} // anonymous namespace

// Each event carries the node that's in the tree when it fires, even
// if the callback of an event before it replaced every node, the way
// a script calls dlg:modify{ nodes } from onchange.

TEST(TreeModel, ContextMenuAfterChangeReplacedTheNodes)
{
  TreeModel model;
  model.setChildren(nullptr, nodes());
  model.Change.connect([&](TreeNode*) { model.setChildren(nullptr, nodes()); });
  TreeNode* menuNode = nullptr;
  model.ContextMenu.connect([&](TreeNode* n) { menuNode = n; });

  model.contextMenu(model.findNode("b"));
  ASSERT_NE(nullptr, menuNode);
  EXPECT_EQ(model.findNode("b"), menuNode);
  EXPECT_EQ(model.findNode("b"), model.selected());
}

TEST(TreeModel, ContextMenuAfterChangeRemovedTheNode)
{
  TreeModel model;
  model.setChildren(nullptr, nodes());
  model.Change.connect([&](TreeNode*) { model.setChildren(nullptr, {}); });
  int menus = 0;
  model.ContextMenu.connect([&](TreeNode*) { ++menus; });

  model.contextMenu(model.findNode("b"));
  EXPECT_EQ(0, menus);
}

TEST(TreeModel, CollapseAfterChangeReplacedTheNodes)
{
  TreeModel model;
  model.setChildren(nullptr, nodes());
  model.setSelected(model.findNode("b"));
  int changes = 0;
  model.Change.connect([&](TreeNode*) {
    ++changes;
    model.setChildren(nullptr, nodes());
  });
  TreeNode* expandNode = nullptr;
  bool expanded = true;
  model.Expand.connect([&](TreeNode* n, bool e) {
    expandNode = n;
    expanded = e;
  });

  // Collapsing "a" moves the selection from "b" to it
  model.toggle(model.findNode("a"));
  EXPECT_EQ(1, changes);
  ASSERT_NE(nullptr, expandNode);
  EXPECT_EQ(model.findNode("a"), expandNode);
  EXPECT_FALSE(expanded);
}

TEST(TreeModel, CollapseAfterChangeRemovedTheNode)
{
  TreeModel model;
  model.setChildren(nullptr, nodes());
  model.setSelected(model.findNode("b"));
  model.Change.connect([&](TreeNode*) { model.setChildren(nullptr, {}); });
  int expands = 0;
  model.Expand.connect([&](TreeNode*, bool) { ++expands; });

  model.toggle(model.findNode("a"));
  EXPECT_EQ(0, expands);
}

// A label of 50 px starting at 14 px: the label shows whole, and the
// badge of 6 px of text and 2 px of padding starts 4 px after it,
// however wide the row is.

TEST(TreeRowLayout, BadgeAfterTheLabel)
{
  const TreeRowLayout layout = tree_row_layout(gfx::Rect(0, 32, 100, 16), 14, 50, 6, 2);
  EXPECT_EQ(gfx::Rect(14, 32, 50, 16), layout.label);
  EXPECT_EQ(gfx::Rect(68, 33, 10, 14), layout.badge);
}

TEST(TreeRowLayout, LabelWiderThanTheRow)
{
  const TreeRowLayout layout = tree_row_layout(gfx::Rect(0, 32, 40, 16), 14, 50, 6, 2);
  EXPECT_EQ(gfx::Rect(14, 32, 50, 16), layout.label);
  EXPECT_EQ(gfx::Rect(68, 33, 10, 14), layout.badge);
}

TEST(TreeRowLayout, NoBadge)
{
  const TreeRowLayout layout = tree_row_layout(gfx::Rect(0, 32, 1000, 16), 14, 50, 0, 2);
  EXPECT_TRUE(layout.badge.isEmpty());
  EXPECT_EQ(gfx::Rect(14, 32, 50, 16), layout.label);
}

// Two rows whose labels differ in width put their badges at different x
TEST(TreeRowLayout, BadgesDoNotLineUp)
{
  EXPECT_NE(tree_row_layout(gfx::Rect(0, 0, 200, 16), 14, 50, 6, 2).badge.x,
            tree_row_layout(gfx::Rect(0, 16, 200, 16), 14, 80, 6, 2).badge.x);
}
