import { ref } from 'vue';

export function useClipboard() {
  const isCopied = ref(false);
  const error = ref<string | null>(null);

  const copyToClipboard = async (text: string) => {
    if (!text) return;

    try {
      await navigator.clipboard.writeText(text);
      isCopied.value = true;
      error.value = null;
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      isCopied.value = false;
      return false;
    }
  };

  return {
    isCopied,
    error,
    copyToClipboard,
  };
}
