"""Bootstrap tests: these run even before addon gameplay code exists."""
from pathlib import Path
from tempfile import TemporaryDirectory
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import build
import version as release_version


class ManifestTests(unittest.TestCase):
    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addon = Path(self.tmp.name)
        (self.addon / "FoodGuardian.toc").write_text(
            "## Interface: 16001\n## Title: Food Guardian\n## Version: 1.0b1\n\nCore.lua\n",
            encoding="utf-8",
        )
        (self.addon / "Core.lua").write_text("-- minimal test fixture\n", encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    def test_valid_manifest(self):
        version, names = build.validate_manifest(self.addon)
        self.assertEqual(version, "1.0b1")
        self.assertIn(Path("Core.lua"), names)

    def test_stable_version_manifest(self):
        toc = self.addon / "FoodGuardian.toc"
        toc.write_text(toc.read_text(encoding="utf-8").replace("1.0b1", "1.0.0"), encoding="utf-8")
        version, _ = build.validate_manifest(self.addon)
        self.assertEqual(version, "1.0.0")

    def test_missing_lua_rejected(self):
        (self.addon / "Core.lua").unlink()
        with self.assertRaisesRegex(ValueError, "Missing TOC file"):
            build.validate_manifest(self.addon)

    def test_traversal_rejected(self):
        (self.addon / "FoodGuardian.toc").write_text(
            "## Interface: 16001\n## Version: 1.0b1\n\n../outside.lua\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(ValueError, "Unsafe manifest entry"):
            build.validate_manifest(self.addon)

    def test_packaged_structure(self):
        with TemporaryDirectory() as dist:
            result = build.build(self.addon, Path(dist))
            import zipfile
            with zipfile.ZipFile(result) as archive:
                self.assertIn("FoodGuardian/FoodGuardian.toc", archive.namelist())
                self.assertIn("FoodGuardian/Core.lua", archive.namelist())


class BetaVersionTests(unittest.TestCase):
    def select(self, tags, at_head=()):
        with patch.dict("os.environ", {"GITHUB_REF": "refs/heads/main"}), \
             patch.object(release_version, "current_version", return_value="1.1b9"), \
             patch.object(release_version, "git", side_effect=[tags, at_head]):
            return release_version.select()

    def test_qa_beta_number_is_preserved(self):
        self.assertEqual(self.select([]), "1.1b9")
        self.assertEqual(self.select(["forever-1.1b2"]), "1.1b9")

    def test_existing_beta_advances(self):
        self.assertEqual(self.select(["forever-1.1b9"]), "1.1b10")

    def test_retry_at_head_reuses_version(self):
        self.assertEqual(self.select(["forever-1.1b9"], ["forever-1.1b9"]), "1.1b9")


if __name__ == "__main__":
    unittest.main()
