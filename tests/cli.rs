use std::fs;
use std::path::PathBuf;
use std::process::{Command, Output};
use tempfile::TempDir;

fn pd_exe() -> &'static str {
    env!("CARGO_BIN_EXE_pd")
}

// ── Test fixture ─────────────────────────────────────────────────────────────

struct Fixture {
    data_file: PathBuf,
    dir: TempDir,
}

impl Fixture {
    fn new() -> Self {
        let dir = TempDir::new().expect("failed to create temp dir");
        let data_file = dir.path().join(".pd-bookmarks");
        Self { data_file, dir }
    }

    fn run(&self, args: &[&str]) -> Output {
        Command::new(pd_exe())
            .env("PD_DATA_FILE", &self.data_file)
            .args(args)
            .output()
            .expect("failed to run pd")
    }

    fn stdout(&self, args: &[&str]) -> String {
        String::from_utf8(self.run(args).stdout).unwrap()
    }

    fn stderr(&self, args: &[&str]) -> String {
        String::from_utf8(self.run(args).stderr).unwrap()
    }

    fn ok(&self, args: &[&str]) -> bool {
        self.run(args).status.success()
    }

    fn exit_code(&self, args: &[&str]) -> i32 {
        self.run(args).status.code().unwrap_or(-1)
    }

    /// A real directory guaranteed to exist (the temp dir itself).
    fn real_path(&self) -> PathBuf {
        self.dir.path().to_path_buf()
    }
}

// ── add / get / expand ───────────────────────────────────────────────────────

#[test]
fn add_and_get() {
    let fix = Fixture::new();
    let p = fix.real_path();
    assert!(fix.ok(&["add", "work", p.to_str().unwrap()]));
    let got = fix.stdout(&["get", "work"]).trim().to_string();
    assert_eq!(got, p.display().to_string());
}

#[test]
fn add_and_expand() {
    let fix = Fixture::new();
    let p = fix.real_path();
    assert!(fix.ok(&["add", "work", p.to_str().unwrap()]));
    let got = fix.stdout(&["expand", "work"]).trim().to_string();
    assert_eq!(got, p.display().to_string());
}

#[test]
fn get_with_relative_path() {
    let fix = Fixture::new();
    let p = fix.real_path();
    let sub = p.join("sub");
    fs::create_dir_all(&sub).unwrap();
    assert!(fix.ok(&["add", "work", p.to_str().unwrap()]));
    let got = fix.stdout(&["get", "work/sub"]).trim().to_string();
    assert_eq!(got, sub.display().to_string());
}

#[test]
fn get_with_multi_level_relative_path() {
    let fix = Fixture::new();
    let p = fix.real_path();
    let deep = p.join("a").join("b").join("c");
    fs::create_dir_all(&deep).unwrap();
    assert!(fix.ok(&["add", "root", p.to_str().unwrap()]));
    let got = fix.stdout(&["get", "root/a/b/c"]).trim().to_string();
    assert_eq!(got, deep.display().to_string());
}

#[test]
fn expand_with_relative_path() {
    let fix = Fixture::new();
    let p = fix.real_path();
    let sub = p.join("docs");
    fs::create_dir_all(&sub).unwrap();
    assert!(fix.ok(&["add", "w", p.to_str().unwrap()]));
    let got = fix.stdout(&["expand", "w/docs"]).trim().to_string();
    assert_eq!(got, sub.display().to_string());
}

#[test]
fn get_missing_bookmark_exits_2() {
    let fix = Fixture::new();
    assert_eq!(fix.exit_code(&["get", "missing"]), 2);
}

// ── add edge cases ───────────────────────────────────────────────────────────

#[test]
fn add_nonexistent_path_without_force_exits_3() {
    // Non-interactive (stdin is not a tty in tests) + missing path + no --force = exit 3
    let fix = Fixture::new();
    let bogus = fix.real_path().join("does_not_exist_xyz");
    assert_eq!(fix.exit_code(&["add", "nope", bogus.to_str().unwrap()]), 3);
}

