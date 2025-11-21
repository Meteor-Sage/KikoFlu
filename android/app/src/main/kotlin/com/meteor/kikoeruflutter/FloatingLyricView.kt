package com.meteor.kikoeruflutter

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView

/**
 * 悬浮歌词视图
 * 美观、简洁、现代化的设计，支持拖动
 */
class FloatingLyricView(
    context: Context,
    private val windowManager: WindowManager,
    private val layoutParams: WindowManager.LayoutParams
) : FrameLayout(context) {
    private val textView: TextView
    
    // 触摸事件相关变量
    private var initialX: Int = 0
    private var initialY: Int = 0
    private var initialTouchX: Float = 0f
    private var initialTouchY: Float = 0f
    private var isDragging = false
    private val dragThreshold = 10f // 拖动阈值，避免点击误触发

    // 当前样式状态
    private var currentBackgroundColor: Int = Color.parseColor("#F2000000")
    private var currentCornerRadius: Float = 16f

    init {
        // 使用 GradientDrawable 创建圆角背景
        updateBackground()
        
        setPadding(
            dpToPx(20f).toInt(),
            dpToPx(10f).toInt(),
            dpToPx(20f).toInt(),
            dpToPx(10f).toInt()
        )
        elevation = dpToPx(12f) // 增加阴影深度

        // 创建文本视图
        textView = TextView(context).apply {
            textSize = 16f
            setTextColor(Color.WHITE)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL) // 使用常规字重
            gravity = Gravity.CENTER
            // 添加文本阴影效果，增强可读性
            setShadowLayer(6f, 0f, 2f, Color.parseColor("#CC000000"))
            maxLines = 2
            ellipsize = android.text.TextUtils.TruncateAt.END
            letterSpacing = 0.02f // 增加字间距，更易阅读
        }

        addView(textView, LayoutParams(
            LayoutParams.WRAP_CONTENT,
            LayoutParams.WRAP_CONTENT
        ))
    }
    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                // 记录初始位置
                initialX = layoutParams.x
                initialY = layoutParams.y
                initialTouchX = event.rawX
                initialTouchY = event.rawY
                isDragging = false
                return true
            }
            
            MotionEvent.ACTION_MOVE -> {
                // 计算移动距离
                val dx = event.rawX - initialTouchX
                val dy = event.rawY - initialTouchY
                
                // 判断是否超过拖动阈值
                if (!isDragging && (Math.abs(dx) > dragThreshold || Math.abs(dy) > dragThreshold)) {
                    isDragging = true
                }
                
                if (isDragging) {
                    // 更新悬浮窗位置
                    layoutParams.x = initialX + dx.toInt()
                    layoutParams.y = initialY + dy.toInt()
                    
                    try {
                        windowManager.updateViewLayout(this, layoutParams)
                    } catch (e: Exception) {
                        // 忽略更新失败
                    }
                }
                return true
            }
            
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                if (!isDragging) {
                    // 如果没有拖动，可以在这里处理点击事件
                    performClick()
                }
                return true
            }
        }
        return super.onTouchEvent(event)
    }

    override fun performClick(): Boolean {
        super.performClick()
        // 可以在这里添加点击事件处理
        return true
    }

    /**
     * 更新显示的文本
     */
    fun updateText(text: String) {
        textView.text = text
    }

    /**
     * 更新背景
     */
    private fun updateBackground() {
        val drawable = GradientDrawable().apply {
            setColor(currentBackgroundColor)
            cornerRadius = dpToPx(currentCornerRadius)
        }
        background = drawable
    }

    /**
     * 更新样式
     */
    fun updateStyle(
        fontSize: Float?,
        textColor: Int?,
        backgroundColor: Int?,
        cornerRadius: Float?,
        paddingHorizontal: Float?,
        paddingVertical: Float?
    ) {
        fontSize?.let {
            textView.textSize = it
        }
        textColor?.let {
            textView.setTextColor(it)
        }
        
        var backgroundChanged = false
        backgroundColor?.let {
            currentBackgroundColor = it
            backgroundChanged = true
        }
        cornerRadius?.let {
            currentCornerRadius = it
            backgroundChanged = true
        }
        
        if (backgroundChanged) {
            updateBackground()
        }

        if (paddingHorizontal != null || paddingVertical != null) {
            val pH = paddingHorizontal?.let { dpToPx(it).toInt() } ?: paddingLeft
            val pV = paddingVertical?.let { dpToPx(it).toInt() } ?: paddingTop
            setPadding(pH, pV, pH, pV)
        }
    }

    /**
     * dp 转 px
     */
    private fun dpToPx(dp: Float): Float {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            resources.displayMetrics
        )
    }
}
