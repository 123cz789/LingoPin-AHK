#Requires AutoHotkey v2.0
; ==========================================
; 全场景中英智能双模转写工具 (Pro 终极重构版)
; 特性：突破长文限制、贴图自由拉伸缩放、完美滚动、设置面板
; ==========================================

; ------------------------------------------
; 1. 全局变量声明与配置读取
; ------------------------------------------
Global IniFile := A_ScriptDir "\TransConfig.ini"
Global SettingsGui := ""
Global ctrlHkRead, ctrlHkWrite, ctrlApiUrl, ctrlApiKey, ctrlModel, ctrlPrmptZ2E, ctrlPrmptE2Z
Global PinWindowsList := [] 

Global PresetZh2En := [
    "【标准地道】你是一名顶尖的中英翻译家。请将以下内容翻译成极度地道、专业、符合母语者习惯的英语。",
    "【学术论文】你是一名严谨的学术专家。请将以下内容翻译成符合 SCI 国际顶级期刊发表标准的高级学术英语。",
    "【日常口语】你是我的美国本地朋友。请把以下内容翻译得极其地道、日常口语化，可以使用常见的俚语。",
    "【IT与代码】你是一名资深的硅谷程序员。请将以下内容翻译成专业的计算机技术文档风格，保留专业术语。"
]
Global PresetEn2Zh := [
    "【信达雅】你是一名顶尖的中英翻译家。请将以下英文翻译成符合中国本土阅读习惯、信达雅的中文。",
    "【网文翻译】你是一名通俗小说翻译家。请把这段英文翻译得非常生动、接地气，符合当代中国年轻人的说话方式。",
    "【严谨直译】请极其精准、严谨地翻译以下英文，不要遗漏任何细节，适用于合同或法律文书。"
]

Global Cfg := {}
Cfg.HkRead  := IniRead(IniFile, "Hotkeys", "ReadMode", "^+t")
Cfg.HkWrite := IniRead(IniFile, "Hotkeys", "WriteMode", "^+r")
Cfg.ApiUrl  := IniRead(IniFile, "LLM", "ApiUrl", "https://api.openai.com/v1/chat/completions")
Cfg.ApiKey  := IniRead(IniFile, "LLM", "ApiKey", "")
Cfg.Model   := IniRead(IniFile, "LLM", "Model", "gpt-4o-mini")
Cfg.PrmptZ2E := IniRead(IniFile, "LLM", "PrmptZ2E", PresetZh2En[1])
Cfg.PrmptE2Z := IniRead(IniFile, "LLM", "PrmptE2Z", PresetEn2Zh[1])

; ------------------------------------------
; 2. 系统初始化
; ------------------------------------------
OnMessage(0x0201, HandlePinDrag)
OnMessage(0x0203, HandlePinDoubleClick)

A_IconTip := "中英转写神器"
TraySetIcon("shell32.dll", 302)
myTray := A_TrayMenu
myTray.Delete()
myTray.Add("⚙️ 设置面板", (*) => ShowSettingsGUI())
myTray.Add("❌ 完全退出", (*) => ExitApp())
myTray.Default := "⚙️ 设置面板"

RegisterHotkeys()

TrayTip("转写神器已就绪", "右键点击右下角托盘图标可打开【设置面板】。", 1)
SetTimer(() => TrayTip(), -4000)

; ------------------------------------------
; 3. 核心快捷键触发逻辑
; ------------------------------------------
ActionReadMode(*) {
    SelectedText := GetSelectedText()
    if (SelectedText == "")
        return
    ToolTip("正在获取翻译 (长文请稍候)...")
    TranslatedText := TranslateEngine(SelectedText)
    ToolTip()
    if (TranslatedText != "")
        CreatePinWindow(TranslatedText)
}

ActionWriteMode(*) {
    SelectedText := GetSelectedText()
    if (SelectedText == "")
        return
    ToolTip("正在就地转写 (长文请稍候)...")
    TranslatedText := TranslateEngine(SelectedText)
    ToolTip()
    if (TranslatedText != "") {
        A_Clipboard := TranslatedText
        Send("^v")
        Sleep(100)
    }
}

