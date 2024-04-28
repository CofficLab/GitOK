const webkit = {
    pageLoaded() {
        if (!('webkit' in window)) {
            return
        }

        console.log('🍎 WebKit: 调用 WebKit 以通知 Swift 页面加载完成')
        try {
            ; (window as any).webkit.messageHandlers.sendMessage.postMessage({
                channel: "pageLoaded"
            })
        } catch (e) {
            console.log('WebKit: 调用 WebKit 以通知 Swift 页面加载完成，失败', e)
        }
    }
}

export default webkit