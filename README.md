# Λ-1 Emulator
　月刊RAM 1978年8月号から1980年9月号にわたって連載され、後に「マイコン手づくり塾 -コンピュータ技術を完全マスター-」として参考本としても出版されたマイコンΛ-1のエミュレータを作ってみました。

　メインパネルからスイッチを操作することでプログラムの入力、実行が可能ですのでどなたでも遊べますが、操作方法などはやはり「マイコン手づくり塾 -コンピュータ技術を完全マスター-」が手元にあった方が判りやすいです。

　「マイコン手づくり塾 -コンピュータ技術を完全マスター-」は国立国会図書館デジタルコレクションでも公開されており(2026年10月14日現在)、利用者登録すれば閲覧が可能です。

　また拡張できる限りのRAM、CMT、電子オルガン、カラーTVディスプレイ、フルキーボード、プリンタインタフェースなど「マイコン手づくり塾」で紹介されている機能をすべて取り込んでみました。

　「マイコン手づくり塾」で紹介されているCHICK-BUG、UTILITIES、電大版Tiny-Basic、Assemblerなどのバイナリファイルを用意できればすべて動きます。

## 使い方
　起動した状態でメインパネルが操作可能です。

![Ramda-1](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/MAIN%20PANEL.png)

　DATA-SW、ADDRESS-SWを操作してアドレスを設定してからDATA-SW、WRITE-SW、READ-SWを操作してプログラムを入力します。

　入力し終わったらもう一度DATA-SW、ADDRESS-SWでプログラム実行開始アドレスをセットしてGO-SWで実行です。

　メインパネルがアクティブなときにはメインパネルのスイッチ操作がWindowsキーボードで操作できます。

|メインパネルの操作|Windowsキー|
| ------------ | ------------ |
|DATA 7～0を切替（左から順）|F1～F8|
|ADDRESS SET|F9|
|READ|F10|
|WRITE|F11|
|GO／HALTを切替|F12|

### ファイル入出力
　バイナリファイルの読込、保存の方法は二通りの方法があります。

![Memory INOUT](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/Memory%20INOUT.png)

#### RAMバイナリ入出力
　単純なバイナリファイルを直接RAMにロード、RAMからセーブします。
##### バイナリファイルをRAMへLOAD
　LOAD開始アドレスを16進数4桁で指定して拡張子binのバイナリファイルをLOADします。
##### RAMの内容をバイナリファイルへSAVE
　セーブ開始アドレス、セーブ終了アドレスを16進数4桁で指定し、保存するファイル名を指定してください。拡張子はbinになります。

#### カセット/WAV
　CHICK-BUGのLコマンド、Sコマンドを使用するときのファイルを選択します。

　ファイルはWAVファイルとなります。

![CMT](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/CMT.png)

### 64KRAMモニタ
　RAMの内容が確認できます。表示のみで書き換えることはできません。

![Memory Disp](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/Memory%20Disp.png)

### プリンタ
　拡張PIA#2へのプリンタ出力がそのまま表示されます。

　出力ファイルを指定して「受信データをテキストファイルに書き出す」をチェックすればテキストファイルとして保存も出来ます。

![Printer](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/Printer.png)

### 電子オルガン
　このパネルを表示しなくても電子オルガンは接続済みです。手動でオルガンから音を出すためのものです。

![Organ](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/Organ.png)

## ソフトウェア
### CHICK-BUG
　Ramda1Emulator.exeと同じフォルダにCHICK-BUG.binがある状態で起動するとアドレスがFE78にセットされ、カラーTVディスプレイのウィンドウが表示されます。

![CHICK-BUG1](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/CHICK-BUG1.png)

　この状態でGO-SWを操作するとCHICK-BUGが起動し、ATNキーを押すことでコマンド待ちになります。

![CHICK-BUG2](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/CHICK-BUG2.png)

![CHICK-BUG3](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/CHICK-BUG3.png)

　操作はパソコンのキーボードか、又は表示メニューから仮想フルキーボードを表示させて操作することも出来ます。

　メインパネル、カラーTVディスプレイ、仮想フルキーボード、RAMモニタのいずれかがアクティブなときにはWindowsキーボードから操作が出来ます。

　Windowsキーボードにはないキーの割り当ては次の通りです。
|仮想フルキーボート|Windowsキー|
| ------------ | ------------ |
|ATN|Home|
|LF(0Ah)|下向きカーソルキー|
|HTAB(09h)|Tabキー又は上向きカーソルキー|

　なお、WindowsキーボードのENTERはCR(0Dh)の入力となります。LF(0Ah)と混同しないにしてください。

### Assembler
　アセンブラの起動には巻末付録のユーティリティプログラムが必要です。

　Ramda1Emulator.exeと同じフォルダにAssembler.binとUTILITY.binを置いてRamda1Emulatorを起動させると自動的に読み込みます。

　CHICK-BUGが起動したらGコマンドでA000hにジャンプするとメニューが表示されるので5を選択するとAssemblerが起動します。

![Assembler1](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/Assembler1.png)

![Assembler2](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/Assembler2.png)

![Assembler3](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/Assembler3.png)

### 電大版Tiny-Basic
　電大版Tiny-Basicの起動には巻末付録のユーティリティプログラムが必要です。

　Ramda1Emulator.exeと同じフォルダにTinyBasic.binを置いてRamda1Emulatorを起動させると自動的に読み込みます。

　CHICK-BUGが起動したらGコマンドでA000hにジャンプするとメニューが表示されるので6を選択すると電大版Tiny-Basicが起動します。

![Tint-Basic](https://github.com/yanataka60/Ramda-1-Emulator/blob/main/PNG/Tiny-Basic.png)
