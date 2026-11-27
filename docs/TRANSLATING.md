# Translating MyBrowser

Every interface string lives in a language file: **224 keys across 3 sections.**

## Add a language

1. Copy `resources/en-US.ini` to `Lang\<code>.ini` next to `MyBrowser.exe`
   (for example `Lang\de-DE.ini`).
2. Translate the values, leave the keys and section names untouched.
3. Set `Language=<code>` under `[Settings]` in `MyBrowser.ini`.
4. Restart the launcher.

The launcher reads the file and never overwrites it, so your translation survives updates.

## Rules

| Rule | Why |
|---|---|
| Do not rename keys or sections | the code looks them up by name |
| Keep `%s` and `%d` placeholders | they are filled at runtime |
| Keep `\n` as two characters | the code turns it into a line break |
| Use UTF-8 with BOM | AutoIt reads non-ASCII correctly with it |
| Leave `Version=` alone | it is compared with the build |

## Keys by section

### AppUpdate

| Key | Default (Chinese) |
|---|---|
| `CancelUpdate` | 取消更新 |
| `DownloadTips` | 点击图标可查看下载进度 |
| `Downloading` | 下载 |
| `HashMismatch` | 下载的更新包校验失败，已取消更新。 |
| `UpdateAvailableTip` | %s %s 可用，可在设置中更新。 |
| `UpdateCanceled` | 更新已取消 |
| `UpdateFailed` | %s 自动更新失败！\n\n是否打开项目主页反馈？ |
| `UpdateTips` | %s 可以更新，是否立即下载？\n\n您的版本： %s，最新版本： %s\n\n%s |
| `Updated` | %s 已更新至 %s ! |

### GUI

