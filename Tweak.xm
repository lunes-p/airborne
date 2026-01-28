#import <substrate.h>
#import <mach-o/dyld.h>
#import <Foundation/Foundation.h>

// ログを見やすくするためのマクロ
#define MODLog(format, ...) NSLog(@"[Asphalt8Mod] " format, ##__VA_ARGS__)
#define ASLR_OFFSET(offset) (_dyld_get_image_vmaddr_slide(0) + offset)

// ---------------------------------------------------------
// Target: sub_100843bb8 (所持金チェックと思われる関数)
// ---------------------------------------------------------
int (*old_sub_100843bb8)(void *thisPointer);

int new_sub_100843bb8(void *thisPointer) {
    // 1. 関数が呼ばれたことをログ出力
    // これが出なければ、アドレス間違い or この関数は使われていない
    MODLog(@"target_function (sub_100843bb8) CALLED!");

    // 2. オリジナルの戻り値（現在の所持金）を取得
    int originalValue = old_sub_100843bb8(thisPointer);

    // 3. オリジナルの値をログ出力
    // ここでゲーム画面の表示と一致する数値が出れば、ビンゴ（正解）です
    MODLog(@"Original Return Value: %d", originalValue);

    // 4. テストとして数値を固定してみる
    // 成功すれば表示がこの値になるはず
    return 999999999;
}

// ---------------------------------------------------------
// Sanity Check (生存確認用)
// ---------------------------------------------------------
// ゲーム起動時に必ず呼ばれるであろう場所（AppDelegateなど）か、
// コンストラクタでログを吐き、Dylibのロード自体は成功しているか確認
%ctor {
    MODLog(@"========== MOD LOADED ==========");
    MODLog(@"ASLR Slide: 0x%lx", _dyld_get_image_vmaddr_slide(0));
    MODLog(@"Target Address: 0x%lx", ASLR_OFFSET(0x100843bb8));

    // フック設定
    MSHookFunction(
        (void *)ASLR_OFFSET(0x100843bb8), 
        (void *)new_sub_100843bb8, 
        (void **)&old_sub_100843bb8
    );
    MODLog(@"Hook installed.");
}