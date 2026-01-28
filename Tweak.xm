#import <substrate.h>
#import <mach-o/dyld.h>
#import <Foundation/Foundation.h>
#import <string.h>

#define MODLog(format, ...) NSLog(@"[Asphalt8Mod] " format, ##__VA_ARGS__)

// ゲームバイナリの開始アドレス（Header）を取得する関数
const struct mach_header *get_game_header() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "Asphalt8")) {
            MODLog(@"Found Game Binary at Index %d: %s", i, name);
            // スライド値ではなく、ヘッダ（ロードされたメモリの先頭アドレス）を返す
            return _dyld_get_image_header(i);
        }
    }
    return NULL;
}

// ---------------------------------------------------------
// Target A: sub_100e506d4
// ---------------------------------------------------------

int (*old_sub_100e506d4)(void *thisPointer, int defaultVal);

int new_sub_100e506d4(void *thisPointer, int defaultVal) {
    int ret = old_sub_100e506d4(thisPointer, defaultVal);
    
    // ログ出力: 値の確認
    // 1000 ~ 10億の間ならログに出す（0や-1などのノイズを除く）
    if (ret > 1000 && ret < 1000000000) {
        MODLog(@"[TargetA] Value: %d (Default: %d)", ret, defaultVal);
        
        // ★ここにあなたの現在の所持金（クレジットなど）が出たら、下の行を有効化してください★
        // return 999999999;
    }
    
    return ret;
}

%ctor {
    MODLog(@"========== MOD PHASE 4 LOADED (Addr Fix) ==========");
    
    // 1. バイナリの開始位置を取得
    const struct mach_header *header = get_game_header();
    
    if (header != NULL) {
        // 2. 静的なオフセットを計算 (Hopperのアドレス - 0x100000000)
        // sub_100e506d4 -> 0xe506d4
        uintptr_t staticOffset = 0xe506d4;
        
        // 3. 実際のメモリアドレスを計算 (開始位置 + オフセット)
        void *targetAddr = (void *)((uintptr_t)header + staticOffset);
        
        MODLog(@"Header Addr: %p", header);
        MODLog(@"Static Offset: 0x%lx", staticOffset);
        MODLog(@"Calculated Target: %p", targetAddr);
        
        // 4. フック実行
        MSHookFunction(targetAddr, (void *)new_sub_100e506d4, (void **)&old_sub_100e506d4);
        
        MODLog(@"Hook installed successfully.");
    } else {
        MODLog(@"Error: Game binary header not found.");
    }
}