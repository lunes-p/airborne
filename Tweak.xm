#import <substrate.h>
#import <mach-o/dyld.h>
#import <Foundation/Foundation.h>

#define MODLog(format, ...) NSLog(@"[Asphalt8Mod] " format, ##__VA_ARGS__)
#define ASLR_OFFSET(offset) (_dyld_get_image_vmaddr_slide(0) + offset)

// ---------------------------------------------------------
// Target: sub_100e506d4 (Getter)
// ---------------------------------------------------------
// Assembly解析結果: int GetValue(void* this, int defaultValue)
// 第2引数(x1)まで定義する必要があります。

int (*old_sub_100e506d4)(void *thisPointer, int defaultValue);

int new_sub_100e506d4(void *thisPointer, int defaultValue) {
    // オリジナルを呼び出す（正しい引数を渡す）
    int ret = old_sub_100e506d4(thisPointer, defaultValue);

    // ログフィルタリング:
    // 0や1、-1などのよくある値は無視し、
    // 「所持金っぽい値（例: 1000以上）」のときだけログに出す
    if (ret > 1000) {
        // もし現在所持金が 5000 クレジットなら、ここに "5000" が出るはず
        MODLog(@"[ValGetter] sub_100e506d4(ptr=%p, def=%d) returned: %d", thisPointer, defaultValue, ret);
        
        // テスト: ここで値を書き換えてみることも可能
        // return 99999999; 
    }
    
    return ret;
}

%ctor {
    MODLog(@"========== MOD RELOADED (Crash Fix) ==========");
    
    // フック適用
    MSHookFunction(
        (void *)ASLR_OFFSET(0x100e506d4), 
        (void *)new_sub_100e506d4, 
        (void **)&old_sub_100e506d4
    );
}