import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

import "./js/calendar.mjs" as CalendarApi

Item {
  id: root

  // Plugin API (injected by PluginService)
  property var pluginApi: null

  // Required properties for bar widgets
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  // Per-screen bar properties (for multi-monitor and vertical bar support)
  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  readonly property real contentWidth: row.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        visible: isBarVertical
        icon: "calendar-week"
      }

      NText {
        id: content
        visible: !isBarVertical
        text: {
          const year = Time.now.getFullYear();
          const month = Time.now.getMonth();
          const day = Time.now.getDate();
          const result = CalendarApi.getDateBySolar(year, month + 1, day);
          return `${result["gzYearZH"]}年【${result["animal"]}】${result["lMonthZH"]}${result["lDayZH"]}`
        }
        color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
        pointSize: barFontSize
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      if (pluginApi) {
        pluginApi.openPanel(root.screen, root);
      }
    }
  }
}
