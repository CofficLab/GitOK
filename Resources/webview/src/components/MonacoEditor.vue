<template>
    <div id="container" style="height: 100%"></div>
</template>

<script setup lang="ts">
import * as monaco from "monaco-editor";
import { onMounted } from "vue";

onMounted(() => {
    var originalModel = monaco.editor.createModel(
        "This line is removed on the right.\njust some text\nabcd\nefgh\nSome more text",
        "text/plain"
    );
    var modifiedModel = monaco.editor.createModel(
        "just some text\nabcz\nzzzzefgh\nSome more text.\nThis line is removed on the left.",
        "text/plain"
    );

    var diffEditor = monaco.editor.createDiffEditor(
        document.getElementById("container")!,
        {
            // You can optionally disable the resizing
            enableSplitViewResizing: false,
            renderSideBySide: false,
            readOnly: true,
            minimap: {
                enabled: false,
                side: "left",
            }
        }
    );
    diffEditor.setModel({
        original: originalModel,
        modified: modifiedModel,
    });
})
</script>

<style scoped>
.read-the-docs {
    color: #888;
}
</style>
