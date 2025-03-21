#import <napi.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <mach/mach_time.h>

// 全局状态变量
typedef struct {
  bool isListening;
  uint64_t lastCommandKeyDown;
  uint64_t doublePressThreshold;
  Napi::ThreadSafeFunction tsfn;
  id localMonitor;
  id localFlagsMonitor;
  id globalMonitor;
  id globalFlagsMonitor;
  bool commandKeyPressed;
} ListenerState;

static ListenerState state = {
  .isListening = false,
  .lastCommandKeyDown = 0,
  .doublePressThreshold = 300000000,  // 300ms 转换为纳秒
  .localMonitor = nil,
  .localFlagsMonitor = nil,
  .globalMonitor = nil,
  .globalFlagsMonitor = nil,
  .commandKeyPressed = false
};

// 启动监听器
Napi::Value Start(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  
  if (info.Length() < 1 || !info[0].IsFunction()) {
    Napi::TypeError::New(env, "Function expected as first argument").ThrowAsJavaScriptException();
    return env.Undefined();
  }
  
  if (state.isListening) {
    Napi::Error::New(env, "Listener already started").ThrowAsJavaScriptException();
    return env.Undefined();
  }
  
  Napi::Function callback = info[0].As<Napi::Function>();
  
  // 创建线程安全函数引用
  state.tsfn = Napi::ThreadSafeFunction::New(
    env,
    callback,
    "CommandKeyListener",
    0,
    1,
    []( Napi::Env ) {
      state.isListening = false;
    }
  );
  
  // 开始监听本地按键事件
  NSLog(@"开始设置键盘监听器...");
  
  // 添加本地修饰键监听器
  state.localFlagsMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^NSEvent *(NSEvent *event) {
    NSLog(@"本地监听器捕获修饰键变化：键码：%hu，修饰键：%lu", 
          event.keyCode,
          (unsigned long)event.modifierFlags);
          
    // 检查是否为Command键 (左右Command键的keyCode分别为55和54)
    if (event.keyCode == 55 || event.keyCode == 54) {
      // 判断Command键是按下还是释放
      bool isCommandKeyDown = (event.modifierFlags & NSEventModifierFlagCommand) != 0;
      
      NSLog(@"Command键%@", isCommandKeyDown ? @"按下" : @"释放");
      
      if (isCommandKeyDown) {
        // Command键按下
        uint64_t currentTime = mach_absolute_time();
        
        if (state.lastCommandKeyDown > 0) {
          uint64_t elapsed = currentTime - state.lastCommandKeyDown;
          if (elapsed < state.doublePressThreshold) {
            // 双击检测成功
            NSLog(@"检测到Command键双击事件");
            if (state.tsfn) {
              NSLog(@"调用JavaScript回调函数");
              state.tsfn.NonBlockingCall();
            }
            state.lastCommandKeyDown = 0;
          } else {
            // 间隔太长，记录为第一次按下
            state.lastCommandKeyDown = currentTime;
            NSLog(@"重置并记录首次Command键按下时间");
          }
        } else {
          // 第一次按下
          state.lastCommandKeyDown = currentTime;
          NSLog(@"记录首次Command键按下时间");
        }
      }
    }
    
    return event;
  }];
  
  // 添加全局修饰键监听器
  state.globalFlagsMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^(NSEvent *event) {
    NSLog(@"全局监听器捕获修饰键变化：键码：%hu，修饰键：%lu", 
          event.keyCode,
          (unsigned long)event.modifierFlags);
          
    // 检查是否为Command键 (左右Command键的keyCode分别为55和54)
    if (event.keyCode == 55 || event.keyCode == 54) {
      // 判断Command键是按下还是释放
      bool isCommandKeyDown = (event.modifierFlags & NSEventModifierFlagCommand) != 0;
      
      NSLog(@"Command键%@（全局）", isCommandKeyDown ? @"按下" : @"释放");
      
      if (isCommandKeyDown) {
        // Command键按下
        uint64_t currentTime = mach_absolute_time();
        
        if (state.lastCommandKeyDown > 0) {
          uint64_t elapsed = currentTime - state.lastCommandKeyDown;
          if (elapsed < state.doublePressThreshold) {
            // 双击检测成功
            NSLog(@"检测到Command键双击事件（全局）");
            if (state.tsfn) {
              NSLog(@"调用JavaScript回调函数");
              state.tsfn.NonBlockingCall();
            }
            state.lastCommandKeyDown = 0;
          } else {
            // 间隔太长，记录为第一次按下
            state.lastCommandKeyDown = currentTime;
            NSLog(@"重置并记录首次Command键按下时间（全局）");
          }
        } else {
          // 第一次按下
          state.lastCommandKeyDown = currentTime;
          NSLog(@"记录首次Command键按下时间（全局）");
        }
      }
    }
  }];

  // 保留原有的KeyDown监听器（用于捕获常规键盘事件）
  state.localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
    NSLog(@"本地监听器捕获键盘事件：%@，键码：%hu，修饰键：%lu", 
          event.charactersIgnoringModifiers, 
          event.keyCode,
          (unsigned long)event.modifierFlags);
    return event;
  }];
  
  // 添加全局监听器（整个系统）
  state.globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^(NSEvent *event) {
    NSLog(@"全局监听器捕获键盘事件：%@，键码：%hu，修饰键：%lu", 
          event.charactersIgnoringModifiers, 
          event.keyCode,
          (unsigned long)event.modifierFlags);
  }];
  
  state.isListening = (state.localFlagsMonitor != nil || state.globalFlagsMonitor != nil);
  NSLog(@"Command键双击监听器已%@", state.isListening ? @"启动" : @"启动失败");
  return Napi::Boolean::New(env, state.isListening);
}

// 停止监听器
Napi::Value Stop(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  
  if (!state.isListening) {
    return Napi::Boolean::New(env, true);
  }
  
  // 移除本地监听器
  if (state.localMonitor) {
    [NSEvent removeMonitor:state.localMonitor];
    state.localMonitor = nil;
  }
  
  // 移除本地修饰键监听器
  if (state.localFlagsMonitor) {
    [NSEvent removeMonitor:state.localFlagsMonitor];
    state.localFlagsMonitor = nil;
  }
  
  // 移除全局监听器
  if (state.globalMonitor) {
    [NSEvent removeMonitor:state.globalMonitor];
    state.globalMonitor = nil;
  }
  
  // 移除全局修饰键监听器
  if (state.globalFlagsMonitor) {
    [NSEvent removeMonitor:state.globalFlagsMonitor];
    state.globalFlagsMonitor = nil;
  }
  
  if (state.tsfn) {
    state.tsfn.Release();
  }
  
  state.isListening = false;
  state.lastCommandKeyDown = 0;
  state.commandKeyPressed = false;
  
  NSLog(@"Command键双击监听器已停止");
  return Napi::Boolean::New(env, true);
}

// 初始化模块
Napi::Object Init(Napi::Env env, Napi::Object exports) {
  NSLog(@"初始化Command键双击监听器模块");
  exports.Set("start", Napi::Function::New(env, Start));
  exports.Set("stop", Napi::Function::New(env, Stop));
  return exports;
}

NODE_API_MODULE(command_key_listener, Init) 