package com.omarea.ui

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import com.omarea.data_collection.EventType
import com.omarea.model.TaskAction
import com.omarea.model.TriggerInfo
import com.omarea.vtools.R
import kotlinx.android.synthetic.main.list_scene_task_item.view.*

class SceneTriggerItem : LinearLayout {
    constructor(context: Context) : super(context) {
        setLayout(context)
    }

    constructor(context: Context, triggerInfo: TriggerInfo) : super(context) {
        setLayout(context, triggerInfo)
    }

    constructor(context: Context?, attrs: AttributeSet?) : super(context, attrs) {}
    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr) {}
    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int, defStyleRes: Int) : super(context, attrs, defStyleAttr, defStyleRes) {}

    private fun setLayout(context: Context) {
        LayoutInflater.from(context).inflate(R.layout.list_scene_trigger_item, this, true)
    }

    private fun setLayout(context: Context, triggerInfo: TriggerInfo) {
        setLayout(context)

        system_scene_task_time.text = getEvents(triggerInfo)
        system_scene_task_content.text = getTaskContentText(triggerInfo)
    }

    private fun getEvents(triggerInfo: TriggerInfo): String {
        val buffer = StringBuffer()
        if (triggerInfo.enabled) {
            buffer.append("● ")
        } else {
            buffer.append("○ ")
        }
        if (triggerInfo.events != null && triggerInfo.events.size > 0) {
            triggerInfo.events.forEach {
                when (it) {
                    EventType.BOOT_COMPLETED -> {
                        buffer.append("开机完成")
                    }
                    EventType.APP_SWITCH -> {
                        buffer.append("应用切换")
                    }
                    EventType.SCREEN_OFF -> {
                        buffer.append("屏幕关闭")
                    }
                    EventType.SCREEN_ON -> {
                        buffer.append("屏幕打开")
                    }
                    EventType.BATTERY_CHANGED -> {
                        buffer.append("电池变化")
                    }
                    EventType.BATTERY_LOW -> {
                        buffer.append("电量不足")
                    }
                    EventType.POWER_DISCONNECTED -> {
                        buffer.append("充电器移除")
                    }
                    EventType.POWER_CONNECTED -> {
                        buffer.append("充电器连接")
                    }
                    else -> {}
                }
                buffer.append(", ")
            }
        } else {
            buffer.append("---")
        }
        if (triggerInfo.timeLimited) {
            buffer.append(String.format(context.getString(R.string.format_hh_mm), triggerInfo.timeStart / 60, triggerInfo.timeStart % 60))
            buffer.append(" ~ ")
            buffer.append(String.format(context.getString(R.string.format_hh_mm), triggerInfo.timeEnd / 60, triggerInfo.timeEnd % 60))
        }
        return buffer.toString()
    }

    private fun getTaskContentText(triggerInfo: TriggerInfo): String {
        val buffer = StringBuffer()
        if (triggerInfo.taskActions != null && triggerInfo.taskActions.size > 0) {
            triggerInfo.taskActions.forEach {
                when (it) {
                    null -> {
                    }
                    TaskAction.STANDBY_MODE_ON -> {
                        buffer.append("休眠模式 √")
                    }
                    TaskAction.STANDBY_MODE_OFF -> {
                        buffer.append("休眠模式 ×")
                    }
                    TaskAction.AIRPLANE_MODE_ON -> {
                        buffer.append("飞行模式 √")
                    }
                    TaskAction.AIRPLANE_MODE_OFF -> {
                        buffer.append("飞行模式 ×")
                    }
                    TaskAction.WIFI_ON -> {
                        buffer.append("无线网络 √")
                    }
                    TaskAction.WIFI_OFF -> {
                        buffer.append("无线网络 ×")
                    }
                    TaskAction.GPS_ON -> {
                        buffer.append("定位服务 √")
                    }
                    TaskAction.GPS_OFF -> {
                        buffer.append("定位服务 ×")
                    }
                    TaskAction.GPRS_ON -> {
                        buffer.append("数据流量 √")
                    }
                    TaskAction.GPRS_OFF -> {
                        buffer.append("数据流量 ×")
                    }
                    TaskAction.FSTRIM -> {
                        buffer.append("FSTRIM √")
                    }
                    TaskAction.COMPILE_SPEED -> {
                        buffer.append("dex2oat(speed)")
                    }
                    TaskAction.COMPILE_EVERYTHING -> {
                        buffer.append("dex2oat(everything)")
                    }
                    TaskAction.POWER_REBOOT -> {
                        buffer.append("重启手机 √")
                    }
                    TaskAction.POWER_OFF -> {
                        buffer.append("自动关机 √")
                    }
                    TaskAction.ZEN_MODE_OFF -> {
                        buffer.append("勿扰模式 ×")
                    }
                    TaskAction.ZEN_MODE_ON -> {
                        buffer.append("勿扰模式 √")
                    }
                    TaskAction.MODE_POWERSAVE -> {
                        buffer.append("省电模式 ○")
                    }
                    TaskAction.MODE_BALANCE -> {
                        buffer.append("均衡模式 ○")
                    }
                    TaskAction.MODE_PERFORMANCE -> {
                        buffer.append("性能模式 ○")
                    }
                    TaskAction.MODE_FAST -> {
                        buffer.append("极速模式 ○")
                    }
                }
                buffer.append("     ")
            }
        } else {
            buffer.append("---")
        }
        return buffer.toString()
    }

    val text: CharSequence
        get() = (findViewById<View>(android.R.id.title) as TextView).text

    override fun setEnabled(enabled: Boolean) {

    }
}