#[test]
fn add_nonexistent_path_with_force_succeeds() {
    let fix = Fixture::new();
    let bogus = fix.real_path().join("does_not_exist_xyz");
    assert!(fix.ok(&["add", "--force", "nope", bogus.to_str().unwrap()]));
    let got = fix.stdout(&["get", "nope"]).trim().to_string();
    assert_eq!(got, bogus.display().to_string());
}

#[test]
fn add_invalid_name_slash_exits_5() {
    let fix = Fixture::new();
    let p = fix.real_path();
    assert_eq!(fix.exit_code(&["add", "bad/name", p.to_str().unwrap()]), 5);
}

#[test]
fn add_invalid_name_leading_dash_exits_5() {
    let fix = Fixture::new();
    let p = fix.real_path();
    assert_eq!(fix.exit_code(&["add", "-bad", p.to_str().unwrap()]), 5);
}

#[test]
fn add_overwrites_existing_silently_when_non_interactive() {
    let fix = Fixture::new();
    let p = fix.real_path();
    let sub = p.join("v2");
    fs::create_dir_all(&sub).unwrap();
    assert!(fix.ok(&["add", "proj", p.to_str().unwrap()]));
    // Non-interactive without --force: prints a warning but still overwrites
    assert!(fix.ok(&["add", "proj", sub.to_str().unwrap()]));
    let got = fix.stdout(&["get", "proj"]).trim().to_string();
    assert_eq!(got, sub.display().to_string());
}

// ── del ──────────────────────────────────────────────────────────────────────

#[test]
fn del_removes_bookmark() {
    let fix = Fixture::new();
    let p = fix.real_path();
    assert!(fix.ok(&["add", "tmp", p.to_str().unwrap()]));
    assert!(fix.ok(&["del", "tmp"]));
    assert_eq!(fix.exit_code(&["get", "tmp"]), 2);
}

#[test]
fn del_missing_exits_2() {
    let fix = Fixture::new();
    assert_eq!(fix.exit_code(&["del", "nope"]), 2);
}

// ── list ─────────────────────────────────────────────────────────────────────

#[test]
fn list_empty_prints_message_to_stderr() {
    let fix = Fixture::new();
    let out = fix.run(&["list"]);
    assert!(out.status.success());
    assert!(out.stdout.is_empty());
    assert!(fix.stderr(&["list"]).contains("No bookmarks"));
}

#[test]
fn list_shows_all_added_bookmarks() {
    let fix = Fixture::new();
    let p = fix.real_path();
    assert!(fix.ok(&["add", "alpha", p.to_str().unwrap()]));
    assert!(fix.ok(&["add", "beta", p.to_str().unwrap()]));
    let out = fix.stdout(&["list"]);
    assert!(out.contains("alpha"));
    assert!(out.contains("beta"));
}

// ── clear ────────────────────────────────────────────────────────────────────

#[test]
fn clear_with_force_removes_all() {
    let fix = Fixture::new();
    let p = fix.real_path();
    assert!(fix.ok(&["add", "a", p.to_str().unwrap()]));
    assert!(fix.ok(&["add", "b", p.to_str().unwrap()]));
    assert!(fix.ok(&["clear", "--force"]));
    assert!(fix.stderr(&["list"]).contains("No bookmarks"));
}

#[test]
fn clear_empty_store_succeeds() {
    let fix = Fixture::new();
    assert!(fix.ok(&["clear", "--force"]));
}

// ── export / import ───────────────────────────────────────────────────────────

#[test]
fn export_and_import_roundtrip() {
    let fix = Fixture::new();
    let p = fix.real_path();
    assert!(fix.ok(&["add", "src", p.to_str().unwrap()]));
    assert!(fix.ok(&["add", "docs", p.to_str().unwrap()]));

    let export_file = p.join("exported.pd");
    assert!(fix.ok(&["export", export_file.to_str().unwrap()]));

    assert!(fix.ok(&["clear", "--force"]));
    // Non-interactive import replaces without prompting even without --force
    assert!(fix.ok(&["import", export_file.to_str().unwrap()]));

    let out = fix.stdout(&["list"]);
    assert!(out.contains("src"));
    assert!(out.contains("docs"));
}

