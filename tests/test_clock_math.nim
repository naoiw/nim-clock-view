## Native Nim tests for clock logic; no browser is required.

import std/[math, unittest]
import ../src/clock_math

suite "Nim Clock calculations":
  test "fractional time progress and digital formatting":
    let time = initClockTime(13, 30, 15, 500)
    check time.hours == 13
    check time.minutes == 30
    check time.seconds == 15
    check time.smoothSeconds == 15.5
    check time.smoothMinutes > 30.0
    check time.smoothHours > 1.0
    check formatTime(time.hours, time.minutes) == "13:30"
    check formatTime(8, 5) == "08:05"

  test "weekday is adjacent to the date, matching Coffee Clock":
    check formatDate(2026, 11, 17, 2) == "2026年11月17日火曜日"
    check formatDate(2026, 1, 4, 0) == "2026年1月4日日曜日"

  test "minute change triggers once, not at initialization":
    check not shouldExplode(-1, 100)
    check not shouldExplode(100, 100)
    check shouldExplode(100, 101)
    check not shouldExplode(101, 101)

  test "hue changes across the day":
    check timeHue(0, 0) == 0.0
    check timeHue(12, 0) == 180.0
    check timeHue(23, 59) < 360.0

  test "mobile and desktop geometry":
    let mobile = clockGeometry(320.0, 640.0)
    let desktop = clockGeometry(1920.0, 1080.0)
    check mobile.radius * 1.15 < 160.0
    check desktop.radius <= 214.0
    check mobile.x == 160.0
    check desktop.y == 540.0

  test "particle motion honors elapsed milliseconds":
    var p = Particle(
      x: 50.0, y: 100.0, vx: 10.0, vy: -20.0,
      hue: 180.0, age: 0.0, life: 1000.0
    )
    advanceParticle(p, 250.0)
    check abs(p.x - 52.5) < 1e-9
    check abs(p.y - 95.0) < 1e-9
    check p.age == 250.0
