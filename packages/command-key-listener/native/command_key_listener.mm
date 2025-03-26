#import <napi.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <mach/mach_time.h>

// 控制是否输出日志的开关
static bool enableLogging = false;

// 有条件地输出日志的宏
#define LOG_IF_ENABLED(...) do { if (enableLogging) NSLog(__VA_ARGS__); } while(0)

// 转换mach时间到纳秒
uint64_t machTimeToNanoseconds(uint64_t machTime) {
  static mach_timebase_info_data_t timebase;
  if (timebase.denom == 0) {
    mach_timebase_info(&timebase);
  }
  return machTime * timebase.numer / timebase.denom;
}

// 全局状态变量
typedef struct {
  bool isListening;
  uint64_t lastCommandKeyDown;
  uint64_t doublePressThreshold;
  uint64_t maxWaitThreshold;
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
  .maxWaitThreshold = 600000000,     // 600ms 转换为纳秒，最大等待时间
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
  
  // 检查是否有第二个参数来启用日志
  if (info.Length() > 1 && info[1].IsBoolean()) {
    enableLogging = info[1].As<Napi::Boolean>().Value();
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
  LOG_IF_ENABLED(@"开始设置键盘监听器...");
  
  // 添加本地修饰键监听器
  state.localFlagsMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^NSEvent *(NSEvent *event) {
    // 只关心Command键
    if (event.keyCode == 55 || event.keyCode == 54) {
      // 判断Command键是按下还是释放
      bool isCommandKeyDown = (event.modifierFlags & NSEventModifierFlagCommand) != 0;
      
      LOG_IF_ENABLED(@"Command键%@", isCommandKeyDown ? @"按下" : @"释放");
      
      if (isCommandKeyDown) {
        // Command键按下
        uint64_t currentMachTime = mach_absolute_time();
        uint64_t currentTimeNs = machTimeToNanoseconds(currentMachTime);
        
        if (state.lastCommandKeyDown > 0) {
          uint64_t elapsedNs = currentTimeNs - machTimeToNanoseconds(state.lastCommandKeyDown);
          
          // 检查是否超过了最大等待时间
          if (elapsedNs > state.maxWaitThreshold) {
            // 超过最大等待时间，视为新的第一次按下
            LOG_IF_ENABLED(@"超过最大等待时间(%.2f秒)，重新开始计时", (double)elapsedNs / 1000000000.0);
            state.lastCommandKeyDown = currentMachTime;
          } else if (elapsedNs < state.doublePressThreshold) {
            // 在有效时间内，双击检测成功
            LOG_IF_ENABLED(@"检测到Command键双击事件，间隔：%.2f毫秒", (double)elapsedNs / 1000000.0);
            if (state.tsfn) {
              LOG_IF_ENABLED(@"调用JavaScript回调函数");
              state.tsfn.NonBlockingCall();
            }
            state.lastCommandKeyDown = 0;
          } else {
            // 间隔太长，记录为第一次按下
            state.lastCommandKeyDown = currentMachTime;
            LOG_IF_ENABLED(@"重置并记录首次Command键按下时间，上次间隔：%.2f毫秒", (double)elapsedNs / 1000000.0);
          }
        } else {
          // 第一次按下
          state.lastCommandKeyDown = currentMachTime;
          LOG_IF_ENABLED(@"记录首次Command键按下时间");
        }
      } else {
        // Command键释放，但不重置lastCommandKeyDown，以便检测双击
        LOG_IF_ENABLED(@"Command键释放，等待可能的双击");
      }
    }
    
    return event;
  }];
  
  // 添加全局修饰键监听器
  state.globalFlagsMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^(NSEvent *event) {
    // 只关心Command键
    if (event.keyCode == 55 || event.keyCode == 54) {
      // 判断Command键是按下还是释放
      bool isCommandKeyDown = (event.modifierFlags & NSEventModifierFlagCommand) != 0;
      
      LOG_IF_ENABLED(@"Command键%@（全局）", isCommandKeyDown ? @"按下" : @"释放");
      
      if (isCommandKeyDown) {
        // Command键按下
        uint64_t currentMachTime = mach_absolute_time();
        uint64_t currentTimeNs = machTimeToNanoseconds(currentMachTime);
        
        if (state.lastCommandKeyDown > 0) {
          uint64_t elapsedNs = currentTimeNs - machTimeToNanoseconds(state.lastCommandKeyDown);
          
          // 检查是否超过了最大等待时间
          if (elapsedNs > state.maxWaitThreshold) {
            // 超过最大等待时间，视为新的第一次按下
            LOG_IF_ENABLED(@"超过最大等待时间(%.2f秒)，重新开始计时（全局）", (double)elapsedNs / 1000000000.0);
            state.lastCommandKeyDown = currentMachTime;
          } else if (elapsedNs < state.doublePressThreshold) {
            // 在有效时间内，双击检测成功
            LOG_IF_ENABLED(@"检测到Command键双击事件（全局），间隔：%.2f毫秒", (double)elapsedNs / 1000000.0);
            if (state.tsfn) {
              LOG_IF_ENABLED(@"调用JavaScript回调函数");
              state.tsfn.NonBlockingCall();
            }
            state.lastCommandKeyDown = 0;
          } else {
            // 间隔太长，记录为第一次按下
            state.lastCommandKeyDown = currentMachTime;
            LOG_IF_ENABLED(@"重置并记录首次Command键按下时间（全局），上次间隔：%.2f毫秒", (double)elapsedNs / 1000000.0);
          }
        } else {
          // 第一次按下
          state.lastCommandKeyDown = currentMachTime;
          LOG_IF_ENABLED(@"记录首次Command键按下时间（全局）");
        }
      } else {
        // Command键释放，但不重置lastCommandKeyDown，以便检测双击
        LOG_IF_ENABLED(@"Command键释放（全局），等待可能的双击");
      }
    }
  }];

  // 保留原有的KeyDown监听器（用于捕获常规键盘事件），但不输出日志
  state.localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
    return event;
  }];
  
  // 添加全局监听器（整个系统），但不输出日志
  state.globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^(NSEvent *event) {
    // 不输出日志
  }];
  
  state.isListening = (state.localFlagsMonitor != nil || state.globalFlagsMonitor != nil);
  LOG_IF_ENABLED(@"Command键双击监听器已%@", state.isListening ? @"启动" : @"启动失败");
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
  
  LOG_IF_ENABLED(@"Command键双击监听器已停止");
  return Napi::Boolean::New(env, true);
}

// 设置是否启用日志
Napi::Value SetLogging(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  
  if (info.Length() < 1 || !info[0].IsBoolean()) {
    Napi::TypeError::New(env, "Boolean expected as first argument").ThrowAsJavaScriptException();
    return env.Undefined();
  }
  
  enableLogging = info[0].As<Napi::Boolean>().Value();
  return env.Undefined();
}

// 初始化模块
Napi::Object Init(Napi::Env env, Napi::Object exports) {
  LOG_IF_ENABLED(@"初始化Command键双击监听器模块");
  exports.Set("start", Napi::Function::New(env, Start));
  exports.Set("stop", Napi::Function::New(env, Stop));
  exports.Set("setLogging", Napi::Function::New(env, SetLogging));
  return exports;
}

NODE_API_MODULE(command_key_listener, Init) 