; ------------------------------------------
; 4. 图形化设置面板 (GUI) - 语法全面修正
; ------------------------------------------
ShowSettingsGUI() {
    global SettingsGui, Cfg, ctrlHkRead, ctrlHkWrite, ctrlApiUrl, ctrlApiKey, ctrlModel, ctrlPrmptZ2E, ctrlPrmptE2Z
    global PresetZh2En, PresetEn2Zh
    
    if (SettingsGui != "") {
        SettingsGui.Show()
        return
    }

    SettingsGui := Gui("-MinimizeBox -MaximizeBox", "⚙️ 转写神器 - 设置中心")
    SettingsGui.OnEvent("Close", (*) => SettingsGui.Hide())
    SettingsGui.SetFont("s10", "Microsoft YaHei")

    SettingsGui.Add("GroupBox", "w400 h110 section", "⌨️ 快捷键设置 (留空代表不开启)")
    SettingsGui.Add("Text", "xs+20 ys+30 w120", "贴图翻译 (只读):")
    ctrlHkRead := SettingsGui.Add("Hotkey", "x+10 yp-2 w140", Cfg.HkRead)
    btn1 := SettingsGui.Add("Button", "x+10 yp w60", "清空")
    btn1.OnEvent("Click", (*) => ctrlHkRead.Value := "")

    SettingsGui.Add("Text", "xs+20 yp+40 w120", "就地替换 (输入):")
    ctrlHkWrite := SettingsGui.Add("Hotkey", "x+10 yp-2 w140", Cfg.HkWrite)
    btn2 := SettingsGui.Add("Button", "x+10 yp w60", "清空")
    btn2.OnEvent("Click", (*) => ctrlHkWrite.Value := "")

    ; 修正 y+15 语法
    SettingsGui.Add("GroupBox", "xs y+15 w400 h150 section", "🚀 大模型 API 配置 (留空使用免费通道)")
    SettingsGui.Add("Text", "xs+20 ys+30 w80", "接口地址:")
    ctrlApiUrl := SettingsGui.Add("Edit", "x+10 yp-2 w280", Cfg.ApiUrl)
    SettingsGui.Add("Text", "xs+20 yp+40 w80", "API 密钥:")
    ctrlApiKey := SettingsGui.Add("Edit", "x+10 yp-2 w280 Password", Cfg.ApiKey)
    SettingsGui.Add("Text", "xs+20 yp+40 w80", "模型名称:")
    ctrlModel := SettingsGui.Add("Edit", "x+10 yp-2 w280", Cfg.Model)

    SettingsGui.Add("GroupBox", "xs y+15 w400 h180 section", "📝 提示词 (Prompt) 预设与自定义")
    SettingsGui.SetFont("s9 c808080")
    SettingsGui.Add("Text", "xs+10 ys+25", "可下拉选择模板，也可直接在框内打字输入自定义Prompt：")
    SettingsGui.SetFont("s10 cDefault")
    
    SettingsGui.Add("Text", "xs+20 ys+55 w80", "中 翻 英:")
    ctrlPrmptZ2E := SettingsGui.Add("ComboBox", "x+10 yp-2 w280", PresetZh2En)
    ctrlPrmptZ2E.Text := Cfg.PrmptZ2E 

    SettingsGui.Add("Text", "xs+20 yp+45 w80", "英 翻 中:")
    ctrlPrmptE2Z := SettingsGui.Add("ComboBox", "x+10 yp-2 w280", PresetEn2Zh)
    ctrlPrmptE2Z.Text := Cfg.PrmptE2Z
    
    btnSave := SettingsGui.Add("Button", "xs y+15 w400 h40 Default", "💾 保存设置并应用")
    btnSave.OnEvent("Click", SaveSettings)

    SettingsGui.Show()
}

