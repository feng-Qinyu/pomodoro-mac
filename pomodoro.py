#!/usr/bin/env python3
"""A small terminal Pomodoro timer for macOS."""

from __future__ import annotations

import argparse
import signal
import subprocess
import sys
import time
from dataclasses import dataclass


@dataclass(frozen=True)
class ScheduleItem:
    label: str
    minutes: int


class PomodoroModel:
    def __init__(self, focus_minutes: int = 25, break_minutes: int = 5) -> None:
        self.focus_minutes = focus_minutes
        self.break_minutes = break_minutes
        self.mode = "focus"
        self.running = False
        self.completed_focus_sessions = 0
        self.remaining_seconds = self.total_seconds

    @property
    def total_seconds(self) -> int:
        minutes = self.focus_minutes if self.mode == "focus" else self.break_minutes
        return minutes * 60

    @property
    def mode_label(self) -> str:
        return "专注" if self.mode == "focus" else "休息"

    @property
    def status_text(self) -> str:
        return f"{self.mode_label}中" if self.running else self.mode_label

    @property
    def time_text(self) -> str:
        return format_remaining(self.remaining_seconds)

    @property
    def progress(self) -> float:
        if self.total_seconds == 0:
            return 0.0
        return 1 - (self.remaining_seconds / self.total_seconds)

    @property
    def setting_text(self) -> str:
        return f"{self.focus_minutes} / {self.break_minutes}"

    def start(self) -> None:
        self.running = True

    def pause(self) -> None:
        self.running = False

    def reset(self) -> None:
        self.running = False
        self.remaining_seconds = self.total_seconds

    def set_durations(self, focus_minutes: int, break_minutes: int) -> None:
        self.focus_minutes = focus_minutes
        self.break_minutes = break_minutes
        self.reset()

    def tick(self) -> bool:
        if not self.running:
            return False
        self.remaining_seconds -= 1
        if self.remaining_seconds <= 0:
            self._switch_mode()
            return True
        return False

    def _switch_mode(self) -> None:
        if self.mode == "focus":
            self.completed_focus_sessions += 1
        self.running = False
        self.mode = "break" if self.mode == "focus" else "focus"
        self.remaining_seconds = self.total_seconds


def positive_int(value: str) -> int:
    number = int(value)
    if number <= 0:
        raise ValueError("must be greater than 0")
    return number


def argparse_positive_int(value: str) -> int:
    try:
        return positive_int(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc


def format_remaining(seconds: int) -> str:
    minutes, seconds = divmod(max(0, seconds), 60)
    return f"{minutes:02d}:{seconds:02d}"


def build_schedule(
    work: int,
    short_break: int,
    long_break: int,
    sessions: int,
    long_interval: int,
) -> list[ScheduleItem]:
    schedule: list[ScheduleItem] = []
    for session in range(1, sessions + 1):
        schedule.append(ScheduleItem(f"Focus {session}", work))
        if session % long_interval == 0:
            schedule.append(ScheduleItem(f"Long break {session}", long_break))
        elif session != sessions:
            schedule.append(ScheduleItem(f"Short break {session}", short_break))
    return schedule


def notify(title: str, message: str, enabled: bool) -> None:
    if not enabled or sys.platform != "darwin":
        return

    script = (
        'display notification '
        f'{message!r} with title {title!r} sound name "Glass"'
    )
    try:
        subprocess.run(["osascript", "-e", script], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def bell(enabled: bool) -> None:
    if enabled:
        print("\a", end="", flush=True)


def clear_line() -> None:
    print("\r\033[K", end="", flush=True)


def run_timer(item: ScheduleItem, *, notify_enabled: bool, bell_enabled: bool, dry_run: bool) -> None:
    total_seconds = item.minutes * 60
    notify("Pomodoro", f"{item.label} started ({item.minutes} min)", notify_enabled)

    if dry_run:
        print(f"{item.label}: {format_remaining(total_seconds)}")
        return

    while total_seconds >= 0:
        print(f"\r{item.label:<18} {format_remaining(total_seconds)}  Ctrl+C to stop", end="", flush=True)
        if total_seconds == 0:
            break
        time.sleep(1)
        total_seconds -= 1

    clear_line()
    bell(bell_enabled)
    print(f"Done: {item.label}")
    notify("Pomodoro", f"{item.label} finished", notify_enabled)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run a Pomodoro timer in the terminal.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("-w", "--work", type=argparse_positive_int, default=25, help="focus minutes")
    parser.add_argument("-s", "--short-break", type=argparse_positive_int, default=5, help="short break minutes")
    parser.add_argument("-l", "--long-break", type=argparse_positive_int, default=15, help="long break minutes")
    parser.add_argument("-n", "--sessions", type=argparse_positive_int, default=4, help="focus sessions")
    parser.add_argument("-i", "--long-interval", type=argparse_positive_int, default=4, help="long break interval")
    parser.add_argument("--no-notify", action="store_true", help="disable macOS notifications")
    parser.add_argument("--no-bell", action="store_true", help="disable terminal bell")
    parser.add_argument("--dry-run", action="store_true", help="print the schedule without waiting")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    schedule = build_schedule(
        work=args.work,
        short_break=args.short_break,
        long_break=args.long_break,
        sessions=args.sessions,
        long_interval=args.long_interval,
    )

    print("Pomodoro timer")
    print("Schedule: " + " -> ".join(f"{item.label} ({item.minutes}m)" for item in schedule))
    print()

    if args.dry_run:
        for item in schedule:
            run_timer(item, notify_enabled=False, bell_enabled=False, dry_run=True)
        return 0

    original_sigint = signal.getsignal(signal.SIGINT)
    try:
        for item in schedule:
            run_timer(
                item,
                notify_enabled=not args.no_notify,
                bell_enabled=not args.no_bell,
                dry_run=False,
            )
    except KeyboardInterrupt:
        clear_line()
        print("Stopped.")
        return 130
    finally:
        signal.signal(signal.SIGINT, original_sigint)

    print("All sessions complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
