from pathlib import Path
import subprocess
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "scripts" / "validate-calendar-architecture.py"


class CalendarArchitectureValidationTests(unittest.TestCase):
    def test_validator_accepts_the_documented_read_only_architecture(self):
        result = subprocess.run(
            [sys.executable, str(VALIDATOR)],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("calendar architecture validation passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
