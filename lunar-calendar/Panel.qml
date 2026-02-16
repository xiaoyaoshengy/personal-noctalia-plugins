import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.System
import qs.Services.UI
import qs.Widgets

import "./js/calendar.mjs" as CalendarApi

Item {
  id: root

  // Plugin API (injected by PluginPanelSlot)
  property var pluginApi: null

  // SmartPanel properties (required for panel behavior)
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  // Preferred dimensions
  property real contentPreferredWidth: Math.round((Settings.data.location.showWeekNumberInCalendar ? 440 : 420) * Style.uiScaleRatio)
  property real contentPreferredHeight: lunarCalendarCard.implicitHeight + (Style.marginL * 2)

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"
    
    ColumnLayout {
      anchors {
        fill: parent
        margins: Style.marginL
      }
      spacing: Style.marginL
      
      // Calendar month grid with navigation
      NBox {
        id: lunarCalendarCard
        Layout.fillWidth: true
        implicitHeight: calendarContent.implicitHeight + Style.marginXL
      
        // Internal state - independent from header
        readonly property var now: Time.now
        property int calendarMonth: now.getMonth()
        property int calendarYear: now.getFullYear()
        readonly property int firstDayOfWeek: Settings.data.location.firstDayOfWeek === -1 ? I18n.locale.firstDayOfWeek : Settings.data.location.firstDayOfWeek
      
        // Helper function to calculate ISO week number
        function getISOWeekNumber(date) {
          const target = new Date(date.valueOf());
          const dayNr = (date.getDay() + 6) % 7;
          target.setDate(target.getDate() - dayNr + 3);
          const firstThursday = new Date(target.getFullYear(), 0, 4);
          const diff = target - firstThursday;
          const oneWeek = 1000 * 60 * 60 * 24 * 7;
          const weekNumber = 1 + Math.round(diff / oneWeek);
          return weekNumber;
        }
      
        // Navigation functions
        function navigateToPreviousMonth() {
          let newDate = new Date(lunarCalendarCard.calendarYear, lunarCalendarCard.calendarMonth - 1, 1);
          lunarCalendarCard.calendarYear = newDate.getFullYear();
          lunarCalendarCard.calendarMonth = newDate.getMonth();
          const now = new Date();
          const monthStart = new Date(lunarCalendarCard.calendarYear, lunarCalendarCard.calendarMonth, 1);
          const monthEnd = new Date(lunarCalendarCard.calendarYear, lunarCalendarCard.calendarMonth + 1, 0);
          const daysBehind = Math.max(0, Math.ceil((now - monthStart) / (24 * 60 * 60 * 1000)));
          const daysAhead = Math.max(0, Math.ceil((monthEnd - now) / (24 * 60 * 60 * 1000)));
        }
      
        function navigateToNextMonth() {
          let newDate = new Date(lunarCalendarCard.calendarYear, lunarCalendarCard.calendarMonth + 1, 1);
          lunarCalendarCard.calendarYear = newDate.getFullYear();
          lunarCalendarCard.calendarMonth = newDate.getMonth();
          const now = new Date();
          const monthStart = new Date(lunarCalendarCard.calendarYear, lunarCalendarCard.calendarMonth, 1);
          const monthEnd = new Date(lunarCalendarCard.calendarYear, lunarCalendarCard.calendarMonth + 1, 0);
          const daysBehind = Math.max(0, Math.ceil((now - monthStart) / (24 * 60 * 60 * 1000)));
          const daysAhead = Math.max(0, Math.ceil((monthEnd - now) / (24 * 60 * 60 * 1000)));
        }
      
        // Wheel handler for month navigation
        WheelHandler {
          id: wheelHandler
          target: lunarCalendarCard
          acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
          onWheel: function (event) {
            if (event.angleDelta.y > 0) {
              // Scroll up - go to previous month
              lunarCalendarCard.navigateToPreviousMonth();
              event.accepted = true;
            } else if (event.angleDelta.y < 0) {
              // Scroll down - go to next month
              lunarCalendarCard.navigateToNextMonth();
              event.accepted = true;
            }
          }
        }
      
        ColumnLayout {
          id: calendarContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS
      
          // Navigation row
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
      
            Item {
              Layout.preferredWidth: Style.marginS
            }
      
            NText {
              text: I18n.locale.monthName(lunarCalendarCard.calendarMonth, Locale.LongFormat).toUpperCase() + " " + lunarCalendarCard.calendarYear
              pointSize: Style.fontSizeM
              font.weight: Style.fontWeightBold
              color: Color.mOnSurface
            }
      
            NDivider {
              Layout.fillWidth: true
            }
      
            NIconButton {
              icon: "chevron-left"
              onClicked: lunarCalendarCard.navigateToPreviousMonth()
            }
      
            NIconButton {
              icon: "calendar"
              onClicked: {
                lunarCalendarCard.calendarMonth = lunarCalendarCard.now.getMonth();
                lunarCalendarCard.calendarYear = lunarCalendarCard.now.getFullYear();
              }
            }
      
            NIconButton {
              icon: "chevron-right"
              onClicked: lunarCalendarCard.navigateToNextMonth()
            }
          }
      
          // Day names header
          RowLayout {
            Layout.fillWidth: true
            spacing: 0
      
            Item {
              visible: Settings.data.location.showWeekNumberInCalendar
              Layout.preferredWidth: visible ? Style.baseWidgetSize * 0.7 : 0
            }
      
            GridLayout {
              Layout.fillWidth: true
              columns: 7
              rows: 1
              columnSpacing: 0
              rowSpacing: 0
      
              Repeater {
                model: 7
                Item {
                  Layout.fillWidth: true
                  Layout.preferredHeight: Style.fontSizeS * 2
      
                  NText {
                    anchors.centerIn: parent
                    text: {
                      let dayIndex = (lunarCalendarCard.firstDayOfWeek + index) % 7;
                      const dayName = I18n.locale.dayName(dayIndex, Locale.ShortFormat);
                      return dayName.substring(0, 2).toUpperCase();
                    }
                    color: Color.mPrimary
                    pointSize: Style.fontSizeS
                    font.weight: Style.fontWeightBold
                    horizontalAlignment: Text.AlignHCenter
                  }
                }
              }
            }
          }
      
          // Calendar grid with week numbers
          RowLayout {
            Layout.fillWidth: true
            spacing: 0
      
            // Week numbers column
            ColumnLayout {
              visible: Settings.data.location.showWeekNumberInCalendar
              Layout.preferredWidth: visible ? Style.baseWidgetSize * 0.7 : 0
              Layout.alignment: Qt.AlignTop
              spacing: Style.marginXXS
      
              property var weekNumbers: {
                if (!grid.daysModel || grid.daysModel.length === 0)
                  return [];
                const weeks = [];
                const numWeeks = Math.ceil(grid.daysModel.length / 7);
                for (var i = 0; i < numWeeks; i++) {
                  const dayIndex = i * 7;
                  if (dayIndex < grid.daysModel.length) {
                    const weekDay = grid.daysModel[dayIndex];
                    const date = new Date(weekDay.year, weekDay.month, weekDay.day);
                    let thursday = new Date(date);
                    if (lunarCalendarCard.firstDayOfWeek === 0) {
                      thursday.setDate(date.getDate() + 4);
                    } else if (lunarCalendarCard.firstDayOfWeek === 1) {
                      thursday.setDate(date.getDate() + 3);
                    } else {
                      let daysToThursday = (4 - lunarCalendarCard.firstDayOfWeek + 7) % 7;
                      thursday.setDate(date.getDate() + daysToThursday);
                    }
                    weeks.push(lunarCalendarCard.getISOWeekNumber(thursday));
                  }
                }
                return weeks;
              }
      
              Repeater {
                model: parent.weekNumbers
                Item {
                  Layout.preferredWidth: Style.baseWidgetSize * 0.7
                  Layout.preferredHeight: Style.baseWidgetSize * 0.9
      
                  NText {
                    anchors.centerIn: parent
                    color: Qt.alpha(Color.mPrimary, 0.7)
                    pointSize: Style.fontSizeXXS
                    text: modelData
                  }
                }
              }
            }
      
            // Calendar grid
            GridLayout {
              id: grid
              Layout.fillWidth: true
              columns: 7
              columnSpacing: Style.marginXXS
              rowSpacing: Style.marginL
      
              property int month: lunarCalendarCard.calendarMonth
              property int year: lunarCalendarCard.calendarYear
      
              property var daysModel: {
                const firstOfMonth = new Date(year, month, 1);
                const lastOfMonth = new Date(year, month + 1, 0);
                const daysInMonth = lastOfMonth.getDate();
                const firstDayOfWeek = lunarCalendarCard.firstDayOfWeek;
                const firstOfMonthDayOfWeek = firstOfMonth.getDay();
                let daysBefore = (firstOfMonthDayOfWeek - firstDayOfWeek + 7) % 7;
                const lastOfMonthDayOfWeek = lastOfMonth.getDay();
                const daysAfter = (firstDayOfWeek - lastOfMonthDayOfWeek - 1 + 7) % 7;
                const days = [];
                const today = new Date();
      
                // Previous month days
                const prevMonth = new Date(year, month, 0);
                const prevMonthDays = prevMonth.getDate();
                for (var i = daysBefore - 1; i >= 0; i--) {
                  const day = prevMonthDays - i;
                  const lunarInfo = CalendarApi.getDateBySolar(month === 0 ? year - 1 : year, month - 1, day);
                  days.push({
                              "day": day,
                              "month": month - 1,
                              "year": month === 0 ? year - 1 : year,
                              "today": false,
                              "currentMonth": false,
                              "lunarDay": lunarInfo["lDayZH"]
                            });
                }
      
                // Current month days
                for (var day = 1; day <= daysInMonth; day++) {
                  const date = new Date(year, month, day);
                  const isToday = date.getFullYear() === today.getFullYear() && date.getMonth() === today.getMonth() && date.getDate() === today.getDate();
                  const lunarInfo = CalendarApi.getDateBySolar(year, month, day);
                  days.push({
                              "day": day,
                              "month": month,
                              "year": year,
                              "today": isToday,
                              "currentMonth": true,
                              "lunarDay": lunarInfo["lDayZH"]
                            });
                }
      
                // Next month days
                for (var i = 1; i <= daysAfter; i++) {
                  const lunarInfo = CalendarApi.getDateBySolar(month === 11 ? year + 1 : year, month + 1, i);
                  days.push({
                              "day": i,
                              "month": month + 1,
                              "year": month === 11 ? year + 1 : year,
                              "today": false,
                              "currentMonth": false,
                              "lunarDay": lunarInfo["lDayZH"]
                            });
                }
      
                return days;
              }
      
              Repeater {
                model: grid.daysModel
      
                Item {
                  Layout.fillWidth: true
                  Layout.preferredHeight: Style.baseWidgetSize * 1.2
      
                  Rectangle {
                    width: Style.baseWidgetSize * 0.9
                    height: Style.baseWidgetSize * 1.2
                    anchors.centerIn: parent
                    radius: Style.radiusXS
                    color: modelData.today ? Color.mSecondary : "transparent"

                    ColumnLayout {
                      anchors.fill: parent
                      spacing: 0
                      
                      NText {
                        Layout.alignment: Qt.AlignCenter
                        text: modelData.day
                        color: {
                          if (modelData.today)
                            return Color.mOnSecondary;
                          if (modelData.currentMonth)
                            return Color.mOnSurface;
                          return Color.mOnSurfaceVariant;
                        }
                        opacity: modelData.currentMonth ? 1.0 : 0.4
                        pointSize: Style.fontSizeM
                        font.weight: modelData.today ? Style.fontWeightBold : Style.fontWeightMedium
                      }

                      NText {
                        Layout.alignment: Qt.AlignCenter
                        text: modelData.lunarDay
                        color: {
                          if (modelData.today)
                            return Color.mOnSecondary;
                          if (modelData.currentMonth)
                            return Color.mOnSurface;
                          return Color.mOnSurfaceVariant;
                        }
                        opacity: modelData.currentMonth ? 1.0 : 0.4
                        pointSize: Style.fontSizeXXS
                        font.weight: modelData.today ? Style.fontWeightBold : Style.fontWeightMedium
                      }
                    }
      
                    // Festival indicator dots
                    Row {
                      visible: CalendarApi.getDateBySolar(modelData.year, modelData.month, modelData.day)["festival"].length !== 0
                      spacing: 0
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.top: parent.bottom
                      anchors.topMargin: Style.marginXS

                      Repeater {
                        model: CalendarApi.getDateBySolar(modelData.year, modelData.month, modelData.day)["festival"].split(" ")

                        Rectangle {
                          width: 4
                          height: width
                          radius: Style.radiusXXS
                          color: Color.mOnSurface
                        }
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true

                      onEntered: {
                        const festivals = CalendarApi.getDateBySolar(modelData.year, modelData.month, modelData.day)["festival"].split(" ");
                        if (festivals.length > 0) {
                          const summaries = festivals.join("\n");
                          TooltipService.show(parent, summaries, "auto", Style.tooltipDelay, Settings.data.ui.fontFixed);
                        }
                      }

                      onExited: {
                        TooltipService.hide();
                      }
                    }
      
                    Behavior on color {
                      ColorAnimation {
                        duration: Style.animationFast
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
