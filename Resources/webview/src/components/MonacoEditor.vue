<template>
  <div id="container" class="w-full h-full bg-black"></div>
</template>

<script setup lang="ts">
import * as monaco from 'monaco-editor';
import { useAppStore } from '../store/AppStore';
import { onMounted, watch } from 'vue';

const appStore = useAppStore();
var editor: monaco.editor.IStandaloneDiffEditor;

onMounted(() => {
  editor = makeEditor(appStore.original, appStore.modified);
  appStore.setReady();
});

watch(
  () => appStore.original,
  (newValue: string) => {
    editor.setModel({
      original: monaco.editor.createModel(newValue, 'text/plain'),
      modified: monaco.editor.createModel(appStore.modified, 'text/plain'),
    });
  }
);

watch(
  () => appStore.modified,
  (newValue: string) => {
    editor.setModel({
      original: monaco.editor.createModel(appStore.original, 'text/plain'),
      modified: monaco.editor.createModel(newValue, 'text/plain'),
    });
  }
);

function makeEditor(
  original: string,
  modified: string
): monaco.editor.IStandaloneDiffEditor {
  var originalModel = monaco.editor.createModel(original, 'text/plain');
  var modifiedModel = monaco.editor.createModel(modified, 'text/plain');

  var diffEditor = monaco.editor.createDiffEditor(
    document.getElementById('container')!,
    {
      automaticLayout: true,
      inDiffEditor: true,
      // You can optionally disable the resizing
      enableSplitViewResizing: false,
      renderSideBySide: false,
      readOnly: true,
      minimap: {
        enabled: false,
        side: 'left',
      },
      ignoreTrimWhitespace: false,
      folding: true,
      diffCodeLens: true,
      theme: 'vs-dark',

      /**
       * If the diff editor should only show the difference review mode.
       */
      onlyShowAccessibleDiffViewer: false,
      hideUnchangedRegions: {
        enabled: true,
        revealLineCount: 10,
        minimumLineCount: 1,
        // contextLineCount: 1000,
      },
    }
  );
  diffEditor.setModel({
    original: originalModel,
    modified: modifiedModel,
  });

  return diffEditor;
}
</script>

<style scoped>
.read-the-docs {
  color: #888;
}
</style>
