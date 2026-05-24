#!/usr/bin/env python3
"""Simple Chinese Pomodoro GUI for macOS."""

from __future__ import annotations

import tkinter as tk
from tkinter import font, messagebox

from pomodoro import PomodoroModel, notify


BG = "#fff8f2"
TEXT = "#2b2b2b"
MUTED = "#8a8178"
TRACK = "#eadfd5"
TOMATO = "#df3f32"
BUTTON = "#f1e7de"
BUTTON_ACTIVE = "#ead8cd"
WHITE = "#ffffff"


class PomodoroApp:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.model = PomodoroModel()

        root.title("番茄钟")
        root.geometry("420x520")
        root.resizable(False, False)
        root.configure(bg=BG)

        self.title_font = font.Font(family="PingFang SC", size=20, weight="bold")
        self.timer_font = font.Font(family="Menlo", size=48, weight="bold")
        self.label_font = font.Font(family="PingFang SC", size=15)
        self.small_font = font.Font(family="PingFang SC", size=12)
        self.meta_font = font.Font(family="PingFang SC", size=11)

        self._build()
        self._draw()
        self._loop()

    def _build(self) -> None:
        top = tk.Frame(self.root, bg=BG)
        top.pack(fill="x", padx=28, pady=(24, 4))

        tk.Label(top, text="番茄钟", bg=BG, fg=TEXT, font=self.title_font).pack(side="left")
        self.setting_button = tk.Button(
            top,
            text="25 / 5",
            command=self.open_settings,
            bg=BG,
            activebackground=BG,
            fg=MUTED,
            font=self.small_font,
            bd=0,
            cursor="hand2",
        )
        self.setting_button.pack(side="right", pady=(4, 0))

        self.canvas = tk.Canvas(self.root, width=300, height=300, bg=BG, highlightthickness=0)
        self.canvas.pack(pady=(24, 6))

        self.status_label = tk.Label(self.root, bg=BG, fg=MUTED, font=self.label_font)
        self.status_label.pack()

        self.count_label = tk.Label(self.root, bg=BG, fg=MUTED, font=self.meta_font)
        self.count_label.pack(pady=(8, 0))

        controls = tk.Frame(self.root, bg=BG)
        controls.pack(pady=(28, 0))

        self._button(controls, "开始", self.start).grid(row=0, column=0, padx=6)
        self._button(controls, "暂停", self.pause).grid(row=0, column=1, padx=6)
        self._button(controls, "重置", self.reset).grid(row=0, column=2, padx=6)

    def _button(self, parent: tk.Widget, text: str, command: object) -> tk.Button:
        return tk.Button(
            parent,
            text=text,
            command=command,
            bg=BUTTON,
            activebackground=BUTTON_ACTIVE,
            fg=TEXT,
            font=self.small_font,
            bd=0,
            width=7,
            height=2,
            cursor="hand2",
        )

    def start(self) -> None:
        self.model.start()
        self._draw()

    def pause(self) -> None:
        self.model.pause()
        self._draw()

    def reset(self) -> None:
        self.model.reset()
        self._draw()

    def open_settings(self) -> None:
        window = tk.Toplevel(self.root)
        window.title("设置")
        window.geometry("280x190")
        window.resizable(False, False)
        window.configure(bg=WHITE)
        window.transient(self.root)
        window.grab_set()

        tk.Label(window, text="专注分钟", bg=WHITE, fg=TEXT, font=self.small_font).pack(anchor="w", padx=24, pady=(22, 4))
        focus_var = tk.StringVar(value=str(self.model.focus_minutes))
        focus_entry = tk.Entry(window, textvariable=focus_var, font=self.small_font, bd=1, relief="solid")
        focus_entry.pack(fill="x", padx=24)

        tk.Label(window, text="休息分钟", bg=WHITE, fg=TEXT, font=self.small_font).pack(anchor="w", padx=24, pady=(14, 4))
        break_var = tk.StringVar(value=str(self.model.break_minutes))
        break_entry = tk.Entry(window, textvariable=break_var, font=self.small_font, bd=1, relief="solid")
        break_entry.pack(fill="x", padx=24)

        actions = tk.Frame(window, bg=WHITE)
        actions.pack(fill="x", padx=24, pady=(18, 0))

        tk.Button(
            actions,
            text="取消",
            command=window.destroy,
            bg=BUTTON,
            activebackground=BUTTON_ACTIVE,
            fg=TEXT,
            font=self.small_font,
            bd=0,
            width=7,
            height=1,
        ).pack(side="left")
        tk.Button(
            actions,
            text="保存",
            command=lambda: self.save_settings(window, focus_var.get(), break_var.get()),
            bg=TOMATO,
            activebackground="#c9362b",
            fg=WHITE,
            font=self.small_font,
            bd=0,
            width=7,
            height=1,
        ).pack(side="right")

        focus_entry.focus_set()

    def save_settings(self, window: tk.Toplevel, focus_value: str, break_value: str) -> None:
        try:
            focus_minutes = int(focus_value)
            break_minutes = int(break_value)
        except ValueError:
            messagebox.showerror("设置错误", "请输入数字。", parent=window)
            return
        if focus_minutes <= 0 or break_minutes <= 0:
            messagebox.showerror("设置错误", "分钟数必须大于 0。", parent=window)
            return

        self.model.set_durations(focus_minutes, break_minutes)
        window.destroy()
        self._draw()

    def _loop(self) -> None:
        completed = self.model.tick()
        if completed:
            self.root.bell()
            notify("番茄钟", f"{self.model.mode_label}时间到", True)
        self._draw()
        self.root.after(1000, self._loop)

    def _draw(self) -> None:
        self.setting_button.config(text=self.model.setting_text)
        self.status_label.config(text=self.model.status_text)
        self.count_label.config(text=f"已完成 {self.model.completed_focus_sessions} 个番茄")

        self.canvas.delete("all")
        self.canvas.create_oval(34, 34, 266, 266, outline=TRACK, width=14)
        extent = -360 * self.model.progress
        self.canvas.create_arc(
            34,
            34,
            266,
            266,
            start=90,
            extent=extent,
            style="arc",
            outline=TOMATO,
            width=14,
        )
        self.canvas.create_text(150, 142, text=self.model.time_text, fill=TEXT, font=self.timer_font)
        self.canvas.create_text(150, 188, text=self.model.mode_label, fill=MUTED, font=self.label_font)


def main() -> None:
    root = tk.Tk()
    PomodoroApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
