# 音频素材

## 格式选择

- 建议：短音效用 WAV，音乐和较长的语音用 Ogg Vorbis。
- 注意：WAV 导入的 `compress/mode` 默认是有损的 Quite OK Audio（QOA）。需要无损时改为 PCM。IMA ADPCM 质量较低，不作为默认选择。
- 不把一种有损格式转码为另一种有损格式，保留质量最高的源文件。

## 导入设置

- `force/8_bit` 只在有意追求低保真效果时开启。
- `force/mono` 只在立体声信息不重要时开启。
- 开启 `force/max_rate` 降低采样率前，确认不会损失需要的高频。
- `edit/normalize` 只调整这个文件的增益，不代替在音频总线中平衡音量。
- `edit/trim` 会裁掉首尾的静音，改变时间线和循环点。需要循环或与动画对齐的音频不开启。
- 循环由导入设置决定：WAV 使用 `edit/loop_mode`、`edit/loop_begin`、`edit/loop_end`，Ogg Vorbis 使用 `loop` 和 `loop_offset`。设置后用实际导入的结果试听循环衔接处。
