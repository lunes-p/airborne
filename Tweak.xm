#import <substrate.h>
#import <mach-o/dyld.h>
#import <Foundation/Foundation.h>
#import <string.h>

// -----------------------------------------------------------------------
// 設定: Hopperで見たそのままのアドレス（Static Address）
// -----------------------------------------------------------------------
// sub_1001a823c (通貨判定)
#define TARGET_STATIC_ADDR  0x1001a823c

// -----------------------------------------------------------------------
// Helper: 正しいメモリアドレスを計算する関数 (ASLR対応)
// -----------------------------------------------------------------------
static uintptr_t get_real_address(uintptr_t static_address) {
    uint32_t count = _dyld_image_count();
    
    // 全イメージを走査
    for (uint32_t i = 0; i < count; i++) {
        const char *image_name = _dyld_get_image_name(i);
        
        // パスに "Asphalt8" が含まれる、かつ ".dylib" ではない（実行ファイル本体）を探す
        if (strstr(image_name, "Asphalt8") != NULL) {
            
            // ASLRスライド量（起動ごとのズレ）を取得
            intptr_t slide = _dyld_get_image_vmaddr_slide(i);
            
            // 計算式: 実アドレス = スライド量 + 静的アドレス
            uintptr_t real_address = slide + static_address;
            
            NSLog(@"[Asphalt8Mod] Found Binary: %s", image_name);
            NSLog(@"[Asphalt8Mod] ASLR Slide: 0x%lx", slide);
            NSLog(@"[Asphalt8Mod] Static Addr: 0x%lx -> Real Addr: 0x%lx", static_address, real_address);
            
            return real_address;
        }
    }
    
    NSLog(@"[Asphalt8Mod] Error: Target binary not found!");
    return 0;
}

// -----------------------------------------------------------------------
// 1. Money Mode (Currency Swap)
// -----------------------------------------------------------------------

// オリジナルの関数ポインタ
int (*old_GetItemType)(void* arg0);

// フック関数
int new_GetItemType(void* arg0) {
    // オリジナルの値を一旦取得
    int type = old_GetItemType(arg0);

    // 4:Tokens (Hard Currency) -> 0:Credits に偽装
    if (type == 4) {
        return 0; 
    }
    
    return type;
}

// -----------------------------------------------------------------------
// Main Constructor
// -----------------------------------------------------------------------

%ctor {
    NSLog(@"[Asphalt8Mod] === Injection Started ===");

    // アドレス計算
    uintptr_t targetAddr = get_real_address(TARGET_STATIC_ADDR);
    
    if (targetAddr != 0) {
        // フック実行
        MSHookFunction((void*)targetAddr, (void*)new_GetItemType, (void**)&old_GetItemType);
        NSLog(@"[Asphalt8Mod] Hook Success!");
    } else {
        NSLog(@"[Asphalt8Mod] Hook Failed: Address is 0");
    }
}