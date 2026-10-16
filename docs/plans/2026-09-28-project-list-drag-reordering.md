# Project List Drag Reordering Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow users to drag projects in the left sidebar to reorder them, while preserving pinned projects at the top and persisting the order.

**Architecture:** Add a small ID-based reorder operation to `ProjectProviding` and implement it in `ProjectManager`. The sidebar uses SwiftUI's native drag/drop modifiers and delegates the actual mutation to the provider, so filtered views never rely on display indexes and all consumers receive the existing `projectsChanged` event.

**Tech Stack:** Swift 6, SwiftUI/AppKit, `ProjectProviding`, XCTest.

---

### Task 1: Add provider-level reorder behavior

**Files:**
- Modify: `Packages/ProviderProjects/Sources/ProviderProjects/ProjectProviding.swift`
- Modify: `Packages/PluginProjects/Sources/PluginProjects/ProjectManager.swift`
- Test: `Packages/PluginProjects/Tests/PluginProjectsTests/PluginProjectsTests.swift`

1. Add `moveProject(id:beforeID:)` to the project provider contract.
2. Add tests covering manual order, persistence, and the pinned/unpinned boundary.
3. Implement the operation using stable project IDs, preserving group order and notifying observers only when the order changes.

### Task 2: Add sidebar drag/drop interaction

**Files:**
- Modify: `Packages/PluginProjects/Sources/PluginProjects/ProjectSidebarProviding.swift`

1. Attach a text drag payload containing the project's UUID to each project row.
2. Add row and list-end drop delegates that translate drag targets into provider-level moves.
3. Keep reorder behavior available with search filtering and reset drag state after the drop.

### Task 3: Verify

1. Run the focused `PluginProjects` test suite.
2. Run the relevant build/test command available for the Xcode project.
3. Review the final diff and confirm pre-existing package manifest changes remain untouched.