SaveSettings(*) {
    global Cfg, IniFile, SettingsGui
    global ctrlHkRead, ctrlHkWrite, ctrlApiUrl, ctrlApiKey, ctrlModel, ctrlPrmptZ2E, ctrlPrmptE2Z
    
    if (Cfg.HkRead != "")
        try Hotkey(Cfg.HkRead, "Off")
    if (Cfg.HkWrite != "")
        try Hotkey(Cfg.HkWrite, "Off")

    Cfg.HkRead  := ctrlHkRead.Value
    Cfg.HkWrite := ctrlHkWrite.Value
    Cfg.ApiUrl  := ctrlApiUrl.Value
    Cfg.ApiKey  := ctrlApiKey.Value
    Cfg.Model   := ctrlModel.Value
    Cfg.PrmptZ2E := ctrlPrmptZ2E.Text 
    Cfg.PrmptE2Z := ctrlPrmptE2Z.Text

    IniWrite(Cfg.HkRead, IniFile, "Hotkeys", "ReadMode")
    IniWrite(Cfg.HkWrite, IniFile, "Hotkeys", "WriteMode")
    IniWrite(Cfg.ApiUrl, IniFile, "LLM", "ApiUrl")
    IniWrite(Cfg.ApiKey, IniFile, "LLM", "ApiKey")
    IniWrite(Cfg.Model, IniFile, "LLM", "Model")
    IniWrite(Cfg.PrmptZ2E, IniFile, "LLM", "PrmptZ2E")
    IniWrite(Cfg.PrmptE2Z, IniFile, "LLM", "PrmptE2Z")

    RegisterHotkeys()
    SettingsGui.Hide()
    TrayTip("保存成功", "新配置已生效！", 1)
}

RegisterHotkeys() {
    global Cfg
    if (Cfg.HkRead != "")
        try Hotkey(Cfg.HkRead, ActionReadMode, "On")
    if (Cfg.HkWrite != "")
        try Hotkey(Cfg.HkWrite, ActionWriteMode, "On")
}

