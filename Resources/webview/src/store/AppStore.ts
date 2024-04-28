import { defineStore } from 'pinia'

export const useAppStore = defineStore('app-store', {
    state: () => {
        return {
            original: "333",
            modified: "e333"
        }
    },

    actions: {
        setOriginal: function (data: string) {
            console.log('🍋 AppStore: setOriginal')
            this.original = data
        },
        setModified: function (data: string) {
            console.log('🍋 AppStore: setModified')
            this.modified = data
        },
    },
})