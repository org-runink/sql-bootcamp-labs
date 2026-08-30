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
}

# Distributions whose import name differs from their package name. Installing
# the distribution is not proof it imports, so both are checked.
IMPORT_NAME = {
    "jupysql": "sql",
    "beautifulsoup4": "bs4",
    "pymysql": "pymysql",
    "sqlalchemy": "sqlalchemy",
}


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
            __import__(mod)
        except Exception as exc:
            status = "IMPORT FAILED"
            failures.append("%s %s installed but `import %s` raised %s"
                            % (dist, got, mod, type(exc).__name__))
        print("  %-16s %-10s %s" % (dist, got, status))

    print()
    if failures:
        print("IMAGE VERIFICATION FAILED (%d problem(s)):" % len(failures))
        for f in failures:
            print("  -", f)
        sys.exit(1)
    print("image verified: python %s and %d pinned packages, all importable"
          % (PYTHON, len(EXPECTED)))


if __name__ == "__main__":
    main()
