import json
import tempfile
import unittest
from datetime import date, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

from listener_lab import curve, peak_for, publish

TZ = ZoneInfo("Europe/Prague")


class ListenerLabTests(unittest.TestCase):
    def test_same_minute_keeps_snapshot_when_real_connections_change(self):
        with tempfile.TemporaryDirectory() as temp:
            state = Path(temp) / "state.json"
            out = Path(temp) / "listeners.json"
            morning = datetime(2026, 11, 17, 11, 15, 1, tzinfo=TZ)
            first = publish(state, out, morning, source=lambda: (True, 2))
            second = publish(state, out, morning + timedelta(seconds=40), source=lambda: (True, 900))
            self.assertEqual(first, second)
            self.assertEqual(first, json.loads(out.read_text()))
            self.assertEqual(first["real_connections"], 2)

    def test_offline_is_zero_and_unknown_is_never_published_as_a_count(self):
        with tempfile.TemporaryDirectory() as temp:
            state = Path(temp) / "state.json"
            out = Path(temp) / "listeners.json"
            when = datetime(2026, 11, 17, 11, 0, tzinfo=TZ)
            offline = publish(state, out, when, source=lambda: (False, 0))
            self.assertEqual((offline["status"], offline["listeners"]), ("offline", 0))

            def failure():
                raise TimeoutError("source unavailable")

            unknown = publish(state, out, when + timedelta(minutes=1), source=failure)
            self.assertEqual(unknown["status"], "unknown")
            self.assertIsNone(unknown["listeners"])

    def test_peak_is_a_hard_daily_cap_and_ramp_is_date_based(self):
        state = {"initial_peak": 800, "changes": [
            {"date": "2026-12-01", "peak": 2000, "ramp_days": 12}
        ]}
        self.assertEqual(peak_for(state, date(2026, 11, 30)), 800)
        self.assertEqual(peak_for(state, date(2026, 12, 1)), 900)
        self.assertEqual(peak_for(state, date(2026, 12, 12)), 2000)
        for hour in range(24):
            for minute in range(60):
                when = datetime(2026, 11, 17, hour, minute, tzinfo=TZ)
                self.assertLessEqual(curve(when, 800, 400), 800)
                self.assertGreaterEqual(curve(when, 800, 0), 0)


if __name__ == "__main__":
    unittest.main()