| Key | Default (Chinese) |
|---|---|
| `About` | 关于 |
| `About1` | QQ:970852638 |
| `About2` | MyBrowser官网 |
| `About3` | Chrome在线下载 |
| `About4` | Edge在线下载 |
| `About5` | Brave在线下载 |
| `About6` | Firefox在线下载 |
| `About7` | Vivaldi在线下载 |
| `About8` | Cent在线下载 |
| `AddApp` | 添加 |
| `AddAppTips` | 添加外部程序 |
| `And` | 和 |
| `Apply` | 应用 |
| `AutoCacheSize` |  自动控制缓存大小(Firefox) |
| `AutoSet` | 自动注入 |
| `AutoSetTips` | 浏览器更新后自动注入 |
| `Bosskey` | 老板键* |
| `Browse` | 浏览 |
| `CacheDir` | 缓存位置： |
| `CacheSize` | 缓存大小： |
| `Cancel` | 取消 |
| `CancelUpdate` | 取消更新 |
| `CentDownloadUrl` | Cent下载地址 |
| `Channel` | 分支： |
| `CheckBrowserUpdate` | 检查浏览器更新： |
| `CheckBrowserWeishu` | 浏览器位数： |
| `ChooseCacheDir` | 选择浏览器缓存文件夹 |
| `ChooseChromeExe` | 选择浏览器主程序 |
| `ChooseDataDir` | 选择一个文件夹用来保存用户数据文件 |
| `ChooseExApp` | 选择外部程序 |
| `ChooseInstaller` | 选择离线安装文件 |
| `ChromeCache` | 浏览器缓存 |
| `ChromeCacheSizeTips` | 缓存大小\n0 = 默认 |
| `ChromeCacheTips` | 浏览器缓存位置\n空白 = 默认路径\n支持%TEMP%等环境变量 |
| `ChromeNotExistsTips` | 找不到浏览器程序文件： \n%s\n\n请重新设置或者从网络下载！\n需要从网络下载浏览器的最新版本吗？ |
| `ChromePath` | 浏览器路径： |
| `ChromeSource` | 浏览器来源： |
| `ChromeSourceInstaller` | 从离线安装包提取 |
| `ChromeSourceSys` | 从系统中提取 |
| `ChromeUserData` | 浏览器用户数据文件 |
| `ClickToViewUrl` | 点击查看下载地址 |
| `CloseChromeTips` | 请关闭浏览器以便完成更新。\n是否强制关闭？ |
| `CommandLine` | 浏览器启动参数： |
| `CommandLineTips` | Chrome 启动参数，每行写一个参数。\n支持%TEMP%等环境变量，\n特别地，%APP%代表 MyBrowser 所在目录。 |
| `ConfirmUpdate` | 确定要取消浏览器更新吗？ |
| `CopyAlready` | 文本已复制到剪贴板： |
| `CopyChromeFromSys` | 正在复制浏览器程序文件... |
| `CopyChromeSuccessful` | 提取浏览器程序文件成功！ |
| `CopyDataFail` | 提取配置文件失败！ |
| `CopyDataFromeSys` | 从系统中提取用户数据文件 |
| `CopyDataSuccess` | 提取配置文件成功！ |
| `CopyDataTips` | 浏览器正在运行，无法提取用户数据文件！\n请关闭浏览器后继续。 |
| `CopyingUserData` | 正在复制浏览器用户数据文件... |
| `Copyright` | MyBrowser %s |
| `CreateChromeShortcut` | 创建快捷方式 |
| `CreateChromeShortcutTip` | 创建当前浏览器的快捷方式到桌面（不支持中文路径） |
| `CurrentVersion` | 当前版本： |
| `DefaultDir` | 空白=默认位置 |
| `DetailsCopied` | 详细信息已复制到剪贴板。 |
| `DoubleClick` | 双击 |
| `DoubleClick2CloseTab` | 双击关闭标签页 |
| `DoubleClick2CloseTabTips` | 和WGesture、StrokesPlus等有冲突 |
| `DragDrop` | 拖拽 |
| `ExApps2Tips` | 支持批处理、vbs文件等，\n如需启动参数，可添加在程序路径之后。 |
| `ExAppsTips` | 支持批处理、vbs文件等，\n如需启动参数，可添加在程序路径之后。 |
| `FirefoxDownloadUrl` | Firefox下载地址 |
| `FuZhu` | 辅助 |
| `GetUpdateInfoFailed` | 获取更新信息失败 |
| `GoogleApiRemoved` | 此版本不内置 Google API 密钥。如需使用，请自行设置环境变量 GOOGLE_API_KEY、GOOGLE_DEFAULT_CLIENT_ID 与 GOOGLE_DEFAULT_CLIENT_SECRET。 |
| `GreenChrome` | GreenChrome设置 |
| `GroupChromeApp` | 浏览器程序文件 |
| `Hide2Tray` |  隐藏到系统托盘 |
| `HookBox` | 启用Hook |
| `HookBoxTip` | 1.hook.dll能实现"双击关闭标签页"、"右键关闭标签页"、"滚轮切换标签页"、"保留最后一个标签页"和"老板键"功能，\n前四个功能对72及以上版本chrome核浏览器无效\n2."双击关闭标签页"、"右键关闭标签页"、"滚轮切换标签页"的设置同时对TabPlus和Hook生效 |
| `HookBoxTips` | 说明：\n\n1. hook.dll能实现"双击关闭标签页"、"右键关闭标签页"、"滚轮切换标签页"、"保留最后一个标签页"和"老板键"功能，前四个功能对72及以上版本chrome核浏览器无效；\n2."双击关闭标签页"、"右键关闭标签页"、"滚轮切换标签页"的设置同时对TabPlus和Hook生效。\n\n确定要取消此选项吗？ |
| `Hotkey` | 键盘： |
| `Instructions` | 使用说明 |
| `IntvEveryDay` | 每天 |
| `IntvEveryHour` | 每小时 |
| `IntvEveryWeek` | 每周 |
| `IntvNever` | 从不 |
| `IntvOnStartup` | 每次启动时 |
| `KeepLastTab` | 保留最后一个标签页 |
| `KeepLastTabTips` | 对Chromium核72及以上版本无效 |
| `LangSupport` | 语言支持： |
| `LastKnownVersion` | 上次已知版本 |
| `LatestVersion` | 最新版本： |
| `MiddleButton` | 中键 |
| `Mouse2SwitchTab` | 滚轮切换标签页 |
| `MouseClick` | 鼠标： |
| `MouseInc` | MouseInc鼠标手势 |
| `MouseIncA` | MouseInc鼠标手势 |
| `MouseIncATips` | 和[右键关闭标签页]有冲突但不影响使用 |
| `MouseIncB` | MouseInc随浏览器关闭 |
| `MouseIncBTips` | 需重启浏览器或MyBrowser才生效 |
| `MyBrowserRunInBackground` | MyBrowser 在后台运行直至浏览器退出 |
| `NetworkSettings` | 网络设置 |
| `NoChromeFound` | 在您的系统中未找到 Chrome（%s）程序文件! |
| `NoChromiumFound` | 在您的系统中未找到 Chromium（%s）程序文件! |
| `NoResponse` | 进程意外中止或无响应 |
| `NotFound` | 未找到 |
| `NotifyMyBrowserUpdate` | MyBrowser 发布新版时通知我 |
| `NotifyMyBrowserUpdateTips` | 每24小时检查更新一次 |
| `OK` | 确定 |
| `OpenUrl` | 打开网页 |
| `PleaseCheck` | ，请检查配置 |
| `PleaseDownload` |  ,请先下载程序文件！\n是否立即下载？\n\n【是】:按[常规]选项卡里面的设置立即下载  【否】:不下载 |
| `PluginsDir` | 插件目录(Firefox)： |
| `PluginsDirTip` | 浏览器插件目录 |
| `PluginsDirToTip` | 指定浏览器插件目录 |
| `ProxyDirect` | 直接连接 |
| `ProxyIE` | 跟随系统 |
| `ProxyPort` | 代理端口： |
| `ProxyServer` | 代理服务器： |
| `ProxyType` | 代理类型： |
| `QuitOnChromeExit` |  浏览器退出后自动关闭* |
| `RightButton` | 右键 |
| `RightClick2CloseTab` | 右键关闭标签页 |
| `RightClick2CloseTabTips` | Shift+右键或1+右键可显示右键菜单 |
| `RunBackgroundTips` | 如果您不勾选该选项，请注意以下几点：\n\n1. 将浏览器锁定到任务栏或设为默认浏览器后，需再运行一次 MyBrowser 才能生效；\n2. MyBrowser 设置界面中带“*”符号的功能将无法实现。\n\n确定要取消此选项吗？ |
| `RunOnChromeExit` | 浏览器退出后运行*： |
| `SettingsTips` | 双击软件目录下的 "%s.vbs" 文件可显示此窗口 |
| `StartWithChrome` | 浏览器启动时运行： |
| `Tab` | 标签页* |
| `TabAdvanced` | 高级 |
| `TabGeneral` | 常规 |
| `TabPlus` | 启用TabPlus |
| `TabPlusTip` | 1.TabPlus能实现"双击关闭标签页"、"右键关闭标签页"、"滚轮切换标签页"功能\n2."双击关闭标签页"、"右键关闭标签页"、"滚轮切换标签页"的设置同时对TabPlus和Hook生效 |
| `TabPlusTips` | 说明：\n\n1. TabPlus能实现"双击关闭标签页"、"右键关闭标签页"、"滚轮切换标签页"功能；\n2."双击关闭标签页"、"右键关闭标签页"、"滚轮切换标签页"的设置同时对TabPlus和Hook生效。\n\n确定要取消此选项吗？ |
| `ThreadsNum` | 下载线程数(1-10)： |
| `ThreadsTips` | 增减线程数可调节下载速度\n仅适用于下载chrome更新 |
| `Title` | MyBrowser |
| `UnhideChrome` | Chrome已隐藏\n点击取消隐藏 |
| `UpdateNow` | 立即更新 |
| `UpdateUrlTips` | 选择链接可下载或复制到剪贴板 |
| `UrlCopy` | 复制 |
| `UrlCopySuccessful` | 下载地址已复制到剪贴板! |
| `UrlDownload` | 下载 |
| `UserDataDir` | 用户数据文件夹： |
| `VivaldiDownloadUrl` | Vivaldi下载地址 |
| `chromium` | Chromium设置 |
| `fugaigengxin1` | 设置在同一目录(不推荐)，将会覆盖更新，是否继续？ |
| `fugaigengxin2` | 是否覆盖更新？\n\n【是】:立即覆盖更新\n【否】:删除原程序目录后更新【危险：请注意备份重要文件】\n【取消】：取消本次操作 |
| `fugaigengxin3` | 检测到浏览器正在运行，是否关闭浏览器后更新？\n\n【确定】:关闭浏览后更新\n【取消】：不更新 |
| `gcsetting` | 配置GreenChrome |
| `gcsettingTips` | 打开GreenChrome配置文件 |
| `guanfang` | 官方 |
| `injectgc1` | 注入GreenChrome成功，重启浏览器生效！ |
| `injectgc2` | 注入GreenChrome成功！ |
| `injectgc3` | 注入GreenChrome失败！ |
| `kuozhan` | 扩展 |
| `opencentdownload` | 是否打开Cent网页下载链接？ |
| `openfirefoxdownload` | 是否打开Firefox网页下载链接？ |
| `openvivaldidownload` | 是否打开Vivaldi网页下载链接？ |
| `qingchutishi` | 清除GoogleAPI密钥成功 |
| `removegc1` | 解除GreenChrome成功，重启浏览器生效！ |
| `removegc2` | 解除GreenChrome成功！ |
| `removegc3` | 解除GreenChrome失败！ |
| `setapino` | 清除GoogleAPI提示 |
| `setapinoTips` | 不导入GoogleAPI密钥只清除缺少GoogleAPI密钥提示 |
| `setapioff` | 清除GoogleAPI |
| `setapioffTips` | 缺少GoogleAPI密钥会导致Chromium不能登录谷歌账号 |
| `setapion` | 导入GoogleAPI |
| `setapionTips` | 导入GoogleAPI密钥Chromium才能登录谷歌账号 |
| `setcppoff` | 解除Chrome++ |
| `setcppoffTips` | 解除并删除Chrome++ |
| `setgcoff` | 解除GreenChrome |
| `setgcoffTips` | 解除并删除GreenChrome |
| `setgcon` | 注入GreenChrome |
| `setgconTips` | 释放并注入GreenChrome |
| `wuxiaoapp` |  不是有效的32位或64位 Windows 应用程序 |

