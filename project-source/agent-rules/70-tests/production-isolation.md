# 测试与生产隔离

本页规定测试代码、文件和配置怎样与生产启动和导出隔离。修改测试目录、导出过滤或测试 Autoload，测试要写文件，或生产代码要为测试开接口时读。

开发时 Godot 和 gdUnit 能加载全部测试；生产启动和导出不依赖任何仅用于测试的代码、文件和配置。

## 测试目录与导出

- 不在 `tests/` 或它的上级目录放 `.gdignore` 来排除测试。Godot 会因此看不到这些文件，gdUnit 无法发现和加载测试。
- 生产导出用导出过滤排除 `tests/`、测试夹具、测试生成的文件和 `addons/gdUnit4/`。导出过滤的写法见 [41-export-config](../41-export-config/README.md)。
- 生产代码、Resource 和配置不引用 `tests/` 或 gdUnit4 的类型与文件。去掉测试目录和 gdUnit4 后，生产启动和导出仍然成功。默认的不变量测试 `tests/invariants/debug_dependency_test.gd` 检查 `game/`、`main/`、`components/` 和 `project.godot` 不引用这两处的路径和 UID，以及 `tests/` 中的类名；`project.godot` 的 `[editor_plugins]`、`[gdunit4]` 两节只供编辑器使用，不检查。
- 修改测试目录、导出过滤、测试 Autoload 或 gdUnit4 集成时，逐条检查本节。

## 测试与调试后门

- 测试与调试工具通过生产 Command 和 API 操作，不直接修改内部状态来绕过校验、状态归属、成本、阶段检查或事件发出。
- 不为测试在生产代码中加反射、任意 `set`/`call` 或重置后门。

## Autoload 与 ProjectSettings

- 仅用于测试或编辑器的 Autoload 不成为生产运行时的依赖。插件注册的 Autoload 按[编辑器插件](../40-project-config/autoloads-and-plugins.md#编辑器插件)的规则清理和导出。
- 普通测试不向 `project.godot` 写入仅用于测试的 Input Map、分组、Shader 全局变量、ProjectSettings 或主场景设置。需要时在内存中修改并在 teardown 恢复，见[全局状态](fixtures-and-isolation.md#全局状态)。

## 测试写入的文件

- 测试创建的可变文件写到测试自己的 `user://` 子目录。必须写 `res://` 时，使用测试专属的临时子目录，不写生产的资源或数据目录。
- 只清理测试自己创建的文件、导入产物和 `.uid` 文件。

## 第三方测试框架

- 不为风格、lint 或测试方便修改 `addons/gdUnit4/`。
- 项目自己的测试 GDScript 和 `yaya/tools/testing/*.gd` 遵循项目的 GDScript 与 lint 规则。确需例外时逐处限定，不整体豁免。
