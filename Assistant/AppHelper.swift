diff --git a/GitOK/Helper/AppHelper.swift b/GitOK/Helper/AppHelper.swift
deleted file mode 100644
index c9dad82..0000000
--- a/GitOK/Helper/AppHelper.swift
+++ /dev/null
@@ -1,15 +0,0 @@
-import Foundation
-
-class AppHelper {
-    func isInSandbox() -> Bool {
-        let fileManager = FileManager.default
-        let appURLs = fileManager.urls(for: .applicationDirectory, in: .userDomainMask)
-
-        if let appURL = appURLs.first {
-            // 判断应用程序的路径是否包含特定的沙盒路径
-            return appURL.path.contains("Containers/Data/Application")
-        }
-
-        return false
-    }
-}
