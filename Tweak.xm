#import <substrate.h>
#import <mach-o/dyld.h>
#import <Foundation/Foundation.h>

// ASLRスライド取得用マクロ
#define ASLR_OFFSET(offset) (_dyld_get_image_vmaddr_slide(0) + offset)

// ---------------------------------------------------------
// 1. 通貨無限ハック (Infinite Currencies)
// ---------------------------------------------------------
// Target: sub_100843bb8
// この関数はループして現在の所持金を計算して返しているように見えます。
// 戻り値を強制的に書き換えます。

int (*old_sub_100843bb8)(void *thisPointer);
int new_sub_100843bb8(void *thisPointer) {
    // オリジナルの処理を実行（クラッシュ回避のため念のため呼ぶ）
    // int originalAmount = old_sub_100843bb8(thisPointer);
    
    // 常に約10億を返す
    return 999999999;
}

// ---------------------------------------------------------
// 2. ステータス操作 / ニトロ (Stats / Nitro)
// ---------------------------------------------------------
// Target: sub_1000ec564 内で呼ばれている sub_100e3a040
// この関数は (Object*, StringObject*) を受け取り、数値を返している可能性が高いです。
// 文字列キーを判定して、特定の能力値だけ書き換えます。

float (*old_sub_100e3a040)(void *thisPointer, void *stringObj);
float new_sub_100e3a040(void *thisPointer, void *stringObj) {
    float originalValue = old_sub_100e3a040(thisPointer, stringObj);
    
    // stringObjはGameloft独自のStringクラスの可能性がありますが、
    // NSString* にキャストして中身が見れるか試します。
    // 見れない場合、単純に値をブーストする実験が必要です。
    
    // 安全のため、ここでのNSString変換はクラッシュのリスクがあります。
    // まずは単純なログ出力か、全値を2倍にするなどのテストが有効です。
    
    // 例: 全ての取得値を2倍にする（TopSpeedなども含むためゲームスピードが上がるかも）
    // return originalValue * 2.0f; 
    
    return originalValue;
}

// ---------------------------------------------------------
// 3. 車のアンロック (Unlock Cars) - 実験的
// ---------------------------------------------------------
// sub_1000ec564 の最後の方で AvailableForPlayer をセットしています。
// 直接構造体のメモリを書き換えるのはタイミングが難しいので、
// 一旦保留するか、MSHookMemoryで特定のチェック命令を潰すのが安全です。

// Target: loc_1000ecbe0 (AvailableForPlayerのチェック?)
// 0x1000ecbe0: cbz x8, loc_1000ecc08
// これをNOPにすればチェックをスルーできるかもしれませんが、
// オフセットがズレると危険なので今回は関数フックに集中します。

// ---------------------------------------------------------
// Constructor
// ---------------------------------------------------------
%ctor {
    NSLog(@"[Asphalt8Mod] Injected!");

    // 通貨フック
    MSHookFunction(
        (void *)ASLR_OFFSET(0x100843bb8), 
        (void *)new_sub_100843bb8, 
        (void **)&old_sub_100843bb8
    );
    
    // ステータス取得関数のフック（必要ならコメントアウトを外してアドレスを確認してください）
    /*
    MSHookFunction(
        (void *)ASLR_OFFSET(0x100e3a040), 
        (void *)new_sub_100e3a040, 
        (void **)&old_sub_100e3a040
    );
    */
}