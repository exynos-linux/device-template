#!/usr/bin/env python3
"""Tests for scripts/config: derived values, validation, channels.

    python3 -I tests/config/test_config.py
"""
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "scripts" / "config"


def run(*args, text=None, env=None):
    e = {k: v for k, v in os.environ.items() if k != "GITHUB_REPOSITORY"}
    e.update(env or {})
    if text is not None:
        f = tempfile.NamedTemporaryFile("w", suffix=".toml", delete=False)
        f.write(text)
        f.close()
        e["CONFIG"] = f.name
    return subprocess.run([str(CONFIG), *args], capture_output=True, text=True, env=e)


def port(**over):
    """The template's config.toml as a filled-in port."""
    t = (ROOT / "config.toml").read_text()
    t = t.replace("template = true", "template = false")
    t = t.replace('vendor = "vendor"', 'vendor = "samsung"').replace('codename = "codename"', 'codename = "testtab"')
    t = t.replace('soc = "exynosxxxx"', 'soc = "exynos9999"')
    for a, b in over.items():
        t = t.replace(a, b)
    return t


class Config(unittest.TestCase):
    def test_template_is_valid(self):
        r = run("check")
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_derived(self):
        c = json.loads(run("json", text=port()).stdout)
        self.assertEqual(c["device"]["id"], "samsung-testtab")
        self.assertEqual(c["kernel"]["package"], "linux-postmarketos-exynos9999")
        self.assertEqual(c["update"]["base"], "https://github.com/exynos-linux/device-template/releases/download/")
        self.assertEqual(c["update"]["pages"], "https://exynos-linux.github.io/device-template")
        self.assertEqual(c["update"]["channel_file"], "/usr/lib/samsung-testtab/update-channel")
        self.assertEqual(c["bootchain"]["tag"], "samsung-testtab_bootchain")
        self.assertEqual(c["installer"]["name"], "testtab-setup")

    def test_fork_publishes_to_itself(self):
        c = json.loads(run("json", text=port(), env={"GITHUB_REPOSITORY": "Someone/fork"}).stdout)
        self.assertEqual(c["update"]["base"], "https://github.com/Someone/fork/releases/download/")
        self.assertEqual(c["update"]["pages"], "https://someone.github.io/fork")

    def test_channels(self):
        out = run("channels", text=port()).stdout.split("\n")
        self.assertIn("phosh dev samsung-testtab_phosh_edge-dev", out)
        self.assertIn("gnome release samsung-testtab_gnome_edge", out)
        out = run("channels", text=port(**{"release = true": "release = false"})).stdout
        self.assertNotIn(" release ", out)
        m = json.loads(run("matrix", text=port()).stdout)
        self.assertEqual(len(m["include"]), 4)

    def test_shell_quoting(self):
        out = run("shell", text=port()).stdout
        env = subprocess.run(["bash", "-c", out + '\nprintf "%s|%s" "$CFG_DEVICE_NAME" "$CFG_IMAGES_UIS"'],
                             capture_output=True, text=True).stdout
        self.assertEqual(env, "Example tablet|phosh gnome")

    def test_template_values_rejected_in_a_port(self):
        r = run("check", text=port(**{'vendor = "samsung"': 'vendor = "vendor"'}))
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("template value", r.stderr)

    def test_errors(self):
        for a, b, msg in [
            ('default_ui = "phosh"', 'default_ui = "plasma"', "default_ui"),
            ('release = "edge"', 'release = "latest"', "images.release"),
            ('flash_allow = ["BOOT", "RECOVERY"]', 'flash_allow = ["BOOT", "EFS"]', "protected partition"),
            ('download_usb = "04e8:685d"', 'download_usb = "x"', "download_usb"),
            ('fingerprint = ""', 'fingerprint = "abc"', "fingerprint"),
        ]:
            r = run("check", text=port(**{a: b}))
            self.assertNotEqual(r.returncode, 0, a)
            self.assertIn(msg, r.stderr, a)

    def test_get(self):
        self.assertEqual(run("get", "ui.gnome.title").stdout.strip(), "GNOME")
        self.assertNotEqual(run("get", "no.such.key").returncode, 0)


if __name__ == "__main__":
    unittest.main(verbosity=1)
