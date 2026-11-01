# 作者与第三方来源

项目作者、游戏内署名：**memory**。

## Godot Engine

四款游戏使用 Godot 4.4.1，Compatibility 渲染器。引擎为 MIT 许可。完整许可与第三方版权清单见 [GODOT_LICENSE.txt](../02-Source/neon_breakout/GODOT_LICENSE.txt) 与 [GODOT_COPYRIGHT.txt](../02-Source/neon_breakout/GODOT_COPYRIGHT.txt)，Windows 试玩包亦附带相同文件。

https://godotengine.org/license/

## 字体

《霓虹突围》使用 Noto Sans SC，SIL Open Font License 1.1。原字体版权与许可全文保留在 [FONT_LICENSE.txt](../02-Source/neon_breakout/assets/FONT_LICENSE.txt)。其他三款游戏使用 Godot 的默认界面字体。

## 玩法参考

《霓虹突围》参考 Jack Rugile 的 [Radius Raid](https://github.com/jackrugile/radius-raid)（MIT，Copyright (c) 2014 Jack Rugile），使用独立编写的 Godot 实现，没有嵌入原版 JavaScript 或音频样本，不是原作者发布的官方移植。

贪吃蛇、打砖块和乒乓球为经典规则的独立实现，没有复制其他小游戏的项目代码或图像资源。

## 画面与声音

游戏图形为 GDScript 程序绘制，音效由 `sound_bank.gd` 在运行时合成，不依赖外部图片、音乐录音或音效资源包。代码与界面使用 AI 辅助编写和验证。
