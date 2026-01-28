#import <substrate.h>
#import <mach-o/dyld.h>
#import <Foundation/Foundation.h>
#import <string.h>

#define MODLog(format, ...) NSLog(@"[Asphalt8Mod] " format, ##__VA_ARGS__)

// ゲームバイナリのスライド値を取得
intptr_t get_game_slide() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "Asphalt8")) {
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

// ---------------------------------------------------------
// Target A: sub_100e506d4
// User Report: "called multiple times on load for getting value as int"
// ---------------------------------------------------------
// Hopper Address: 0x100e506d4
// Image Base: 0x100000000 (通常)
// Actual Offset: 0xe506d4
// ---------------------------------------------------------

int (*old_sub_100e506d4)(void *thisPointer, int defaultVal);

int new_sub_100e506d4(void *thisPointer, int defaultVal) {
    // まずはオリジナルの値を取得
    int ret = old_sub_100e506d4(thisPointer, defaultVal);
    
    // ログ出力: 所持金らしき値（例: 1000以上）が出たら記録
    // 頻繁に呼ばれるとログが溢れるので条件をつける
    if (ret > 1000 && ret < 1000000000) {
        MODLog(@"[TargetA] Value: %d (Default: %d)", ret, defaultVal);
        
        // 【テスト】もしこれが所持金なら、ここで書き換えれば無限になるはず
        // ログであなたの所持金と一致する値が出たら、次の行のコメントを外してください
        // return 999999999;
    }
    
    return ret;
}

%ctor {
    MODLog(@"========== MOD PHASE 3 LOADED (Target A Only) ==========");
    
    intptr_t slide = get_game_slide();
    if (slide != 0) {
        // HopperのアドレスからImageBase(0x100000000)を引いてオフセットを算出するのが定石
        // アドレス計算: Slide + (HopperAddr - ImageBase)
        // もしHopperAddrがオフセットそのものなら Slide + HopperAddr
        // 前回のログを見る限り、Hopperのアドレスは「0x100000000ベース」のようなので:
        
        uint64_t hopperAddr = 0x100e506d4;
        uint64_t imageBase = 0x100000000;
        uint64_t offset = hopperAddr - imageBase;
        
        void *targetAddr = (void *)(slide + offset);
        
        MODLog(@"Hooking Target A at: %p (Offset: 0x%llx)", targetAddr, offset);
        
        MSHookFunction(targetAddr, (void *)new_sub_100e506d4, (void **)&old_sub_100e506d4);
        
    } else {
        MODLog(@"Error: Game binary not found.");
    }
}