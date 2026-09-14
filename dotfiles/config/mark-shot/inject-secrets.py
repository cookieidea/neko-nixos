import json

CONFIG_PATH = "/home/cookie/.config/mark-shot/config.json"
SECRET_PATH = "/run/agenix/mark-shot-sensitive"

secret = json.load(open(SECRET_PATH))
try:
    config = json.load(open(CONFIG_PATH))
except (FileNotFoundError, json.JSONDecodeError):
    config = {}

# 非敏感默认值
defaults = {
    "annotation": {"defaultColor": "", "defaultTool": "arrow", "fileDefaultTool": "arrow", "fullscreenDefaultTool": "arrow"},
    "capture": {"doubleClickAction": "copy", "freezeScope": False, "hideOwnWindows": True, "includeCursor": False, "selectionHistory": True, "selectionLoupe": True, "wayland": True},
    "captureHistory": {"enabled": True, "limit": 20},
    "clipboard": {"image": True},
    "codeScan": {"command": "/home/cookie/.local/share/mark-shot/code-scan-helper.sh {imagePath}", "provider": "auto", "timeoutMs": 15000},
    "debug": {"enabled": False, "logPath": "/tmp/mark-shot-scroll.log"},
    "env": {},
    "export": {"imageFrame": False},
    "globalHotkeys": {"capture": "Ctrl+Shift+X", "enabled": True, "fullscreen": "Ctrl+Shift+F"},
    "ocr": {"backend": "rapidocr", "command": "/home/cookie/.local/share/mark-shot/ocr-helper.sh {imagePath}", "enabled": True, "provider": "auto", "resultPanel": True, "timeoutMs": 30000},
    "ocrResultWindow": {"alwaysOnTop": False},
    "pinnedWindow": {"alwaysOnTop": False, "autoOcr": False, "border": False, "borderColor": "#4c af50", "borderEnabled": False, "borderWidth": 2, "textSelectionCopyEnabled": True},
    "recording": {"storage": "/tmp/mark-shot-recording"},
    "save": {"pathTemplate": "mark-shot-$Y$m$d-$H$M$S"},
    "scrollCapture": {"frame": True, "frameEnabled": True, "frameGap": 2, "hidePreviewDuringCapture": False, "previewGap": 0},
    "shortcuts": {"actions": [], "startup": True, "tools": []},
    "startup": {"launchOnStartup": False},
    "toolbar": {"fontSize": 14, "iconSize": 24},
    "translation": {"apiBase": "https://api.openai.com/v1", "apiKey": "", "apiKeyEnv": "OPENAI_API_KEY", "autoAfterOcr": False, "baidu": {"appId": "", "appKey": ""}, "command": "", "extraBody": {}, "model": "gpt-4o-mini", "provider": "auto", "systemPrompt": "", "targetLanguage": "Simplified Chinese", "temperature": 0.2, "tencent": {"region": "ap-guangzhou", "secretId": "", "secretKey": ""}, "timeoutMs": 60000, "timeoutSeconds": 60, "youdao": {"appKey": "", "appSecret": ""}},
    "ui": {"language": "zh-CN", "theme": "dark"},
    "upload": {"command": "", "env": {"MARK_SHOT_UPLOAD_URL": "https://freeimage.host/api/1/upload", "MARK_SHOT_UPLOAD_FIELD": "source", "MARK_SHOT_UPLOAD_URL_PATH": "image.url", "MARK_SHOT_UPLOAD_DELETE_URL_PATH": "", "MARK_SHOT_UPLOAD_FIELD_key": ""}, "timeoutMs": 60000},
    "windowDetection": {"command": "", "enabled": True, "env": {}, "timeoutMs": 5000, "workingDirectory": ""},
    "windows": {"hotkeys": True, "tray": True},
}

# 合并默认值（保留用户已有配置）
for k, v in defaults.items():
    if k not in config:
        config[k] = v

# 注入敏感值
config["translation"]["youdao"]["appKey"] = secret.get("youdaoAppKey", "")
config["translation"]["youdao"]["appSecret"] = secret.get("youdaoAppSecret", "")
config["upload"]["env"]["MARK_SHOT_UPLOAD_FIELD_key"] = secret.get("freeimageKey", "")

json.dump(config, open(CONFIG_PATH, "w"), indent=4, ensure_ascii=False)
