#import <Foundation/Foundation.h>
#import <substrate.h>
#import <dlfcn.h>

// `sys/ptrace.h`がプライベートSDKにしか含まれないため、ここで直接定義する
#define PT_DENY_ATTACH 31

// REMOVED: The following lines were causing redefinition errors
// typedef int pid_t;
// typedef void* caddr_t;
// The SDK already knows what pid_t and caddr_t are.

// ptraceの引数の型もヘッダに頼らず、基本的な型で定義する
// --> The types pid_t and caddr_t are now provided by the SDK headers.
//     We just need to use them.

// 元のptrace関数のポインタを保存する変数
static int (*original_ptrace)(int _request, pid_t _pid, caddr_t _addr, int _data);

// ptraceを置き換える自作関数
int replaced_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data) {
    if (_request == PT_DENY_ATTACH) {
        NSLog(@"[AntiAntiDebug] ptrace(PT_DENY_ATTACH) called and BLOCKED!");
        return 0;
    }
    
    return original_ptrace(_request, _pid, _addr, _data);
}

// Tweakがロードされたときに実行されるコンストラクタ
%ctor {
    NSLog(@"[AntiAntiDebug] Initializing ptrace hook...");
    
    void* ptrace_ptr = dlsym(RTLD_DEFAULT, "ptrace");
    
    if (ptrace_ptr) {
        MSHookFunction(ptrace_ptr, (void*)&replaced_ptrace, (void**)&original_ptrace);
        NSLog(@"[AntiAntiDebug] ptrace hook successful!");
    } else {
        NSLog(@"[AntiAntiDebug] Failed to find ptrace function.");
    }
}