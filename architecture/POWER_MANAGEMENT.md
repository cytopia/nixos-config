# Power management architecture

## Purpose

This document says which service owns each power event on a NixOS sway laptop. It lists the target settings and the state of host core.

## Ownership

| Service | Owns | Must not own | NixOS option |
|---|---|---|---|
| logind | Keys, lid, inhibitor broker, lock signal. [1] [2] | Idle timers. | `services.logind.settings.Login` |
| swayidle | Idle timers, monitor off, before-sleep, lock handler. [3] | Lid and key events. | Started by sway `exec`. No restart on crash. Accepted. |
| systemd-sleep | How sleep runs and when it turns into hibernate. [5] | When to sleep. | `systemd.sleep.settings.Sleep` |
| swaylock | The lock screen. [10] | Idle timers and sleep. | `programs.sway.enable` |
| sway | Key bindings, inhibit rules, `output power` commands. [4] | Lid and power key events. | `programs.sway.enable` |
| upower | Critical-battery hibernate. [11] | Lid and idle policy. | `services.upower` |
| kernel and boot | Hibernate image target. [8] | Zram as image target. | `boot.resumeDevice`, `swapDevices`, `zramSwap` |
| inhibitors | What blocks monitor off, idle sleep and lid sleep. [2] | Sleep started by root. | none |

## Rules

| Rule | Service | Why |
|---|---|---|
| Lid and keys belong to logind only. [1] [7] | logind | Two handlers act twice. |
| `IdleAction=ignore` while swayidle runs. [1] [3] | logind | Both would start sleep. |
| No swayidle `idlehint` beside a swayidle sleep timer. [1] [3] | swayidle | Same double trigger. |
| Run one idle daemon only. [3] | swayidle | Two ladders share one protocol. |
| No `HandleLidSwitch*` beside sway `bindswitch lid:*`. [4] [6] | logind, sway | Logind would act on the lid too. |
| No acpid beside logind `Handle*`. [7] | logind | Two handlers for ACPI events. |
| No X11 tools such as `xset dpms`. [6] | sway | They do not cover Wayland. |
| Idle and manual locks go through `loginctl lock-session`. `before-sleep` is the exception. [3] | logind, swayidle | One entry point. |
| `before-sleep` starts the locker directly. [3] | swayidle, swaylock | The lock must exist before sleep. |
| Monitor off comes before lock. [3] | swayidle | Chosen order for this setup. |
| Define the sleep verb once. [5] | sway | Idle and menu then match. |
| Test `output * power off` on NVIDIA hybrid. [6] | sway | Arch reports a driver deadlock. |

## Best case

| Event | Service | Setting | Value |
|---|---|---|---|
| Power off | logind | `HandlePowerKey` | `suspend-then-hibernate` [1] |
| Power off | logind | `HandlePowerKeyLongPress` | `poweroff` [1] |
| Power off | logind | Suspend, hibernate and reboot keys | `ignore` [1] |
| Power off | logind | Key `*IgnoreInhibited` | `no` [1] |
| Power off | sway | Menu key | `systemctl poweroff` |
| Sleep | logind | Lid on battery and on AC | `suspend-then-hibernate` [1] [7] |
| Sleep | logind | `HandleLidSwitchDocked` | `ignore` [1] [7] |
| Sleep | logind | `LidSwitchIgnoreInhibited` | `yes` [1] |
| Sleep | logind | `HoldoffTimeoutSec` | `30s` [1] |
| Sleep | logind | `InhibitDelayMaxSec` | `5s` [1] |
| Sleep | logind | `IdleAction` | `ignore` [1] [6] |
| Sleep | sway | `$suspend` | `systemctl suspend-then-hibernate \|\| systemctl suspend` |
| Sleep | sway | Menu key `s` | `loginctl lock-session; $suspend` |
| Sleep | swayidle | AC sleep timer | `timeout 3600 '$suspend'` [3] |
| Hibernate | kernel and boot | Resume device | One disk swap that matches the active swap. [8] [9] |
| Hibernate | kernel and boot | Zram | Never the image target. [8] |
| Hibernate | upower | Low, critical, action percent | 15, 10, 5 [11] |
| Hibernate | upower | `criticalPowerAction` | `Hibernate` [11] |
| Hibernate | sway | Menu key `h` | `loginctl lock-session; systemctl hibernate \|\| systemctl suspend` |
| Sleep-then-hibernate | systemd-sleep | `HibernateDelaySec` | `1h` [5] |
| Sleep-then-hibernate | systemd-sleep | `HibernateOnACPower` | `false` [5] |
| Sleep-then-hibernate | systemd-sleep | `SuspendEstimationSec` | `30min` [5] |
| Sleep-then-hibernate | swayidle | Battery sleep timer | `timeout 900 'systemd-ac-power \|\| $suspend'` [3] |
| Monitor off | swayidle | Idle timer | `timeout 600` runs `swaymsg "output * power off"` [3] [4] |
| Monitor off | swayidle | `resume` | `swaymsg "output * power on"` [3] |
| Monitor off | swayidle | `after-resume` | `swaymsg "output * power on"` [3] |
| Monitor off | sway | `inhibit_idle` | `fullscreen` for GeForce NOW [4] |
| Monitor off | inhibitors | Audio | `sway-audio-idle-inhibit` holds an idle lock. [2] |
| Lock screen | swayidle | Idle timer | `timeout 660 'loginctl lock-session'` [3] |
| Lock screen | swayidle | Order | Monitor off 600 s, lock 660 s, sleep 900 s. |
| Lock screen | swayidle | `before-sleep` | `$mute; $lock` [3] |
| Lock screen | swayidle | `lock` handler | `$mute; $lock` [3] |
| Lock screen | swaylock | Look | Static image, black fallback colour, no screenshots. [10] |
| Lock screen | swaylock | Protocol | `ext-session-lock-v1` [10] |
| Lock screen | logind | Manual lock | `loginctl lock-session` [1] |

