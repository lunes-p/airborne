#import <substrate.h>
#import <mach-o/dyld.h>
#import <Foundation/Foundation.h>

#define MODLog(format, ...) NSLog(@"[Asphalt8Mod] " format, ##__VA_ARGS__)
#define ASLR_OFFSET(offset) (_dyld_get_image_vmaddr_slide(0) + offset)

// ---------------------------------------------------------
// Target A: sub_100e506d4
// User Report: "called multiple times on load for getting value as int"
// ---------------------------------------------------------
int (*old_sub_100e506d4)(void *thisPointer);
int new_sub_100e506d4(void *thisPointer) {
    int ret = old_sub_100e506d4(thisPointer);
    
    // 戻り値が 0 以外、かつ大きすぎない値（ノイズ除去）の場合にログを出す
    // もし所持金が 5000 くらいなら、このログに出てくるはずです
    if (ret > 0) {
        MODLog(@"[ValGetter] sub_100e506d4 returned: %d", ret);
    }
    
    // テスト: 特定の数値（例: 現在の所持金）が返ってきたら、書き換えてみる
    // ここでは書き換えずにログ確認だけを優先します
    return ret;
}

// ---------------------------------------------------------
// Target B: sub_10002e0a0 (Switch Case for IDs)
// ---------------------------------------------------------
// これが呼ばれるタイミングがわかれば、近くに所持金処理があるはず
void (*old_sub_10002e0a0)(int id, void *retStr); // 引数は推測
void new_sub_10002e0a0(int id, void *retStr) {
    MODLog(@"[ID_Check] sub_10002e0a0 called with ID: %d", id);
    old_sub_10002e0a0(id, retStr);
}

%ctor {
    MODLog(@"========== MOD PHASE 2 LOADED ==========");
    
    // Hook Target A
    MSHookFunction((void *)ASLR_OFFSET(0x100e506d4), (void *)new_sub_100e506d4, (void **)&old_sub_100e506d4);
    
    // Hook Target B
    MSHookFunction((void *)ASLR_OFFSET(0x10002e0a0), (void *)new_sub_10002e0a0, (void **)&old_sub_10002e0a0);
}