import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "kevin.sysmon"

  property string cpuUsage: "--"
  property string fanRpm: "--"
  property string diskFree: "--"
  property string memAvail: "--"
  property string diskFreePct: "--"
  property string diskUsedPct: "--"
  property string memTotal: "--"
  property string memAvailPct: "--"

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  // Command output is untrusted: keep it short and strip anything that could
  // become markup in the shell's shared tooltip.
  function clean(value) {
    var s = String(value === null || value === undefined ? "" : value)
    s = s.replace(/[<>&"'\n\r]/g, "").slice(0, 24)
    return s === "" ? "--" : s
  }

  function refresh() {
    if (!statsProc.running) statsProc.running = true
  }

  readonly property string cpuValue: clean(root.cpuUsage)
  readonly property string fanValue: clean(root.fanRpm)
  readonly property string diskValue: clean(root.diskFreePct)
  readonly property string memValue: clean(root.memAvailPct)
  readonly property string tooltipText:
    strings.t("bar.cpu") + ": " + cpuValue + " · " +
    strings.t("bar.fan") + ": " +
      (fanValue === "--" ? strings.t("bar.unavailable") : fanValue + " RPM") + " · " +
    strings.t("bar.disk") + ": " + clean(root.diskFree) + " (" +
      diskValue + " " + strings.t("bar.free") + ", " +
      clean(root.diskUsedPct) + " " + strings.t("bar.used") + ")" + " · " +
    strings.t("bar.memory") + ": " + clean(root.memAvail) + " / " +
      clean(root.memTotal) + " (" + memValue + ")"

  Component.onCompleted: refresh()

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: statsProc
    command: ["bash", Quickshell.env("HOME") + "/.config/omarchy/plugins/kevin.sysmon/stats.sh"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const lines = String(text || "").trim().split("\n")
        if (lines.length < 8) return
        root.fanRpm = lines[0]
        root.diskFree = lines[1]
        root.memAvail = lines[2]
        root.diskFreePct = lines[3]
        root.diskUsedPct = lines[4]
        root.memTotal = lines[5]
        root.memAvailPct = lines[6]
        root.cpuUsage = lines[7]
      }
    }
  }

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  Row {
    id: row

    BarIconButton {
      id: cpuButton
      bar: root.bar
      text: "󰻠" // md-cpu_64_bit
      labelText: root.cpuValue
      slotSize: Commons.Style.bar.iconCanvas + cpuMetrics.width + Commons.Style.space(8)
      tooltipText: root.tooltipText
      onPressed: root.refresh()

      TextMetrics {
        id: cpuMetrics
        font.family: cpuButton.fontFamily
        font.pixelSize: Commons.Style.bar.iconFont
        text: cpuButton.labelText
      }
    }

    BarIconButton {
      id: fanButton
      bar: root.bar
      text: "󰈐" // md-fan
      labelText: root.fanValue === "--" ? "--" : root.fanValue
      slotSize: Commons.Style.bar.iconCanvas + fanMetrics.width + Commons.Style.space(8)
      tooltipText: root.tooltipText
      onPressed: root.refresh()

      TextMetrics {
        id: fanMetrics
        font.family: fanButton.fontFamily
        font.pixelSize: Commons.Style.bar.iconFont
        text: fanButton.labelText
      }
    }

    BarIconButton {
      id: diskButton
      bar: root.bar
      text: "󰋊" // md-harddisk
      labelText: root.diskValue
      slotSize: Commons.Style.bar.iconCanvas + diskMetrics.width + Commons.Style.space(8)
      tooltipText: root.tooltipText
      onPressed: root.refresh()

      TextMetrics {
        id: diskMetrics
        font.family: diskButton.fontFamily
        font.pixelSize: Commons.Style.bar.iconFont
        text: diskButton.labelText
      }
    }

    BarIconButton {
      id: memButton
      bar: root.bar
      text: "󰍛" // md-memory
      labelText: root.memValue
      slotSize: Commons.Style.bar.iconCanvas + memMetrics.width + Commons.Style.space(8)
      tooltipText: root.tooltipText
      onPressed: root.refresh()

      TextMetrics {
        id: memMetrics
        font.family: memButton.fontFamily
        font.pixelSize: Commons.Style.bar.iconFont
        text: memButton.labelText
      }
    }
  }
}
