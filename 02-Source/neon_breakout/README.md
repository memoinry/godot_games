# 霓虹突围 / NEON BREAKOUT

**作者：memory**

一个可从菜单开始、完成六波战斗、选择强化、击败最终 Boss 并保存记录的 Godot 单人射击游戏。首版交付，适合继续迭代为个人作品集项目。

## 立即试玩

返回作品集根目录，双击 `Start-Portfolio.cmd` 并选择 NEON BREAKOUT；或双击 `01-Play/Play-NeonBreakout.cmd`。

## 打开工程

1. 使用 **Godot 4.4.1 标准版或兼容的 Godot 4.x 版本**，不需要 .NET。
2. 在项目管理器中导入本文件夹的 `project.godot`。
3. 第一次打开等待中文字体导入，然后按 **F5** 运行游戏。
4. 渲染器使用 Compatibility，目标为支持 OpenGL 3.3 的 Windows x64 电脑。

## 操作

| 操作 | 按键 |
|---|---|
| 移动 | WASD / 方向键 |
| 瞄准和持续射击 | 鼠标 / 按住左键 |
| 相位冲刺，短暂无敌 | 空格；静止时朝准星，否则朝移动方向 |
| 切换脉冲 / 霰射 / 磁轨 | 1 / 2 / 3，或底部按钮 |
| 选择波次强化 | 鼠标按钮 / 1、2、3 |
| 暂停 / 继续 | Esc / P |
| 全屏 | F11，或设置界面 |
| 静音 / 恢复 | M |

## 游戏规则

- 六个常规区域，每波持续生成敌人 45 秒；倒计时结束后，消灭剩余敌人即可过关。
- 每波结束自动修复 10 点护甲，并回收场上尚未拾取的补给，然后从三个不同强化中选择一个。
- 第七区挑战「母核 / THE WARDEN」。生命值降至 66% 和 33% 时切换阶段；击破即获胜。
- 护甲归零即失败。失败或胜利后可以立即重开。
- 连续击杀维持 3.5 秒连击，每 8 次连击提升一档倍率，最高 ×5。
- 绿色十字维修护甲；青色脉冲环对敌人造成伤害并清除敌弹。
- 自动保存最高分、成功次数、出击次数与设置，不保存未完成战局。
- 一局时长随火力、清场速度和强化选择变化，通常约 6–8 分钟；不存在联网或付费系统。

## 已完成的系统

完整的菜单、操作说明、设置、战斗 HUD、暂停、强化选择、胜败结算、重开、制作信息；三种武器、四类普通敌人、三阶段 Boss、冲刺、补给、连击计分、粒子、拖尾、屏幕震动、原创合成音效和轻量氛围音，以及本地存档。

## 代码结构

| 文件 | 负责内容 |
|---|---|
| `scenes/main.tscn` | 游戏入口 |
| `scripts/main.gd` | 应用状态、全部界面、按键事件、结算 |
| `scripts/arena.gd` | 波次、碰撞、刷怪、子弹、补给、强化、背景与特效 |
| `scripts/player.gd` | 玩家移动、三种武器、冲刺、护甲 |
| `scripts/enemy.gd` | 四种敌人 AI 与 Boss 三阶段攻击 |
| `scripts/sound_bank.gd` | 运行时合成音效与氛围音 |
| `scripts/save_data.gd` | ConfigFile 存档与设置 |
| `scripts/menu_art.gd` | 程序绘制的机库封面插图 |
| `assets/` | 中文字体、字重资源、图标、许可 |
| `tests/` | 整合测试、完整战斗模拟、截图工具；不进入发布包 |

对象行为与界面分离；子弹使用数据数组和线段碰撞检查，避免高速弹丸穿过目标。这个小体量版本没有引入 ECS、复杂插件或网络依赖。

## 怎样继续改成自己的作品

项目作者已统一署名为 **memory**。可以在 `project.godot` 修改游戏名称，在 `scripts/main.gd` 修改封面和制作信息，再逐步替换自己的画面和内容。不要删除第三方字体或引擎的许可。

- 玩家基础速度、武器伤害、射速、冲刺：`scripts/player.gd`。
- 波次时长和数量、强化池：`scripts/arena.gd` 开头的常量及 `UPGRADES`。
- 敌人属性和攻击、Boss 血量：`scripts/enemy.gd`。
- 界面布局、颜色：`scripts/main.gd`。
- 菜单飞船插图：`scripts/menu_art.gd`。

当前 UI 按六个常规区和第七区 Boss 编写；如果修改波次数量，请同步修改 `main.gd` 的 HUD 总区数、提示文字及 `arena.gd` 的波次提示列表。

建议先亲自试玩并调整难度，再加入自己独有的敌人或一项新机制，并记录实现过程。作品集应如实注明 AI 协作及玩法参考，并只把自己理解、修改和验证的内容列为自己的具体工作。

## 测试

```text
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/combat_soak.gd
```

详细结果见 `VERIFICATION.md`。自动战斗使用无敌机器人验证流程，不代表真人难度测试。

## 重新导出

在 Godot 安装与编辑器版本一致的官方 Export Templates，使用已提供的 `Windows Desktop` 导出预设。默认嵌入 PCK，产出独立 `.exe`。也可执行：

```text
godot --headless --path . --export-release "Windows Desktop" ../NeonBreakout-Windows/NeonBreakout.exe
```

附带发布包使用 Godot 4.4.1 官方 Windows x64 Release 模板制作，包含自定义飞船图标及 **memory** 文件作者信息，未进行代码签名。重新导出时，如需保留文件图标和版本信息，请在 Godot 编辑器设置中配置 rcedit；或关闭预设中的「Modify Resources」再导出。

## 存档位置

Windows：`%APPDATA%\NeonBreakout\pilot_v1.cfg`。日志也在这个用户数据目录下。工程文件不会被运行中的游戏写入。

## 来源

玩法参考 Jack Rugile 的 [Radius Raid](https://github.com/jackrugile/radius-raid)，本交付是独立编写的 Godot 实现，没有复制或嵌入原版 JavaScript，也不是原作者发布的官方移植。来源和第三方许可见 `THIRD_PARTY.md`。
