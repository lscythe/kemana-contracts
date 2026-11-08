import tempfile
import unittest
from pathlib import Path
from unittest import mock

from commit_scope import allowed_scopes, check_message, first_message_line, proto_files_under

PROTO_FILES = [
    Path("kemana/bundle/v1/manifest.proto"),
    Path("kemana/routing/v1/route.proto"),
    Path("kemana/routing/v1/stop.proto"),
]
SCOPES = allowed_scopes(PROTO_FILES)


class AllowedScopesTest(unittest.TestCase):
    def test_package_directories_at_every_depth_are_allowed(self):
        for s in [
            "kemana",
            "kemana:bundle",
            "kemana:bundle:v1",
            "kemana:routing",
            "kemana:routing:v1",
        ]:
            self.assertIn(s, SCOPES)

    def test_areas_are_allowed(self):
        for s in ["build", "ci", "deps", "tooling", "docs", "release"]:
            self.assertIn(s, SCOPES)

    def test_directories_without_proto_files_are_not_allowed(self):
        self.assertNotIn("kemana:fares", SCOPES)

    def test_proto_files_at_the_root_add_no_scope(self):
        scopes = allowed_scopes([Path("loose.proto")])
        self.assertEqual({"build", "ci", "deps", "tooling", "docs", "release"}, scopes)


class ProtoFilesUnderTest(unittest.TestCase):
    def test_finds_proto_files_relative_to_the_root(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "kemana" / "bundle" / "v1").mkdir(parents=True)
            (root / "kemana" / "bundle" / "v1" / "manifest.proto").write_text("")
            (root / "kemana" / "bundle" / "v1" / "notes.txt").write_text("")
            self.assertEqual([Path("kemana/bundle/v1/manifest.proto")], proto_files_under(root))

    def test_missing_root_yields_no_files(self):
        self.assertEqual([], proto_files_under(Path("/nonexistent/proto/root")))


class CheckMessageTest(unittest.TestCase):
    def test_valid_scope_passes(self):
        self.assertIsNone(check_message("feat(kemana:bundle:v1): add manifest", SCOPES))

    def test_prefix_scope_passes(self):
        self.assertIsNone(check_message("feat(kemana): add the contracts", SCOPES))

    def test_breaking_marker_passes(self):
        self.assertIsNone(check_message("feat(kemana:bundle:v1)!: drop size field", SCOPES))

    def test_unknown_scope_fails_naming_it(self):
        self.assertIn("kemana:bundl", check_message("fix(kemana:bundl): typo", SCOPES))

    def test_missing_scope_fails(self):
        self.assertIsNotNone(check_message("fix: something", SCOPES))

    def test_ci_and_docs_may_omit_scope(self):
        for m in ["ci: add workflows", "docs: add adrs"]:
            self.assertIsNone(check_message(m, SCOPES))

    def test_build_scope_passes(self):
        self.assertIsNone(check_message("build(tooling): add contracts skeleton", SCOPES))

    def test_git_generated_messages_pass(self):
        for m in [
            "Merge branch 'develop' into feature/x",
            'Revert "feat(kemana:bundle:v1): x"',
            "fixup! feat(kemana:bundle:v1): x",
            "squash! feat(kemana:bundle:v1): x",
        ]:
            self.assertIsNone(check_message(m, SCOPES))

    def test_amend_prefix_passes(self):
        self.assertIsNone(check_message("amend! feat(kemana:bundle:v1): x", SCOPES))

    def test_unknown_type_fails_naming_it(self):
        self.assertIn("feature", check_message("feature(kemana:bundle:v1): x", SCOPES))

    def test_uppercase_summary_fails(self):
        self.assertIsNotNone(check_message("feat(kemana:bundle:v1): Add manifest", SCOPES))

    def test_trailing_period_fails(self):
        self.assertIsNotNone(check_message("feat(kemana:bundle:v1): add manifest.", SCOPES))

    def test_missing_space_after_colon_fails(self):
        self.assertIsNotNone(check_message("feat(kemana:bundle:v1):add manifest", SCOPES))

    def test_empty_summary_fails(self):
        self.assertIsNotNone(check_message("feat(kemana:bundle:v1): ", SCOPES))

    def test_header_length_limit_is_72(self):
        prefix = "feat(kemana:bundle:v1): "
        at_limit = prefix + "a" * (72 - len(prefix))
        self.assertEqual(72, len(at_limit))
        self.assertIsNone(check_message(at_limit, SCOPES))
        self.assertIsNotNone(check_message(at_limit + "a", SCOPES))


class FirstMessageLineTest(unittest.TestCase):
    def test_file_is_read_as_utf_8(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "COMMIT_EDITMSG"
            path.write_text("# café comment\nfeat(kemana:bundle:v1): add manifest\n", encoding="utf-8")
            with mock.patch("io.text_encoding", side_effect=lambda encoding, stacklevel=2: encoding or "ascii"):
                self.assertEqual("feat(kemana:bundle:v1): add manifest", first_message_line(str(path)))


if __name__ == "__main__":
    unittest.main()
