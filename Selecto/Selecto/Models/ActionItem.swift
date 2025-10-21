//
//  ActionItem.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Foundation

/// 动作类型枚举
/// Action type enumeration
enum ActionType: String, CaseIterable, Codable {
    /// 打开网址
    /// Open URL
    case openURL = "openURL"
    
    /// 执行脚本
    /// Execute script
    case executeScript = "script"
    
    /// 显示名称
    /// Display name
    var displayName: String {
        switch self {
        case .openURL:
            return "打开链接"
        case .executeScript:
            return "运行脚本"
        }
    }
}

extension ActionType {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ActionType(rawValue: rawValue) ?? .openURL
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// 动作项模型
/// Action item model
/// 定义用户可以触发的动作
/// Defines actions that users can trigger
struct ActionItem: Codable, Identifiable {
    /// 唯一标识符
    /// Unique identifier
    var id: UUID
    
    /// 动作名称
    /// Action name
    var name: String
    
    /// 显示名称
    /// Display name
    var displayName: String
    
    /// 动作类型
    /// Action type
    var type: ActionType
    
    /// 是否启用
    /// Is enabled
    var isEnabled: Bool
    
    /// 匹配条件（正则表达式）
    /// Match condition (regular expression)
    var matchPattern: String?
    
    /// 动作参数（如 URL 模板、脚本路径等）
    /// Action parameters (e.g., URL template, script path, etc.)
    var parameters: [String: String]
    
    /// 快捷键
    /// Keyboard shortcut
    var shortcut: String?
    
    /// 图标名称
    /// Icon name
    var iconName: String?
    
    /// 排序顺序
    /// Sort order
    var sortOrder: Int
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        type: ActionType,
        isEnabled: Bool = true,
        matchPattern: String? = nil,
        parameters: [String: String] = [:],
        shortcut: String? = nil,
        iconName: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.type = type
        self.isEnabled = isEnabled
        self.matchPattern = matchPattern
        self.parameters = parameters
        self.shortcut = shortcut
        self.iconName = iconName
        self.sortOrder = sortOrder
    }
    
    // MARK: - Methods
    
