#import <substrate.h>
#import <mach-o/dyld.h>
#import <Foundation/Foundation.h>
#import <string.h>

#define MODLog(format, ...) NSLog(@"[Asphalt8Mod] " format, ##__VA_ARGS__)

// 正しいスライド値を取得する関数
intptr_t get_game_slide() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        // バイナリ名に "Asphalt8" が含まれているか確認
        if (name && strstr(name, "Asphalt8")) {
            MODLog(@"Found Game Binary at Index %d: %s", i, name);
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    MODLog(@"Error: Asphalt8 binary not found in dyld images!");
    return 0;
}

// ---------------------------------------------------------
// Target A: sub_100e506d4 (Value Getter?)
// ---------------------------------------------------------
// Assembly解析:
// int getVal(void *this, int defaultVal) {
//    if (this->unk4 == 3) return this->unk8;
//    return defaultVal;
// }
// 引数が2つ(x0, x1)あるように見えます。
int (*old_sub_100e506d4)(void *thisPointer, int defaultVal);

int new_sub_100e506d4(void *thisPointer, int defaultVal) {
    // 戻り値を取得
    int ret = old_sub_100e506d4(thisPointer, defaultVal);
    
    // 頻繁に呼ばれる可能性が高いので、特定の値（所持金っぽい値）の時だけログを出す
    // ノイズ除去のため 1000以上の値のみログ出力
    if (ret > 1000) {
        MODLog(@"[ValGetter] (Default: %d) Returned: %d", defaultVal, ret);
    }
    
    return ret;
}

// ---------------------------------------------------------
// Target B: sub_10002e0a0 (Currency ID Switch)
// ---------------------------------------------------------
void (*old_sub_10002e0a0)(int id, void *retStr);
void new_sub_10002e0a0(int id, void *retStr) {
    // どのIDがチェックされているかログ出し
    // 0=Credits, 1=Tokens, 2=RealMoney, 3=Mastery, 5=Keys
    MODLog(@"[ID_Check] Checked ID: %d", id);
    old_sub_10002e0a0(id, retStr);
}

%ctor {
    MODLog(@"========== MOD FIXED (ASLR FIX) LOADED ==========");
    
    intptr_t slide = get_game_slide();
    
    if (slide != 0) {
        // Target A
        // 0x100e506d4
        long offsetA = 0x100e506d4;
        MSHookFunction((void *)(slide + offsetA), (void *)new_sub_100e506d4, (void **)&old_sub_100e506d4);
        
        // Target B
        // 0x10002e0a0
        long offsetB = 0x10002e0a0;
        MSHookFunction((void *)(slide + offsetB), (void *)new_sub_10002e0a0, (void **)&old_sub_10002e0a0);
        
        MODLog(@"Hooks installed at slide: 0x%lx", slide);
    } else {
        MODLog(@"Failed to find game slide, hooks aborted.");
    }
}