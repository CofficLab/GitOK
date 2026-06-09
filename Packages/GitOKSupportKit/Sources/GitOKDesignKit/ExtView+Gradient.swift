import GitOKFoundationKit
import SwiftUI

// MARK: - LinearGradient Extension

public extension LinearGradient {
    // MARK: - Two-Color Gradients

    /// 红色到蓝色渐变
    static var red2blue: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.red500, Color.blue500]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 红色到绿色渐变
    static var red2green: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.red500, Color.green500]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 蓝色到紫色渐变
    static var blue2purple: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue500, Color.purple500]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 橙色到粉色渐变
    static var orange2pink: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.orange500, Color.pink500]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 绿色到青色渐变
    static var green2teal: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.green500, Color.teal500]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 黄色到橙色渐变
    static var yellow2orange: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.yellow500, Color.orange500]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 紫色到粉色渐变
    static var purple2pink: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.purple500, Color.pink500]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 青色到蓝色渐变
    static var cyan2blue: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.cyan500, Color.blue500]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 灰色到黑色渐变
    static var gray2black: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.gray400, Color.gray900]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// 白色到灰色渐变
    static var white2gray: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.white, Color.gray300]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Nature Gradients

    /// 日落渐变（橙红到天蓝）
    static var sunset: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.sunsetStart, Color.sunsetEnd]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 极光渐变（紫色到深紫）
    static var aurora: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.auroraStart, Color.auroraEnd]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 海洋渐变（浅蓝到深蓝）
    static var ocean: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue300, Color.blue900]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// 森林渐变（浅绿到深绿）
    static var forest: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.green300, Color.green900]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// 天空渐变（浅蓝到深蓝）
    static var sky: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.skyBlue, Color.blue500]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// 草地渐变（嫩绿到深绿）
    static var grass: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.lime300, Color.green700]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// 沙漠渐变（黄到橙）
    static var desert: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.yellow500, Color.orange700]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 火焰渐变（黄到红）
    static var fire: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.yellow500, Color.red700]),
            startPoint: .bottom,
            endPoint: .top
        )
    }

    /// 冰川渐变（白到蓝）
    static var ice: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.white, Color.blue300]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Season Gradients

    /// 春天渐变（粉绿）
    static var spring: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.pink300, Color.springGreen]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 夏天渐变（亮蓝）
    static var summer: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.cyan300, Color.summerBlue]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// 秋天渐变（橙红）
    static var autumn: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.orange500, Color.autumnOrange]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 冬天渐变（冰蓝）
    static var winter: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.winterBlue, Color.blue200]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Multi-Color Gradients

    /// 彩虹渐变
    static var rainbow: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.red500,
                Color.orange500,
                Color.yellow500,
                Color.green500,
                Color.blue500,
                Color.purple500
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 热带渐变
    static var tropical: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.pink500,
                Color.orange500,
                Color.yellow500
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 霓虹渐变
    static var neon: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple500,
                Color.pink500,
                Color.cyan500
            ]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    /// 马卡龙渐变
    static var pastel: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.pink100,
                Color.purple100,
                Color.blue100
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 深海渐变
    static var deepSea: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.teal500,
                Color.blue700,
                Color.blue900
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Diagonal Gradients

    /// 对角线渐变（紫到粉）
    static var diagonalPurple2Pink: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.purple500, Color.pink500]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 对角线渐变（蓝到青）
    static var diagonalBlue2Cyan: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue500, Color.cyan500]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 对角线渐变（绿到黄）
    static var diagonalGreen2Yellow: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.green500, Color.yellow500]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    /// 对角线渐变（橙到红）
    static var diagonalOrange2Red: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.orange500, Color.red500]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
}

// MARK: - Quick Access for Background

public extension View {
    /// 快速应用红色到蓝色渐变背景
    func backgroundRed2Blue() -> some View {
        self.background(LinearGradient.red2blue)
    }

    /// 快速应用日落渐变背景
    func backgroundSunset() -> some View {
        self.background(LinearGradient.sunset)
    }

    /// 快速应用极光渐变背景
    func backgroundAurora() -> some View {
        self.background(LinearGradient.aurora)
    }

    /// 快速应用海洋渐变背景
    func backgroundOceanGradient() -> some View {
        self.background(LinearGradient.ocean)
    }

    /// 快速应用森林渐变背景
    func backgroundForestGradient() -> some View {
        self.background(LinearGradient.forest)
    }

    /// 快速应用春天渐变背景
    func backgroundSpring() -> some View {
        self.background(LinearGradient.spring)
    }

    /// 快速应用夏天渐变背景
    func backgroundSummer() -> some View {
        self.background(LinearGradient.summer)
    }

    /// 快速应用秋天渐变背景
    func backgroundAutumn() -> some View {
        self.background(LinearGradient.autumn)
    }

    /// 快速应用冬天渐变背景
    func backgroundWinter() -> some View {
        self.background(LinearGradient.winter)
    }

    /// 快速应用彩虹渐变背景
    func backgroundRainbow() -> some View {
        self.background(LinearGradient.rainbow)
    }
}

// MARK: - Preview