; ------------------------------------------
; 5. 双核翻译引擎 (API 调度与突破字数限制)
; ------------------------------------------
TranslateEngine(text) {
    global Cfg
    isChinese := RegExMatch(text, "[\x{4e00}-\x{9fa5}]")

    ; 大模型通道 (无长度限制)
    if (Cfg.ApiKey != "") {
        basePrompt := isChinese ? Cfg.PrmptZ2E : Cfg.PrmptE2Z
        strictRule := " (【系统指令】：不准回复任何解释或多余对话，只能输出纯粹的翻译结果！)"
        finalPrompt := basePrompt . strictRule

        safePrompt := StrReplace(finalPrompt, "\", "\\")
        safePrompt := StrReplace(safePrompt, '"', '\"')
        safePrompt := StrReplace(safePrompt, "`n", "\n")
        safePrompt := StrReplace(safePrompt, "`r", "")
        safePrompt := StrReplace(safePrompt, "`t", "\t")

        safeText := StrReplace(text, "\", "\\")
        safeText := StrReplace(safeText, '"', '\"')
        safeText := StrReplace(safeText, "`n", "\n")
        safeText := StrReplace(safeText, "`r", "")
        safeText := StrReplace(safeText, "`t", "\t")
        
        jsonPayload := '{"model": "' . Cfg.Model . '", "messages": [{"role": "system", "content": "' . safePrompt . '"}, {"role": "user", "content": "' . safeText . '"}], "temperature": 0.2}'
        
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        try {
            whr.Open("POST", Cfg.ApiUrl, true)
            whr.SetRequestHeader("Content-Type", "application/json")
            whr.SetRequestHeader("Authorization", "Bearer " . Cfg.ApiKey)
            whr.SetTimeouts(0, 5000, 5000, 15000)
            whr.Send(jsonPayload)
            whr.WaitForResponse()
            
            if (RegExMatch(whr.ResponseText, '"content":\s*"((?:[^"\\]|\\.)*)"', &match)) {
                res := match[1]
                return DecodeUnicode(res)
            } else {
                return FreeTranslate(text, isChinese)
            }
        } catch {
            return FreeTranslate(text, isChinese)
        }
    } else {
        return FreeTranslate(text, isChinese)
    }
}

; 免费通道 (突破 500 字符超载限制：智能切片器)
FreeTranslate(text, isChinese) {
    langPair := isChinese ? "zh-CN|en-GB" : "en|zh-CN"
    finalResult := ""
    
    ; 按照换行符将文章切开，逐块发送，彻底解决 QUERY LENGTH LIMIT 报错
    Loop Parse, text, "`n", "`r"
    {
        line := A_LoopField
        if (line == "") {
            finalResult .= "`n"
            continue
        }
        
        ; 如果单行还是超过 400 字符，强行截断
        while (StrLen(line) > 0) {
            chunk := SubStr(line, 1, 400)
            line := SubStr(line, 401)
            
            url := "https://api.mymemory.translated.net/get?q=" . UriEncode(chunk) . "&langpair=" . langPair
            whr := ComObject("WinHttp.WinHttpRequest.5.1")
            try {
                whr.Open("GET", url, true)
                whr.SetTimeouts(0, 5000, 5000, 8000)
                whr.Send()
                whr.WaitForResponse()
                if (RegExMatch(whr.ResponseText, '"translatedText":"([^"]+)"', &match)) {
                    finalResult .= DecodeUnicode(match[1])
                }
            } catch {
                finalResult .= "[网络超时]"
            }
        }
        finalResult .= "`n"
    }
    return RTrim(finalResult, "`n")
}

; ------------------------------------------
; 6. 贴图 UI 与底层控制组件 (支持边缘拉伸放大与滚动)
; ------------------------------------------
CreatePinWindow(text) {
    global PinWindowsList
    ; 新增 +Resize，允许边缘拉伸放大
    pinGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border +Resize", "uTest_Translation_Pin")
    pinGui.BackColor := "1E1E1E" 
    
    pinGui.SetFont("s8 q5 c808080", "Microsoft YaHei")
    txtCtrl := pinGui.AddText("w320 Center", "📌 贴图翻译 (拖拽 | 边缘拉伸放大 | 双击关闭)")

    pinGui.SetFont("s10 q5 cF1F1F1", "Microsoft YaHei")
    lines := StrSplit(text, "`n")
    editHeight := Min(Max(lines.Length * 22, 60), 500) 
    
    ; 必须加 Multi 和 +VScroll 才能完美滚动
    editCtrl := pinGui.Add("Edit", "w320 h" . editHeight . " ReadOnly Multi +VScroll -Border -Theme -E0x200 Background1E1E1E", text)

    ; 动态适应窗口拉伸大小
    pinGui.OnEvent("Size", (guiObj, minMax, width, height) => (
        txtCtrl.Move(,, width),
        editCtrl.Move(,, width, height - 25)
    ))

    MouseGetPos(&mouseX, &mouseY)
    pinGui.Show("x" . (mouseX + 15) . " y" . (mouseY + 15) . " NoActivate")
    PinWindowsList.Push(pinGui)
}

DestroyPin(guiObj) {
    global PinWindowsList
    for index, obj in PinWindowsList {
        if (obj == guiObj) {
            PinWindowsList.RemoveAt(index)
            break
        }
    }
    guiObj.Destroy()
}

HandlePinDrag(wParam, lParam, msg, hwnd) {
    parentHwnd := DllCall("GetParent", "Ptr", hwnd, "Ptr")
    targetHwnd := parentHwnd ? parentHwnd : hwnd
    try {
        if (WinGetTitle("ahk_id " . targetHwnd) == "uTest_Translation_Pin")
            PostMessage(0xA1, 2,,, "ahk_id " . targetHwnd) 
    }
}

HandlePinDoubleClick(wParam, lParam, msg, hwnd) {
    parentHwnd := DllCall("GetParent", "Ptr", hwnd, "Ptr")
    targetHwnd := parentHwnd ? parentHwnd : hwnd
    try {
        if (WinGetTitle("ahk_id " . targetHwnd) == "uTest_Translation_Pin") {
            if (guiObj := GuiFromHwnd(targetHwnd))
                DestroyPin(guiObj)
        }
    }
}

GetSelectedText() {
    global ClipSaved := ClipboardAll()
    A_Clipboard := ""
    Send("^c")
    if (!ClipWait(0.6)) {
        A_Clipboard := ClipSaved 
        return ""
    }
    text := A_Clipboard
    A_Clipboard := ClipSaved 
    return text
}

DecodeUnicode(str) {
    while RegExMatch(str, "\\u([0-9a-fA-F]{4})", &match) {
        char := Chr(Integer("0x" . match[1]))
        str := StrReplace(str, match[0], char)
    }
    str := StrReplace(str, '\/', '/')       
    str := StrReplace(str, '\r\n', '`r`n')
    str := StrReplace(str, '\n', '`n')
    str := StrReplace(str, '\\', '\')
    str := StrReplace(str, '\"', '"')       
    str := StrReplace(str, '\u0027', "'")   
    str := RegExReplace(str, "i)[0-9a-fA-F]{32}", "")
    return str
}

UriEncode(str) {
    if (str = "")
        return ""
    oHTML := ComObject("htmlfile")
    oHTML.write("<meta http-equiv='x-ua-compatible' content='IE=9'>")
    return oHTML.parentWindow.encodeURIComponent(str)
}