    /// 检查文本是否匹配此动作的条件
    /// Check if text matches this action's condition
    /// - Parameter text: 要检查的文本 / Text to check
    /// - Returns: 是否匹配 / Whether it matches
    func matches(text: String) -> Bool {
        // 如果未启用，返回 false
        // If not enabled, return false
        guard isEnabled else { return false }
        
        // 如果没有匹配模式，总是返回 true
        // If no match pattern, always return true
        guard let pattern = matchPattern, !pattern.isEmpty else {
            return true
        }
        
        // 使用正则表达式匹配
        // Use regular expression matching
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(text.startIndex..., in: text)
            return regex.firstMatch(in: text, options: [], range: range) != nil
        } catch {
            print("正则表达式错误 (Regex error): \(error)")
            return false
        }
    }
    
    /// 创建默认动作列表
    /// Create default action list
    static func defaultActions() -> [ActionItem] {
        return [
            ActionItem(
                name: "search_google",
                displayName: "打开 Google 搜索",
                type: .openURL,
                parameters: ["url": "https://www.google.com/search?q={text}"],
                sortOrder: 0
            ),
            
            // 1. IP信息查询
            // IP Information Lookup
            ActionItem(
                name: "ip_info",
                displayName: "IP 信息",
                type: .executeScript,
                matchPattern: "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",
                parameters: ["script": """
#!/bin/bash
IP="{text}"
echo "🔗 https://ipinfo.io/$IP"
result=$(curl -s --connect-timeout 5 "https://ipinfo.io/$IP" 2>&1)
if [ $? -eq 0 ]; then
    echo "$result"
else
    echo "无法连接到 ipinfo.io"
fi
"""],
                sortOrder: 1
            ),
            
            // 2. 驼峰转换
            // Case Conversion
            ActionItem(
                name: "case_conversion",
                displayName: "驼峰转换",
                type: .executeScript,
                matchPattern: "^[a-zA-Z][a-zA-Z0-9]*([ \\-_\\.][a-zA-Z0-9]+)+$",
                parameters: ["script": """
#!/bin/bash
TEXT="{text}"

# 将文本分割成单词数组
words=()
IFS='[-_ .]' read -ra ADDR <<< "$TEXT"
for word in "${ADDR[@]}"; do
    if [ ! -z "$word" ]; then
        words+=("$word")
    fi
done

# 1. 空格连接
space_case=""
for word in "${words[@]}"; do
    if [ -z "$space_case" ]; then
        space_case="${word,,}"
    else
        space_case="$space_case ${word,,}"
    fi
done
echo "空格: $space_case"

# 2. 下划线连接
underscore_case=""
for word in "${words[@]}"; do
    if [ -z "$underscore_case" ]; then
        underscore_case="${word,,}"
    else
        underscore_case="${underscore_case}_${word,,}"
    fi
done
echo "下划线: $underscore_case"

# 3. 连字符连接
hyphen_case=""
for word in "${words[@]}"; do
    if [ -z "$hyphen_case" ]; then
        hyphen_case="${word,,}"
    else
        hyphen_case="$hyphen_case-${word,,}"
    fi
done
echo "连字符: $hyphen_case"

# 4. 大驼峰 (PascalCase)
pascal_case=""
for word in "${words[@]}"; do
    first_char="${word:0:1}"
    rest="${word:1}"
    pascal_case="$pascal_case${first_char^^}${rest,,}"
done
echo "大驼峰: $pascal_case"

# 5. 小驼峰 (camelCase)
camel_case=""
first=true
for word in "${words[@]}"; do
    if [ "$first" = true ]; then
        camel_case="${word,,}"
        first=false
    else
        first_char="${word:0:1}"
        rest="${word:1}"
        camel_case="$camel_case${first_char^^}${rest,,}"
    fi
done
echo "小驼峰: $camel_case"

# 6. 全小写
lowercase=""
for word in "${words[@]}"; do
    lowercase="$lowercase${word,,}"
done
echo "全小写: $lowercase"

# 7. 全大写
uppercase=""
for word in "${words[@]}"; do
    uppercase="$uppercase${word^^}"
done
echo "全大写: $uppercase"
"""],
                sortOrder: 2
            ),
            
            // 3. 时间转换
            // Time Conversion
            ActionItem(
                name: "time_conversion",
                displayName: "时间转换",
                type: .executeScript,
                matchPattern: "^(\\d{10}|\\d{13}|\\d{4}[-/]\\d{2}[-/]\\d{2}(\\s+\\d{2}:\\d{2}(:\\d{2})?)?)$",
                parameters: ["script": """
#!/bin/bash
TEXT="{text}"

# 检测时间格式并转换为13位时间戳
if [[ "$TEXT" =~ ^[0-9]{10}$ ]]; then
    # 10位时间戳，转换为13位
    timestamp="${TEXT}000"
elif [[ "$TEXT" =~ ^[0-9]{13}$ ]]; then
    # 已经是13位时间戳
    timestamp="$TEXT"
else
    # 日期字符串，使用 date 命令解析
    # 将 / 替换为 -
    date_str="${TEXT//\\//-}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        timestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "$date_str 00:00:00" "+%s" 2>/dev/null || date -j -f "%Y-%m-%d" "$date_str" "+%s" 2>/dev/null)
        timestamp="${timestamp}000"
    else
        # Linux
        timestamp=$(date -d "$date_str" "+%s%3N" 2>/dev/null)
    fi
fi

# 转换为秒级时间戳用于后续计算
timestamp_sec=$((timestamp / 1000))

# 输出13位时间戳
echo "时间戳: $timestamp"

# 输出格式化时间
if [[ "$OSTYPE" == "darwin"* ]]; then
    formatted_time=$(date -r "$timestamp_sec" "+%Y/%m/%d %H:%M:%S")
    day_of_week_num=$(date -r "$timestamp_sec" "+%u")
    day_of_year=$(date -r "$timestamp_sec" "+%j")
else
    formatted_time=$(date -d "@$timestamp_sec" "+%Y/%m/%d %H:%M:%S")
    day_of_week_num=$(date -d "@$timestamp_sec" "+%u")
    day_of_year=$(date -d "@$timestamp_sec" "+%j")
fi
echo "时间: $formatted_time"

# 转换星期几到中文
case $day_of_week_num in
    1) day_of_week="星期一" ;;
    2) day_of_week="星期二" ;;
    3) day_of_week="星期三" ;;
    4) day_of_week="星期四" ;;
    5) day_of_week="星期五" ;;
    6) day_of_week="星期六" ;;
    7) day_of_week="星期日" ;;
esac
echo "星期: $day_of_week"

# 计算距离年初和年末的天数
days_from_start=$((day_of_year))
days_to_end=$((365 - day_of_year))
echo "距年初: ${days_from_start}天"
echo "距年末: ${days_to_end}天"
"""],
                sortOrder: 3
            ),
            
            // 4. 字符长度
            // String Length
            ActionItem(
                name: "string_length",
                displayName: "字符长度",
                type: .executeScript,
                matchPattern: "^.{4,}$",
                parameters: ["script": """
#!/bin/bash
TEXT="{text}"
length=${#TEXT}
echo "字符长度: $length"
"""],
                sortOrder: 4
            ),
            
            // 5. 数字优化展示
            // Number Formatting
            ActionItem(
                name: "number_format",
                displayName: "数字格式化",
                type: .executeScript,
                matchPattern: "^([1-9][0-9]{2,}|[1-9][0-9]{2}\\.[0-9]+)$",
                parameters: ["script": """
#!/bin/bash
TEXT="{text}"

# 检查是否大于100
if (( $(echo "$TEXT > 100" | bc -l) )); then
    # 分离整数和小数部分
    if [[ "$TEXT" == *.* ]]; then
        integer_part="${TEXT%.*}"
        decimal_part="${TEXT#*.}"
        integer_digits=${#integer_part}
        decimal_digits=${#decimal_part}
        echo "整数位数: $integer_digits"
        echo "小数位数: $decimal_digits"
    else
        integer_part="$TEXT"
        integer_digits=${#integer_part}
        echo "整数位数: $integer_digits"
        echo "小数位数: 0"
    fi
    
    # 千分位分隔
    thousands=$(printf "%'d" "$integer_part" 2>/dev/null || echo "$integer_part" | sed ':a;s/\\B[0-9]\\{3\\}\\>/,&/;ta')
    if [[ "$TEXT" == *.* ]]; then
        echo "千分位: $thousands.$decimal_part"
    else
        echo "千分位: $thousands"
    fi
    
    # 中文数字转换（仅整数部分）
    num=$integer_part
    chinese=""
    units=("" "十" "百" "千" "万" "十万" "百万" "千万" "亿")
    digits=("零" "一" "二" "三" "四" "五" "六" "七" "八" "九")
    
    # 简化的中文数字转换
    len=${#num}
    for (( i=0; i<$len; i++ )); do
        digit="${num:$i:1}"
        pos=$((len - i - 1))
        
        if [ "$digit" != "0" ]; then
            chinese="$chinese${digits[$digit]}"
            if [ $pos -gt 0 ] && [ $pos -lt 9 ]; then
                chinese="$chinese${units[$pos]}"
            fi
        elif [ ${#chinese} -gt 0 ] && [ "${chinese: -1}" != "零" ]; then
            chinese="${chinese}零"
        fi
    done
    
    # 去除末尾的零
    chinese=$(echo "$chinese" | sed 's/零*$//')
    echo "中文: $chinese"
    
    # 16进制转换
    hex=$(printf "%X" "$integer_part")
    echo "十六进制: 0x$hex"
else
    echo "数字小于等于100，不显示格式化信息"
fi
"""],
                sortOrder: 5
            )
        ]
    }
}

extension ActionItem: Hashable {
    static func == (lhs: ActionItem, rhs: ActionItem) -> Bool {
        // 比较所有属性以确保 SwiftUI 能检测到变化
        // Compare all properties to ensure SwiftUI detects changes
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.displayName == rhs.displayName &&
        lhs.type == rhs.type &&
        lhs.isEnabled == rhs.isEnabled &&
        lhs.matchPattern == rhs.matchPattern &&
        lhs.parameters == rhs.parameters &&
        lhs.shortcut == rhs.shortcut &&
        lhs.iconName == rhs.iconName &&
        lhs.sortOrder == rhs.sortOrder
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
