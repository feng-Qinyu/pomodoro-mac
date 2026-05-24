TOMATO_RED = (226, 67, 51)
TOMATO_GREEN = (73, 145, 88)


def green_fill_fraction(progress: float) -> float:
    return min(1.0, max(0.0, progress))


def animation_frame_index(progress: float, frame_count: int) -> int:
    if frame_count <= 1:
        return 0
    clamped = green_fill_fraction(progress)
    return min(frame_count - 1, int(clamped * frame_count))
