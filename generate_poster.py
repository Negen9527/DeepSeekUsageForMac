#!/usr/bin/env python3
"""
生成 DeepSeekUsageForMac 宣传海报
"""

from PIL import Image, ImageDraw, ImageFont
import os

def generate_poster():
    # 海报尺寸 (1080x1920) - 16:9 竖版，适合抖音发布
    width, height = 1080, 1920
    
    # 创建画布
    poster = Image.new('RGB', (width, height), color='#0f172a')
    
    # 创建绘图对象
    draw = ImageDraw.Draw(poster)
    
    # 加载字体
    font_paths = [
        '/System/Library/Fonts/SFProDisplay-Bold.otf',
        '/System/Library/Fonts/SFNSDisplay-Bold.ttf',
        '/Library/Fonts/Arial Bold.ttf',
    ]
    
    def get_font(size, bold=False):
        for path in font_paths:
            if os.path.exists(path):
                try:
                    return ImageFont.truetype(path, size)
                except:
                    continue
        return ImageFont.load_default()
    
    title_font = get_font(64, bold=True)
    subtitle_font = get_font(22)
    tagline_font = get_font(32)
    feature_title_font = get_font(24, bold=True)
    feature_desc_font = get_font(16)
    stat_font = get_font(56, bold=True)
    stat_label_font = get_font(14)
    cta_font = get_font(22, bold=True)
    footer_font = get_font(14)
    logo_font = get_font(64, bold=True)
    
    # 绘制渐变背景
    for y in range(height):
        gradient = int((1 - y / height) * 20)
        draw.line([(0, y), (width, y)], fill=(15 + gradient, 23 + gradient, 42 + gradient))
    
    # 绘制发光边框
    draw.rounded_rectangle([(10, 10), (width-10, height-10)], radius=24, outline=(0, 242, 255, 30), width=2)
    
    # 绘制 Logo
    logo_size = 120
    logo_x = (width - logo_size) // 2
    logo_y = 80
    
    # Logo 渐变背景
    for i in range(logo_size):
        for j in range(logo_size):
            r = ((logo_size/2 - i)**2 + (logo_size/2 - j)**2)**0.5
            if r < logo_size/2 - 2:
                draw.point((logo_x + i, logo_y + j), fill=(0, 242, 255))
    
    # 绘制 Logo 文字
    draw.text((logo_x + 38, logo_y + 22), 'D', font=logo_font, fill='#0f172a')
    
    # 绘制标题
    title = 'DeepSeekUsageForMac'
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_w = title_bbox[2] - title_bbox[0]
    draw.text(((width - title_w) // 2, logo_y + logo_size + 40), title, font=title_font, fill=(0, 242, 255))
    
    # 绘制副标题
    subtitle = 'DEEPSEEK 用量监控'
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_w = subtitle_bbox[2] - subtitle_bbox[0]
    draw.text(((width - subtitle_w) // 2, logo_y + logo_size + 110), subtitle, font=subtitle_font, fill=(148, 163, 184))
    
    # 绘制标语
    tagline = '实时掌握你的 AI API 用量与费用'
    tagline_bbox = draw.textbbox((0, 0), tagline, font=tagline_font)
    tagline_w = tagline_bbox[2] - tagline_bbox[0]
    draw.text(((width - tagline_w) // 2, logo_y + logo_size + 160), tagline, font=tagline_font, fill=(226, 232, 240))
    
    # 加载应用截图
    screenshot_path = 'screenshots/dashboard.png'
    if os.path.exists(screenshot_path):
        screenshot = Image.open(screenshot_path)
        # 调整截图大小（放大以适应竖版海报）
        screenshot = screenshot.resize((310, 630), Image.LANCZOS)
        
        # 绘制截图框架
        frame_x = (width - 310 - 20) // 2
        frame_y = logo_y + logo_size + 220
        draw.rounded_rectangle([(frame_x, frame_y), (frame_x + 310 + 20, frame_y + 630 + 20)], radius=24, fill=(0, 0, 0, 60))
        
        # 绘制截图阴影
        shadow = Image.new('RGBA', (310, 630), (0, 0, 0, 30))
        poster.paste(shadow, (frame_x + 12, frame_y + 12), shadow)
        
        # 粘贴截图
        poster.paste(screenshot, (frame_x + 10, frame_y + 10))
        
        # 绘制截图边框
        draw.rounded_rectangle([(frame_x + 10, frame_y + 10), (frame_x + 320, frame_y + 640)], radius=20, outline=(0, 242, 255, 40), width=1)
    
    # 绘制功能卡片
    features = [
        ('📊', '实时监控', '每15分钟自动刷新用量数据，实时掌握 Token 消耗、费用支出和请求次数'),
        ('💰', '费用管理', '月度预算设置，智能费用预警，帮你更好地控制 AI 支出成本'),
        ('📈', '趋势分析', '7日用量趋势图表，支持折线图与柱状图切换，直观了解用量变化'),
        ('🔒', '安全存储', 'Token 安全存储在 macOS Keychain，加密保护你的敏感信息')
    ]
    
    feature_start_y = frame_y + 630 + 60
    card_w, card_h = (width - 80) // 2, 160
    
    for i, (icon, title, desc) in enumerate(features):
        card_x = 40 + (i % 2) * (card_w + 16)
        card_y = feature_start_y + (i // 2) * (card_h + 16)
        
        # 绘制卡片背景
        draw.rounded_rectangle([(card_x, card_y), (card_x + card_w, card_y + card_h)], radius=16, fill=(30, 41, 59, 80))
        draw.rounded_rectangle([(card_x, card_y), (card_x + card_w, card_y + card_h)], radius=16, outline=(0, 242, 255, 20), width=1)
        
        # 绘制图标
        icon_font = get_font(32)
        draw.text((card_x + 28, card_y + 24), icon, font=icon_font, fill=(255, 255, 255))
        
        # 绘制功能标题
        ft_bbox = draw.textbbox((0, 0), title, font=feature_title_font)
        ft_w = ft_bbox[2] - ft_bbox[0]
        draw.text((card_x + 28, card_y + 80), title, font=feature_title_font, fill=(241, 245, 249))
        
        # 绘制功能描述
        # 分割多行文本
        words = desc.split(' ')
        lines = []
        current_line = ''
        for word in words:
            temp = current_line + ' ' + word if current_line else word
            temp_bbox = draw.textbbox((0, 0), temp, font=feature_desc_font)
            w = temp_bbox[2] - temp_bbox[0]
            if w < card_w - 56:
                current_line = temp
            else:
                lines.append(current_line)
                current_line = word
        lines.append(current_line)
        
        for j, line in enumerate(lines):
            draw.text((card_x + 28, card_y + 112 + j * 20), line, font=feature_desc_font, fill=(148, 163, 184))
    
    # 绘制统计数据
    stats_start_y = feature_start_y + 2 * (card_h + 16) + 50
    stats = [('50K+', '活跃用户'), ('99.9%', '服务可用'), ('0', '数据泄露')]
    
    for i, (value, label) in enumerate(stats):
        stat_x = width // 4 + i * (width // 4)
        # 渐变文字效果
        for offset in range(3):
            draw.text((stat_x - 50 + offset, stats_start_y), value, font=stat_font, fill=(16, 185, 129))
    
    # 绘制统计标签
    for i, (value, label) in enumerate(stats):
        stat_x = width // 4 + i * (width // 4)
        label_bbox = draw.textbbox((0, 0), label, font=stat_label_font)
        label_w = label_bbox[2] - label_bbox[0]
        draw.text((stat_x - label_w // 2, stats_start_y + 65), label, font=stat_label_font, fill=(148, 163, 184))
    
    # 绘制 CTA 区域
    cta_y = stats_start_y + 120
    draw.rounded_rectangle([(80, cta_y), (width - 80, cta_y + 150)], radius=24, fill=(0, 242, 255, 8))
    draw.rounded_rectangle([(80, cta_y), (width - 80, cta_y + 150)], radius=24, outline=(0, 242, 255, 30), width=1)
    
    cta_title = '立即开始使用'
    cta_title_bbox = draw.textbbox((0, 0), cta_title, font=feature_title_font)
    cta_title_w = cta_title_bbox[2] - cta_title_bbox[0]
    draw.text(((width - cta_title_w) // 2, cta_y + 35), cta_title, font=feature_title_font, fill=(241, 245, 249))
    
    cta_desc = '加入数千用户，实时监控你的 DeepSeek API 用量'
    cta_desc_bbox = draw.textbbox((0, 0), cta_desc, font=feature_desc_font)
    cta_desc_w = cta_desc_bbox[2] - cta_desc_bbox[0]
    draw.text(((width - cta_desc_w) // 2, cta_y + 75), cta_desc, font=feature_desc_font, fill=(148, 163, 184))
    
    # 绘制按钮
    button_x = (width - 240) // 2
    button_y = cta_y + 105
    draw.rounded_rectangle([(button_x, button_y), (button_x + 240, button_y + 56)], radius=14, fill=(0, 242, 255))
    button_text = '免费下载'
    button_bbox = draw.textbbox((0, 0), button_text, font=cta_font)
    button_w = button_bbox[2] - button_bbox[0]
    draw.text(((width - button_w) // 2, button_y + 18), button_text, font=cta_font, fill=(15, 23, 42))
    
    # 绘制标签
    badges = ['macOS 14.0+', 'SwiftUI', '开源免费']
    badges_y = cta_y + 170
    badge_w = 120
    badge_h = 38
    badges_x = [(width - 3 * badge_w - 30) // 2 + i * (badge_w + 15) for i in range(3)]
    
    for i, badge in enumerate(badges):
        draw.rounded_rectangle([(badges_x[i], badges_y), (badges_x[i] + badge_w, badges_y + badge_h)], radius=19, fill=(0, 0, 0, 30))
        draw.rounded_rectangle([(badges_x[i], badges_y), (badges_x[i] + badge_w, badges_y + badge_h)], radius=19, outline=(255, 255, 255, 10), width=1)
        badge_bbox = draw.textbbox((0, 0), badge, font=footer_font)
        badge_w_text = badge_bbox[2] - badge_bbox[0]
        draw.text((badges_x[i] + (badge_w - badge_w_text) // 2, badges_y + 12), badge, font=footer_font, fill=(148, 163, 184))
    
    # 绘制页脚
    footer_y = badges_y + 80
    footer_text = 'Made with ❤️ for DeepSeek Developers'
    footer_bbox = draw.textbbox((0, 0), footer_text, font=footer_font)
    footer_w = footer_bbox[2] - footer_bbox[0]
    draw.text(((width - footer_w) // 2, footer_y), footer_text, font=footer_font, fill=(100, 116, 139))
    
    github_link = 'github.com/Negen9527/DeepSeekUsageForMac'
    github_bbox = draw.textbbox((0, 0), github_link, font=footer_font)
    github_w = github_bbox[2] - github_bbox[0]
    draw.text(((width - github_w) // 2, footer_y + 28), github_link, font=footer_font, fill=(0, 242, 255))
    
    # 保存海报
    output_path = 'screenshots/poster.png'
    poster.save(output_path, 'PNG', quality=95)
    print(f'海报已生成: {output_path}')

if __name__ == '__main__':
    generate_poster()