#[test]
fn import_append_preserves_existing_and_adds_new() {
    let fix = Fixture::new();
    let p = fix.real_path();
    let sub = p.join("sub");
    fs::create_dir_all(&sub).unwrap();

    // "work" points to sub
    assert!(fix.ok(&["add", "work", sub.to_str().unwrap()]));

    // Import file has "work" pointing to p (should be ignored) and a new "extra"
    let import_file = p.join("import.pd");
    fs::write(
        &import_file,
        format!("work {}\nextra {}\n", p.display(), p.display()),
    )
    .unwrap();

    assert!(fix.ok(&["import", "--append", import_file.to_str().unwrap()]));

    // "work" must still point to sub
    let got = fix.stdout(&["get", "work"]).trim().to_string();
    assert_eq!(got, sub.display().to_string());

    // "extra" must have been added
    assert!(fix.ok(&["get", "extra"]));
}

// ── short flags ───────────────────────────────────────────────────────────────

#[test]
fn short_flag_a_adds_bookmark() {
    let fix = Fixture::new();
    let p = fix.real_path();
    assert!(fix.ok(&["-a", "w", p.to_str().unwrap()]));
    assert!(fix.ok(&["get", "w"]));
}

#[test]
fn short_flag_d_deletes_bookmark() {
    let fix = Fixture::new();
    let p = fix.real_path();
    fix.ok(&["add", "w", p.to_str().unwrap()]);
    assert!(fix.ok(&["-d", "w"]));
    assert_eq!(fix.exit_code(&["get", "w"]), 2);
}

#[test]
fn short_flag_l_lists_bookmarks() {
    let fix = Fixture::new();
    let p = fix.real_path();
    fix.ok(&["add", "w", p.to_str().unwrap()]);
    assert!(fix.stdout(&["-l"]).contains("w"));
}

#[test]
fn short_flag_x_expands_bookmark() {
    let fix = Fixture::new();
    let p = fix.real_path();
    fix.ok(&["add", "w", p.to_str().unwrap()]);
    let got = fix.stdout(&["-x", "w"]).trim().to_string();
    assert_eq!(got, p.display().to_string());
}

#[test]
fn short_flags_e_and_i_export_import() {
    let fix = Fixture::new();
    let p = fix.real_path();
    fix.ok(&["add", "x", p.to_str().unwrap()]);

    let export_file = p.join("e.pd");
    assert!(fix.ok(&["-e", export_file.to_str().unwrap()]));

    fix.ok(&["clear", "--force"]);
    assert!(fix.ok(&["-i", export_file.to_str().unwrap()]));
    assert!(fix.stdout(&["list"]).contains("x"));
}

// ── init / completions ────────────────────────────────────────────────────────

#[test]
fn init_bash_produces_output() {
    let fix = Fixture::new();
    let out = fix.stdout(&["init", "bash"]);
    assert!(!out.trim().is_empty());
    assert!(out.contains("pd"));
}

#[test]
fn init_nu_produces_output() {
    let fix = Fixture::new();
    let out = fix.stdout(&["init", "nu"]);
    assert!(!out.trim().is_empty());
    assert!(out.contains("pd"));
}

#[test]
fn init_pwsh_produces_output() {
    let fix = Fixture::new();
    let out = fix.stdout(&["init", "pwsh"]);
    assert!(!out.trim().is_empty());
    assert!(out.contains("pd"));
}

#[test]
fn completions_bash_produces_output() {
    let fix = Fixture::new();
    assert!(!fix.stdout(&["completions", "bash"]).trim().is_empty());
}

#[test]
fn completions_nu_produces_output() {
    let fix = Fixture::new();
    assert!(!fix.stdout(&["completions", "nu"]).trim().is_empty());
}

#[test]
fn completions_pwsh_produces_output() {
    let fix = Fixture::new();
    assert!(!fix.stdout(&["completions", "pwsh"]).trim().is_empty());
}
