# MEMORY-homeassistant.md — Home Assistant Skill 配置与禁区

> 最后更新: 2026-08-21 19:53 CST
> 关联: skills/homeassistant-skill v2.1.0 (anotb, ClawHub PASS)
> 加载时机: 任何涉及 Home Assistant / smart home / 摄像头/灯/传感器查询的任务之前

---

## 🏠 实例基本信息

| 项 | 值 |
|------|-----|
| **HA_URL** | `http://localhost:8123` |
| **HA 版本** | 2026.6.4 |
| **地点** | 我的家(中国 / CN) |
| **单位制** | 英制(°F / mi / lb / gal / psi / mph) ⚠️ 注意读温度时是 °F 不是 °C |
| **时区** | 跟随系统(Asia/Shanghai) |
| **HA_TOKEN 存储** | `~/.bashrc` (chmod 600),export HA_URL + HA_TOKEN 永久生效。**选项 B**(用户 2026-08-21 19:45 拍板) |

## 🚨 Token 持久化关键教训(2026-08-21 19:53)

**禁止再发生**:
- 用户在对话里贴 token 时,消息系统可能把 ellipsis `…`(U+2026)或多字节字符改写
- 写入磁盘前**必须**用 `grep` + `cat -A` 验证 token 与原文字节级一致
- 长度不等于内容:占位符 `eyJhbG…zrHs` 长度 13 但展开成 `M-(M-(UTF-8 ellipsis) 后只有 11 字节
- 写入后**必须**实测 API 调用返回 200/数据,而不是看 length 对就以为成功

**正确流程**(已写入 AGENTS.md 第零定律补火的同类教训):
1. 用户贴 token
2. **先 echo 一遍确认字节长度 = 实际 JWT 长度**(JWT 至少 100+ 字节)
3. 写入 .bashrc
4. **实测 API**:`curl "$HA_URL/api/config"` 返回 200 + version
5. 如果 401 或 token 长度异常 → 立即 sed 删除块,要求重发

### ✅ 成功流程实跄记录(2026-08-21 19:55,二次重发后)

第二次重发 token `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...GhD4DCnwK38b4AWjUfob2CxF23RDnbfUfopatQjzrHs`(183字节,2 个点,JWT 标准 3 段)写入成功。**关键技术细节**:

- **用 `printf '%q'` 而不是 heredoc `<<EOF`**:`%q` 格式说明符会给 token 加引号转义,避免 bash 变量展开/多字节渲染带来的隐式字符变动
- **写入后 5 重验证**:
  1. `cat -A` 看 token 行(除 `$` 行尾外不应有其他隐藏字符)
  2. `wc -c` 数字节(token 183 + newline 1 = 184)
  3. `.bashrc` 文件权限必须 `chmod 600`
  4. `bash -i -c 'source ~/.bashrc'` 后 echo `${#HA_TOKEN}` 看进程内变量长度 = 183
  5. `curl "$HA_URL/api/config"` 返回 HTTP 200 + 含 version 字段

**反面教材**(避免重复):
- 第一次写入用 `cat >> ~/.bashrc <<EOF`,token 被消息传输管道折成 11 字节垃圾,实测 API 后才发现
- 修复后采用 `printf` + 字节级 grep 验证 + API 实测,**5 步骤全部在写入同一次 exec 里跑**

## 🚫 禁区(写死,任何 session 看到这些 entity_id 必须先确认)

| 类别 | 实体示例 | 风险 |
|------|----------|------|
| 🔒 **摄像头开关** | `switch.chuangmi_029a02_9ba0_switch_status` (on), `_motion_detection` (on), `_motion_tracking` | 关闭 = 失去监控,可能误关家庭安全 |
| 💾 **录像模式** | `select.chuangmi_029a02_9ba0_recording_mode` (All Record) | 改模式可能影响证据保留 |
| 📹 **摄像头指示灯** | `light.chuangmi_..._indicator_light` | 关闭指示灯 = 隐蔽录制嫌疑,必须问 |
| 🔐 **任何 lock.** | (当前 0 个,未来如出现) | SKILL.md 强制规则 |
| 🚨 **任何 alarm_control_panel.** | (当前 0 个) | SKILL.md 强制规则 |
| 🚪 **cover.garage / cover.gate** | (当前 0 个) | SKILL.md 强制规则 |
| ⚙️ **关安全自动化** | `automation.turn_off` 任何 | SKILL.md 强制规则 |

## ✅ 安全可操作(无需确认,直接执行)

- 📊 读 `sensor.*` 任何(电量、温度、太阳轨迹、备份状态)
- 💡 `light.yeelink_lamp4_677c_light` (Yeelight 灯泡,客厅)
- 📍 读 `device_tracker.*` (人在哪)
- ☁️ `weather.forecast_wo_de_jia` (天气)
- 📝 `todo.shopping_list` (读 / 写)
- 🗣️ `tts.*` (TTS 播报)
- 🏠 `person.wszmd520520` 状态查询
- ☀️ `sun.sun` / `sensor.sun_next_*`
- 🔧 `button.*` info 类(读设备信息,不触发硬件动作)
- 🧪 模板查询:`/api/template` 用 Jinja2 只读

## 📊 已知设备清单(2026-08-21 19:47 实测,74 实体 / 17 域)

- **摄像头**:`chuangmi_029a02_9ba0` (小米智能摄像机云台版2K,**当前录制 + 检测动作中**)、`isa_hlmax_9377` (大部分 offline)
- **灯**:`yeelink_lamp4_677c` (Yeelight) + 2 摄像头指示灯
- **穿戴**:`xiaomi_sw776_e06d` (黄陂三里桥,55% 电)、`xiaoxun_sw772_9d54` (黄陂大潭原种场,45% 电)、`midr_k63_0186` (unknown)
- **人**:`person.wszmd520520` (= 老王)
- **集成**:HACS、Conversation、Backup、Shopping List、Google TTS

## 🔧 工具依赖

- **`jq`** ⚠️ **未安装** (2026-08-21 19:53) —— SKILL.md 示例大量用 `jq` 语法。安装命令:
  ```bash
  sudo apt-get install -y jq
  ```
  需要用户授权(`sudo` 需要 TTY 密码,exec 直跑不通)。
  临时 fallback:用 `python3 -c "import sys,json; ..."` 替代 `jq -r ...`(本次安装就用此 fallback)。

## ⚠️ 单位制陷阱

HA 配置是**英制**(°F/mi/lb/gal)。所有读温度的 sensor 默认显示华氏度,需要乘以系数或看 device_class 而不是 unit。SKILL.md 没特别提醒,**靠使用者记住**。