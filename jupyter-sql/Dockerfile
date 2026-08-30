# Pinned by digest, not `:latest`. The tag moves; this does not.
#
# 282 notebooks in this repo declare `"version": "3.13.15"` in their kernel
# metadata, and scripts/normalise_notebooks.py enforces that block -- so the
# Python version is load-bearing, not cosmetic. A base image that quietly
# moved to 3.14 would put every notebook in permanent diff against its own
# metadata.
#
# To bump: change the digest, rebuild, run scripts/check_image.py, then
# re-verify the classes whose solutions quote output (see each class README).
FROM quay.io/jupyter/base-notebook@sha256:23fbe16371af3c0fdc833fa0962b42fd07811e152b821ff51d19a8d6e9cc86cf

# EVERY version here is pinned, and that is the whole point.
#
# This repo's guarantee is that every number quoted in a solution is output
# somebody observed -- 287 literals in week3_day4_morning alone were matched
# against a real run. That guarantee is only as good as the interpreter that
# produced them. An unpinned `pip install pandas` means a rebuild six months
# from now can bring pandas 3.1 or 4.0, change a dtype or an error message,
# and silently invalidate hundreds of verified figures with nothing failing.
#
# These are the exact versions the solutions were verified against.
#
#   jupysql/pymysql/sqlalchemy  drive the SQL worksheets (week 2, days 2-3)
#   pandas/numpy                the Pandas and modeling blocks (week 3)
#   openpyxl  .xlsx read AND write        xlrd     legacy .xls read
#   pyarrow   .parquet                    lxml     read_html / read_xml
#   html5lib + beautifulsoup4             read_html's fallback parser
#   tabulate  DataFrame.to_markdown()     matplotlib  plotting
#
# base-notebook deliberately ships WITHOUT pandas -- that is the
# scipy-notebook image -- so every one of these has to be named explicitly or
# the worksheets are unrunnable.
RUN pip install --no-cache-dir \
      jupysql==0.11.1 \
      pymysql==1.2.0 \
      sqlalchemy==2.0.52 \
      pandas==3.0.5 \
      numpy==2.5.2 \
      openpyxl==3.1.5 \
      xlrd==2.0.2 \
      pyarrow==25.0.1 \
      lxml==6.1.2 \
      html5lib==1.1 \
      beautifulsoup4==4.15.0 \
      tabulate==0.10.0 \
      matplotlib==3.11.1

# Fail the BUILD, not a worksheet in front of a class, if anything above is
# missing or the wrong version. A broken image should never reach a student.
COPY --chown=${NB_UID}:${NB_GID} verify_image.py /tmp/verify_image.py
RUN python3 /tmp/verify_image.py && rm /tmp/verify_image.py

# curl is NOT in base-notebook, and the WeCloudData "Lab - Pandas Advanced"
# notebook downloads its seven datasets with `!curl -sS -o ...` before reading
# them. Without this the vendor notebook fails on its first cell, and since it
# is kept byte-identical we fix the image rather than the notebook.
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*
USER ${NB_UID}

COPY --chown=${NB_UID}:${NB_GID} SQL_Console.ipynb /home/jovyan/work/SQL_Console.ipynb

ENV JUPYTER_ENABLE_LAB=yes
WORKDIR /home/jovyan/work
