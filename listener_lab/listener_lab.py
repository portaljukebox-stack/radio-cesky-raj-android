#!/usr/bin/env python3
"""Private listener-display lab. Publish one cached JSON snapshot per minute.

This tool is deliberately separate from MediaCP and the radio scheduler. It
never changes the stream, listener statistics, or the production application.
"""
import argparse
import hashlib
import json
import math
import os
import tempfile
from datetime import date, datetime, timedelta
from pathlib import Path
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo

TZ = ZoneInfo("Europe/Prague")
SOURCE = "https://portal.juke-box.cz:2020/json/stream/radioceskyraj"
DEFAULT_STATE = Path(__file__).with_name("listener_lab_state.json")
POINTS = (
    (0, .27), (2, .23), (4, .25), (6, .40), (8, .72),
    (10, .94), (12, 1.0), (14, .96), (16, .82),
    (18, .66), (20, .48), (22, .35), (24, .27),
)


def atomic_json(path, value, mode=0o644):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            os.fchmod(handle.fileno(), mode)
            json.dump(value, handle, ensure_ascii=False, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def load_state(path):
    if not path.exists():
        return {"version": 1, "initial_peak": 800, "changes": []}
    if path.is_symlink():
        raise ValueError("The configuration must not be a symlink")
    state = json.loads(path.read_text(encoding="utf-8"))
    if state.get("version") != 1 or not isinstance(state.get("changes"), list):
        raise ValueError("Invalid listener lab configuration")
    if not isinstance(state.get("initial_peak"), int) or not 1 <= state["initial_peak"] <= 100000:
        raise ValueError("Invalid initial peak")
    for change in state["changes"]:
        date.fromisoformat(change["date"])
        if (not isinstance(change["peak"], int) or not 1 <= change["peak"] <= 100000
                or not isinstance(change["ramp_days"], int) or not 0 <= change["ramp_days"] <= 365):
            raise ValueError("Invalid scheduled change")
    return state


def peak_for(state, day):
    peak = state["initial_peak"]
    for change in sorted(state["changes"], key=lambda entry: entry["date"]):
        start = date.fromisoformat(change["date"])
        if start > day:
            break
        distance = (day - start).days
        ramp = change["ramp_days"]
        if ramp and distance < ramp:
            return round(peak + (change["peak"] - peak) * (distance + 1) / ramp)
        peak = change["peak"]
    return peak


def curve(when, peak, real_connections):
    local = when.astimezone(TZ)
    hour = local.hour + local.minute / 60
    for (left_hour, left), (right_hour, right) in zip(POINTS, POINTS[1:]):
        if left_hour <= hour < right_hour:
            progress = (hour - left_hour) / (right_hour - left_hour)
            progress = progress * progress * (3 - 2 * progress)
            fraction = left + (right - left) * progress
            break
    else:
        fraction = POINTS[-1][1]
    minute = local.hour * 60 + local.minute
    day_phase = hashlib.sha256(local.date().isoformat().encode()).digest()[0] / 255 * 2 * math.pi
    noise = peak * (.006 * math.sin(minute * 2 * math.pi / 29 + day_phase)
                    + .003 * math.sin(minute * 2 * math.pi / 13 + day_phase * .7))
    return min(peak, max(0, round(peak * fraction + noise + real_connections)))


def read_real_connections():
    request = Request(SOURCE, headers={"Accept": "application/json", "Cache-Control": "no-cache"})
    with urlopen(request, timeout=10) as response:
        if response.status != 200:
            raise ValueError("MediaCP status response is not 200")
        payload = json.load(response)
    if payload.get("status") is False:
        return False, 0
    connections = payload.get("connections")
    if payload.get("status") is not True or type(connections) is not int or connections < 0:
        raise ValueError("MediaCP returned no valid status/count")
    return True, connections


def publish(state_path, output, when=None, source=read_real_connections):
    now = (when or datetime.now(TZ)).astimezone(TZ)
    epoch = int(now.timestamp()) // 60
    # A second publish within the same minute returns the same snapshot even
    # when real connections change in between. All clients fetch this file.
    if output.exists():
        try:
            old = json.loads(output.read_text(encoding="utf-8"))
            if old.get("minute_epoch") == epoch:
                return old
        except (OSError, ValueError):
            pass
    peak = peak_for(load_state(state_path), now.date())
    try:
        online, real = source()
        count = curve(now, peak, real) if online else 0
        status = "online" if online else "offline"
    except (OSError, ValueError, TimeoutError):
        real, count, status = None, None, "unknown"
    snapshot = {
        "version": 1, "test_mode": True, "status": status,
        "listeners": count, "real_connections": real,
        "daily_peak": peak, "minute_epoch": epoch,
        "updated_at": now.isoformat(),
    }
    atomic_json(output, snapshot)
    return snapshot


def main():
    parser = argparse.ArgumentParser(description="RCR private listener display lab")
    parser.add_argument("--state", type=Path, default=DEFAULT_STATE)
    sub = parser.add_subparsers(dest="command", required=True)
    setting = sub.add_parser("set-peak", help="Set today's target or schedule a later change")
    setting.add_argument("peak", type=int)
    setting.add_argument("--from-date", type=date.fromisoformat)
    setting.add_argument("--ramp-days", type=int, default=0)
    publishing = sub.add_parser("publish", help="Atomically update a static JSON file")
    publishing.add_argument("--output", type=Path, required=True)
    sub.add_parser("show")
    args = parser.parse_args()
    state = load_state(args.state)
    if args.command == "set-peak":
        if not 1 <= args.peak <= 100000 or not 0 <= args.ramp_days <= 365:
            parser.error("Peak must be 1..100000 and ramp days 0..365")
        start = args.from_date or datetime.now(TZ).date()
        state["changes"] = [c for c in state["changes"] if c["date"] != start.isoformat()]
        state["changes"].append({"date": start.isoformat(), "peak": args.peak, "ramp_days": args.ramp_days})
        atomic_json(args.state, state, mode=0o600)
        print(f"Scheduled peak {args.peak} from {start.isoformat()} over {args.ramp_days} days")
    elif args.command == "publish":
        print(json.dumps(publish(args.state, args.output), ensure_ascii=False))
    else:
        print(json.dumps(state, ensure_ascii=False, indent=2))
        print("Today's configured peak:", peak_for(state, datetime.now(TZ).date()))


if __name__ == "__main__":
    main()
