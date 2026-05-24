import unittest

from pomodoro import PomodoroModel, build_schedule, format_remaining, positive_int
from pomodoro_design import animation_frame_index, green_fill_fraction


class PomodoroTests(unittest.TestCase):
    def test_format_remaining_uses_mm_ss(self):
        self.assertEqual(format_remaining(0), "00:00")
        self.assertEqual(format_remaining(65), "01:05")
        self.assertEqual(format_remaining(3605), "60:05")

    def test_build_schedule_adds_long_break_after_interval(self):
        schedule = build_schedule(work=25, short_break=5, long_break=15, sessions=4, long_interval=4)

        self.assertEqual(
            [(item.label, item.minutes) for item in schedule],
            [
                ("Focus 1", 25),
                ("Short break 1", 5),
                ("Focus 2", 25),
                ("Short break 2", 5),
                ("Focus 3", 25),
                ("Short break 3", 5),
                ("Focus 4", 25),
                ("Long break 4", 15),
            ],
        )

    def test_positive_int_rejects_zero_or_negative(self):
        with self.assertRaises(ValueError):
            positive_int("0")
        with self.assertRaises(ValueError):
            positive_int("-1")
        self.assertEqual(positive_int("3"), 3)

    def test_model_starts_pauses_and_resets(self):
        model = PomodoroModel(focus_minutes=1, break_minutes=1)

        self.assertEqual(model.mode_label, "专注")
        self.assertEqual(model.time_text, "01:00")
        self.assertFalse(model.running)

        model.start()
        model.tick()
        model.pause()

        self.assertEqual(model.time_text, "00:59")
        self.assertFalse(model.running)

        model.reset()

        self.assertEqual(model.time_text, "01:00")
        self.assertFalse(model.running)

    def test_model_switches_to_break_when_focus_finishes(self):
        model = PomodoroModel(focus_minutes=1, break_minutes=1)
        model.start()

        for _ in range(60):
            model.tick()

        self.assertEqual(model.mode_label, "休息")
        self.assertEqual(model.time_text, "01:00")
        self.assertFalse(model.running)

    def test_model_applies_new_durations_from_focus_mode(self):
        model = PomodoroModel(focus_minutes=25, break_minutes=5)
        model.set_durations(focus_minutes=30, break_minutes=10)

        self.assertEqual(model.setting_text, "30 / 10")
        self.assertEqual(model.time_text, "30:00")

    def test_model_counts_completed_focus_sessions(self):
        model = PomodoroModel(focus_minutes=1, break_minutes=1)
        model.start()

        for _ in range(60):
            model.tick()

        self.assertEqual(model.completed_focus_sessions, 1)

    def test_green_fill_fraction_clamps_progress(self):
        self.assertEqual(green_fill_fraction(-1), 0)
        self.assertEqual(green_fill_fraction(0), 0)
        self.assertEqual(green_fill_fraction(0.4), 0.4)
        self.assertEqual(green_fill_fraction(1), 1)
        self.assertEqual(green_fill_fraction(2), 1)

    def test_animation_frame_index_uses_full_frame_range(self):
        self.assertEqual(animation_frame_index(0, 8), 0)
        self.assertEqual(animation_frame_index(0.5, 8), 4)
        self.assertEqual(animation_frame_index(1, 8), 7)
        self.assertEqual(animation_frame_index(-1, 8), 0)
        self.assertEqual(animation_frame_index(2, 8), 7)


if __name__ == "__main__":
    unittest.main()