### Update

| Key | Default (Chinese) |
|---|---|
| `ApplyIncomplete` | 更新文件不完整，已取消本次更新，原浏览器未受影响。 |
| `ApplyUpdate` | 正在应用浏览器更新 |
| `ArchiveCorrupt` | 下载的更新包不完整或已损坏，请重试。 |
| `BraveUpdatedTo` | Brave 浏览器已更新至 %s! |
| `CancelUpdate` | 取消更新 |
| `CancelUpdateConfirm` | 浏览器正在更新，确定要取消吗？ |
| `CentUpdatedTo` | Cent 浏览器已更新至 %s! |
| `ChromeDownloadFinished` | 浏览器下载完成 |
| `ChromeUpdatedTo` | Google Chrome 浏览器已更新至 %s %s ! |
| `ChromiumUpdatedTo` | 11Chromium 浏览器已更新至 %s %s ! |
| `ConnectServerFailed` | 连接更新服务器失败 |
| `Connecting` | 尝试连接 |
| `ConnectingServer` | 正在连接服务器 ... |
| `DeleteFail` | 删除 ~update 文件夹失败。 |
| `DownloadChromeTips` | 点击图标可查看下载进度 |
| `DownloadFailed` | 下载浏览器失败 |
| `DownloadingChrome` | 下载中 |
| `EdgeUpdatedTo` | MicroSoft Edge 浏览器已更新至 %s! |
| `ExitConfirm` | 浏览器正在更新，确定要取消更新并退出吗？ |
| `ExtractBraveFailed` | 提取 Brave 程序文件失败！ |
| `ExtractCentFailed` | 提取 Cent 程序文件失败！ |
| `ExtractChromeFailed` | 提取 Google Chrome 程序文件失败！ |
| `ExtractChromiumFailed` | 提取 Chromium 程序文件失败！ |
| `ExtractEdgeFailed` | 提取 MicroSoft Edge 程序文件失败！ |
| `ExtractFirefoxFailed` | 提取 Firefox 程序文件失败！ |
| `ExtractVivaldiFailed` | 提取 Vivaldi 程序文件失败！ |
| `ExtractingChrome` | 正在提取程序文件 |
| `FirefoxUpdatedTo` | Firefox 浏览器已更新至 %s! |
| `GetChromeChances` | 从服务器获取 %s 更新信息... 第 %d 次尝试 |
| `IfCreateChromeShortcut` | 是否创建快捷方式到桌面(不支持中文路径) |
| `InstallerSizeError` | 已下载的浏览器安装包大小不正确 |
| `LowDiskSpace` | 可用磁盘空间不足 2GB，更新可能失败。是否继续？ |
| `NoResponse` | 进程意外中止或无响应 |
| `NoServerResp` | 服务器无响应 |
| `NotAdapted` | 未适配该程序，请手动解压安装！ |
| `ParseInfoFailed` | 服务器返回的更新信息无法解析 |
| `RestoringDownload` | 尝试恢复下载 |
| `SaveFileFailed` | 保存已下载的文件出错 |
| `UpdateCloseChrome` | 是否关闭 Chrome 浏览器以完成更新？\n点击“是”强制关闭浏览器，点击“否”推迟到下次启动时应用更新。 |
| `UpdateGot` | 已成功获取 %s 更新信息 |
| `UpdateInProgress` | 浏览器上次更新仍在进行中！ |
| `UpdateTips` | 浏览器可以更新，是否立即下载？\n\n最新版本：\t%s\n您的版本：\t%s  %s\n\n【是】:立即更新  【否】:不更新(下次不提示)  【取消】:不更新(下次会提示) |
| `VivaldiUpdatedTo` | Vivaldi 浏览器已更新至 %s! |
| `edgedownload` | 是否打开Edge网页下载链接？ |