## Status on core

| Service | Responsibility | Current on core | Status | Fix |
|---|---|---|---|---|
| logind | Lid docked: ignore | `HandleLidSwitchDocked=ignore` | partial | After monitor off, lid close may suspend. Untested: `HandleLidSwitchExternalPower = "ignore";`. It affects all AC closes. |
| logind | Lid on AC, not docked | `HandleLidSwitchExternalPower=suspend-then-hibernate` | ok | |
| logind | Lid on battery, not docked | `HandleLidSwitch=suspend-then-hibernate` | ok | |
| logind | Power key short press | `HandlePowerKey=suspend-then-hibernate` | ok | |
| logind | Power key long press | `HandlePowerKeyLongPress=poweroff` | ok | |
| logind | Suspend key | `HandleSuspendKey=ignore`, `LongPress=ignore` | ok | |
| logind | Hibernate key | `HandleHibernateKey=ignore`, `LongPress=ignore` | ok | |
| logind | Inhibitor broker | `LidSwitchIgnoreInhibited=yes`, key `IgnoreInhibited=no`, `InhibitDelayMaxSec=5s` | ok | |
| logind | Emit lock signal | `loginctl lock-session` in timer and menu | ok | |
| logind | `IdleAction=ignore` while swayidle runs | `IdleAction=ignore`, `IdleActionSec=30m` | ok | |
| logind | Keys explicit, no defaults | Power, suspend, hibernate, reboot and secure attention keys set. Lid set. Holdoff 30 s, delay 5 s. | ok | |
| upower | Action at 5 % only | `PercentageAction=5`, `Critical=10`, `Low=15` | ok | |
| upower | Action is hibernate | `CriticalPowerAction=Hibernate` | ok | |
| systemd-sleep | `HibernateDelaySec` timer | `1h` | ok | |
| systemd-sleep | `HibernateOnACPower` | `false` | ok | |
| systemd-sleep | Swap check and resume | `resume=/dev/pool/swap`, same `resumeDevice` | partial | No hibernate ran on this boot. Run one real `systemctl hibernate`. |
| swayidle | Monitor off first | `timeout 600` power off, `resume` power on | ok | |
| swayidle | Lock a few seconds after monitor off | `timeout 660 loginctl lock-session` | ok | |
| swayidle | Idle sleep last, with fallback | `timeout 900 systemd-ac-power \|\| $suspend`, `timeout 3600 $suspend` | ok | |
| swayidle | `before-sleep` runs locker | `before-sleep $mute; $lock` | ok | |
| swayidle | `lock` handler runs locker | `lock $mute; $lock` | ok | |
| swayidle | After-resume monitor on | `after-resume swaymsg "output * power on"` | ok | |
| swayidle | Started as user unit, sway `exec` as fallback | `exec swayidle -w`. No user unit. | accepted | |
| swaylock | Lock screen with `ext-session-lock-v1` | Image, black colour, pixelate 50, daemonize. Version 1.7.0.0. PAM service `swaylock`. | ok | |
| sway | Menu key suspend | `loginctl lock-session; $suspend` | ok | |
| sway | Menu key hibernate | `loginctl lock-session; systemctl hibernate \|\| systemctl suspend` | ok | |
| sway | `inhibit_idle` rules | `inhibit_idle fullscreen` for GeForce NOW | ok | |
| sway | Runs `output * power` | `swaymsg "output * power off"` and `on` from swayidle | ok | |
| sleep verb | Defined once, reused | `$suspend` on the sway side. Separate Nix option on the logind side. | partial | Two definitions can drift. Keep both in step. |
| sleep verb | Fallback to plain suspend | `$suspend` ends with `\|\| systemctl suspend`. Hibernate key does too. | ok | |

## Open checks

| Check | Proves | Expected |
|---|---|---|
| Docked lid close after monitor off | Docked rule survives disabled output. | Machine stays awake. |
| One real hibernate | Swap and resume work. | Session returns after power on. |
| Lock image file exists | Lock screen shows the image. | File resolves. |
| Deployed sleep settings | Deployed sleep config equals the tree. | Values match. |
| Session type | Sway runs on Wayland. | `wayland` |
| Kernel lockdown level | Hibernate is not blocked. | `none` |

## Sources

1. logind.conf(5), systemd 262, https://www.freedesktop.org/software/systemd/man/262/logind.conf.html
2. systemd Inhibitor Locks, https://systemd.io/INHIBITOR_LOCKS/
3. swayidle(1) 1.9.1, https://raw.githubusercontent.com/swaywm/swayidle/v1.9.1/swayidle.1.scd
4. sway(5) 1.12, https://raw.githubusercontent.com/swaywm/sway/1.12/sway/sway.5.scd
5. systemd-sleep.conf(5), systemd 262, https://www.freedesktop.org/software/systemd/man/262/systemd-sleep.conf.html
6. Arch wiki, Sway, https://wiki.archlinux.org/title/Sway
7. Arch wiki, Power management, https://wiki.archlinux.org/title/Power_management
8. Arch wiki, Power management/Suspend and hibernate, https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate
9. NixOS wiki, Power Management, https://wiki.nixos.org/wiki/Power_Management
10. swaylock-effects 1.7.0.0 source, https://github.com/jirutka/swaylock-effects/tree/v1.7.0.0
11. upower module, nixpkgs rev 0bb2eedc, https://raw.githubusercontent.com/NixOS/nixpkgs/0bb2eedc20e4739f29e8045034f2828ad7054f8f/nixos/modules/services/hardware/upower.nix
