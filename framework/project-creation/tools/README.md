# 项目创建工具

[框架入口](../../README.md#维护命令)

本目录保存创建器；它读取上一级的唯一复制清单 [project-files.json](../project-files.json)。命令在仓库根目录、使用已确认的 Python 3.12+ 运行；`-B` 禁止生成字节码缓存，参数细节以 `--help` 为准。

## 创建空白项目

```powershell
python -B framework/project-creation/tools/create_project.py --output D:\Games\MyGodotGame
```

创建器按清单预检、复制和重命名，再建立独立 Git 仓库与本地初始提交。目标路径、复制映射、失败处理与执行边界的完整契约见[框架、创建器与项目边界](../../godot-project-manual/foundations/framework-and-project.md#创建器用法)。
