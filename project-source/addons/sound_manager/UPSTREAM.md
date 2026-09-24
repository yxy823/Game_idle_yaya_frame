# SoundManager 来源

来自 [nathanhoad/godot_sound_manager](https://github.com/nathanhoad/godot_sound_manager/tree/1c041582db806a0d0edad77111d1fb7a009346ef)， 固定提交 `1c041582db806a0d0edad77111d1fb7a009346ef`，许可见 [LICENSE](LICENSE)。 `plugin.cfg` 的 `2.6.2` 不足以唯一定位本提交。

复制上游 `addons/sound_manager/` 的 GDScript、UID、插件配置与许可，未修改上游代码； 本项目使用 GDScript，省略可选 `SoundManager.cs` 和对应 UID。

首期工作台通过 `components/feedback/audio_playback.gd` 使用局部播放器池。 默认不启用本插件、不注册 `SoundManager` Autoload，也不改变总线音量。 这是非空间短音效接入，不表示已提供音乐交叉淡化、空间音频或专业分析界面。 如项目已有音频服务，在该薄封装处接入；不要同时启动两套全局音频管理。
