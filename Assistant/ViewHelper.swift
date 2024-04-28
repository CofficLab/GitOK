diff --git a/GitOK/Helper/ViewHelper.swift b/GitOK/Helper/ViewHelper.swift
deleted file mode 100644
index 7d3039a..0000000
--- a/GitOK/Helper/ViewHelper.swift
+++ /dev/null
@@ -1,20 +0,0 @@
-import Foundation
-import SwiftUI
-
-class ViewHelper {
-    static func makeCard(_ text: String) -> some View {
-        Text(text)
-            .padding(.horizontal, 8)
-            .overlay(
-                Rectangle()
-                    .fill(Color.black.opacity(0.3))
-                    .frame(height: 30)
-                    .cornerRadius(8)).padding(.horizontal, 8)
-    }
-
-    static var dashedBorder: some Shape = Rectangle()
-        .stroke(style: StrokeStyle(
-            lineWidth: 1,
-            dash: [5])
-        )
-}
