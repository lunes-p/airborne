# Asphalt 8 2.6.0i (July 27, 2016) hacking report

intended for offline use (app didn't even connect to the server)

## why 2.6.0?
It's the oldest version I could install on iOS 14.8.1. Requires iOS 12 or later.

## current progress
- use AppStore++ or MuffinStore to download v2.6.0, use TrollDecrypt to turn into IPA
- open IPA in LiveContainer and it works
- free shopping and credit mode DOES work via binary patching (Hex Fiend)

## what about modding?
- iGameGod: it will inject but broken
- save edit: need to edit both profile and localprofile, could be signed
- existing tweak ([link](https://www.ios-repo-updates.com/repository/bigboss/package/com.athios.asphalt8/)): released in August 27, 2015, (Inf. Nitro, No Speed Limit, No Car Crash, Gate Drift Points Hack), doesn't work for 2.6.0
- static analysis with Hopper Disassembler: tedious but the best approach
- writing tweak for 2.6.0 with theos: hard but might be possible, some CT tweaks might not be possible to port, Memory Patching is more stable. patched successfully but wasn't effective
- dynamic analysis with lldb & debugserver: failed because it checks timing, https://bryce.co/undebuggable/, needs binary patching for bypassing ptrace
- binary patching: also tedious; have to sign with ldid, pack as IPA, reinstall with TrollStore every time because replacing binary isn't enough

## tweak progress
### tips
- https://github.com/itsPow45/iOS-Jailed-Runtime-Offset-Patching-and-Hooking/blob/main/Tweak.xm
- no symbol - only offsets will work
- use Hopper address directly
- no XRef - search for VTable, use Little Endian to find the entry, use closest XRef (pointer)

### targets:
- Credits: insane amount of credits
- Credits/Money Mode: purchase anything with credit, no tokens
- Pro All Cars: Max out every cars
- No crash

### sub_10002d9d0
finally! initial free shopping (broke upgrade) (offset: 186832)

`F6 57 BD A9 F4 4F 01 A9` to `C0 03 5F D6 1F 20 03 D5`

### sub_10002d8b8
token to credit tweak (offset: 186552)

`00 30 40 B9 C0 03 5F D6` to `00 00 80 52 C0 03 5F D6`

### symbol notes:
- sub_1000ec564: for loading/initializing car data?
- sub_10002e0a0: revealed currency ID "treasure map"
- sub_100e506d4: called multiple times on load for getting value as int
- sub_1001a823c: DO NOT TOUCH which currency to use for payment
- sub_100311cb0: constructor for purchase UI?
- sub_1000e6b60: final check before purchase?
- sub_101198a44: decides if item is purchasable/unlockable, apparently this is called every frame, and bad modification will wreck the app (offset: 18451012)
- sub_10002d8c0: somehow it enabled 0%OFF sale for everything (offset: 186560)

"BL sub_100843bb8" (probably checking money in possession, offset: 8666040):
- sub_100328880
- sub_100328cbc
- sub_100478cb4
- sub_10059bed4
- sub_1007ac55c

### debugger killer:
- imp___stubs__syscall: EntryPoint+44 is the ptrace killer
- sub_100029674, sub_100e0c968, sub_100fe5ec8: could be jb detection
