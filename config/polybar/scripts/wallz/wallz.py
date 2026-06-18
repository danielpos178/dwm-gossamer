import argparse
import shutil
import subprocess
from pathlib import Path

BASE_DIR = Path(__file__).parent
WALLPAPER_PATH = BASE_DIR / "background.jpg"


def set_wallpaper(filepath: Path) -> None:
    subprocess.run(["feh", "--bg-fill", filepath])


def get_daily_wallpaper() -> None:
    if not WALLPAPER_PATH.exists():
        raise FileNotFoundError(f"ERROR: Cannot read \"{WALLPAPER_PATH.name}\" (this model does not support image input).")
    set_wallpaper(WALLPAPER_PATH)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Set wallpaper from background.jpg.",
    )

    args = parser.parse_args()

    get_daily_wallpaper()


if __name__ == "__main__":
    main()
