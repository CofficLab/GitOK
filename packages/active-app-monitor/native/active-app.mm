#import <AppKit/AppKit.h>
#import <napi.h>

/**
 * 获取当前活跃的应用信息
 */
Napi::Value GetFrontmostApplication(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();

    @autoreleasepool {
        NSRunningApplication* frontmostApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
        if (frontmostApp) {
            Napi::Object result = Napi::Object::New(env);
            result.Set("name", [frontmostApp.localizedName UTF8String]);
            result.Set("bundleId", [frontmostApp.bundleIdentifier UTF8String]);
            result.Set("bundlePath", [frontmostApp.bundleURL.path UTF8String]);
            result.Set("processId", (double)frontmostApp.processIdentifier);
            return result;
        }
    }

    return env.Null();
}

/**
 * 初始化模块
 */
Napi::Object Init(Napi::Env env, Napi::Object exports) {
    exports.Set(
        Napi::String::New(env, "getFrontmostApplication"),
        Napi::Function::New(env, GetFrontmostApplication)
    );
    return exports;
}

NODE_API_MODULE(active_app, Init) 