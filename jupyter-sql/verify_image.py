#!/usr/bin/env python3
"""Assert the console image contains exactly what the worksheets need.

Runs as a BUILD step in the Dockerfile, so a broken image fails at build time
instead of in front of a class. It is also runnable against a live container:

    podman exec sql-console-lan python3 /tmp/verify_image.py

Why the versions are exact rather than minimums: this repo's guarantee is that
every number quoted in a solution is output somebody observed. A different
pandas can change a dtype, a repr, or an error message and silently invalidate
hundreds of verified figures. "pandas is installed" is not the requirement --
"pandas 3.0.5 is installed" is.

Keep this list in step with the pip pins in the Dockerfile.
"""

import importlib.metadata as md
import json
import os
import sys

PYTHON = "3.13.15"

EXPECTED = {
    "jupysql": "0.11.1",
    "pymysql": "1.2.0",
    "sqlalchemy": "2.0.52",
    "pandas": "3.0.5",
    "numpy": "2.5.2",
    "openpyxl": "3.1.5",
    "xlrd": "2.0.2",
    "pyarrow": "25.0.1",
    "lxml": "6.1.2",
    "html5lib": "1.1",
    "beautifulsoup4": "4.15.0",
    "tabulate": "0.10.0",
    "matplotlib": "3.11.1",
    "polars": "1.44.1",
    "pyspark": "4.2.0",
}

# Distributions whose import name differs from their package name. Installing
# the distribution is not proof it imports, so both are checked.
IMPORT_NAME = {
    "jupysql": "sql",
    "beautifulsoup4": "bs4",
    "pymysql": "pymysql",
    "sqlalchemy": "sqlalchemy",
}


OVERRIDES = "/opt/conda/share/jupyter/lab/settings/overrides.json"


def check_java(failures):
    """pyspark is a Python API over a JVM. Without Java it imports fine and
    dies at SparkSession.builder with an error that never mentions Java."""
    import shutil
    import subprocess
    java = shutil.which("java")
    if not java:
        failures.append("java is NOT on PATH -- pyspark will import but no "
                        "SparkSession can start")
        print("  %-16s %-10s MISSING" % ("java", "-"))
        return
    try:
        out = subprocess.run([java, "-version"], capture_output=True, text=True)
        ver = (out.stderr or out.stdout).split("\n")[0].strip()
    except Exception as exc:
        failures.append("java is present but unrunnable: %s" % exc)
        ver = "unrunnable"
    print("  %-16s %-10s %s" % ("java", "ok", ver[:46]))


def check_theme(failures):
    """The console defaults to dark; a rebuild must not quietly drop it."""
    if not os.path.exists(OVERRIDES):
        failures.append("JupyterLab overrides.json is missing -- the console "
                        "would start in the default light theme")
        print("  %-16s %-10s MISSING" % ("lab theme", "-"))
        return
    try:
        cfg = json.load(open(OVERRIDES))
        theme = cfg["@jupyterlab/apputils-extension:themes"]["theme"]
    except Exception as exc:
        failures.append("overrides.json is unreadable: %s" % exc)
        print("  %-16s %-10s UNREADABLE" % ("lab theme", "-"))
        return
    ok = theme == "JupyterLab Dark"
    if not ok:
        failures.append("lab theme is %r, expected 'JupyterLab Dark'" % theme)
    print("  %-16s %-10s %s" % ("lab theme", "dark" if ok else theme,
                                "ok" if ok else "MISMATCH"))


def main():
    failures = []

    actual_python = "%d.%d.%d" % sys.version_info[:3]
    if actual_python != PYTHON:
        failures.append("python is %s, expected %s -- 282 notebooks declare "
                        "%s in their kernel metadata"
                        % (actual_python, PYTHON, PYTHON))
    print("  %-16s %-10s %s" % ("python", actual_python,
                                "ok" if actual_python == PYTHON else "MISMATCH"))

    for dist, want in sorted(EXPECTED.items()):
        try:
            got = md.version(dist)
        except md.PackageNotFoundError:
            failures.append("%s is NOT INSTALLED (expected %s)" % (dist, want))
            print("  %-16s %-10s MISSING" % (dist, "-"))
            continue

        status = "ok" if got == want else "MISMATCH"
        if got != want:
            failures.append("%s is %s, expected %s" % (dist, got, want))

        mod = IMPORT_NAME.get(dist, dist)
        try:
            # BaseException, not Exception: a module that calls sys.exit()
            # during import raises SystemExit, which `except Exception` misses
            # -- the interpreter then dies mid-check and the failure looks like
            # a crash rather than a result. jupysql + pyspark did exactly that.
            __import__(mod)
        except BaseException as exc:
            status = "IMPORT FAILED"
            failures.append("%s %s installed but `import %s` raised %s"
                            % (dist, got, mod, type(exc).__name__))
        print("  %-16s %-10s %s" % (dist, got, status))

    check_java(failures)
    check_theme(failures)

    print()
    if failures:
        print("IMAGE VERIFICATION FAILED (%d problem(s)):" % len(failures))
        for f in failures:
            print("  -", f)
        sys.exit(1)
    print("image verified: python %s, %d pinned packages, JVM, dark theme"
          % (PYTHON, len(EXPECTED)))


if __name__ == "__main__":
    main()
