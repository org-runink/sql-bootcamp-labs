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
#   polars    the DataFrame alternative    pyspark     distributed DataFrames
#
# PYSPARK NEEDS A JVM. `pip install pyspark` gives you the Python API and
# nothing to run it on -- base-notebook ships no Java, so the JRE is installed
# below and JAVA_HOME is set. Without both, `SparkSession.builder...` fails at
# runtime with an error that does not mention Java.
#
# THE [connect] EXTRA IS NOT OPTIONAL HERE. jupysql has optional Spark
# support that activates the moment pyspark is importable, and it imports
# pyspark.sql.connect. Without grpcio that module calls sys.exit(0) DURING
# IMPORT -- so `%load_ext sql` would kill the Jupyter kernel and take every SQL
# worksheet with it. [connect] pulls grpcio and the exit goes away. Verified:
# jupysql imports cleanly, and a SparkSession still starts and runs a job.
#
# PYSPARK 4.2.0 WARNS ON pandas 3.x: "PySpark does not yet fully support
# pandas >= 3.0.0". Core Spark SQL and DataFrame work is unaffected -- verified
# by starting a session and running a job -- but toPandas(), pandas UDFs and
# pandas-on-Spark may misbehave. Downgrading pandas is not an option: 300+
# solutions were verified against 3.0.5 and their quoted output would change.
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
      matplotlib==3.11.1 \
      polars==1.44.1 \
      "pyspark[connect]==4.2.0"


# curl is NOT in base-notebook, and the WeCloudData "Lab - Pandas Advanced"
# notebook downloads its seven datasets with `!curl -sS -o ...` before reading
# them. Without this the vendor notebook fails on its first cell, and since it
# is kept byte-identical we fix the image rather than the notebook.
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl openjdk-17-jre-headless \
 && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
USER ${NB_UID}

COPY --chown=${NB_UID}:${NB_GID} SQL_Console.ipynb /home/jovyan/work/SQL_Console.ipynb

# LAST STEP ON PURPOSE. This gate validates the FINISHED image -- packages,
# the JVM pyspark needs, and the dark theme. Placing it earlier means it
# checks a half-built image and passes on things that are added afterwards;
# that mistake has been made twice in this file's history.
#
# Fail the BUILD, not a worksheet in front of a class.
#
# The script STAYS in the image at a stable path, because the build-time gate
# is only half the problem: it cannot catch a STALE image that is never
# rebuilt. docker-compose.yml runs this same file as the container's
# healthcheck, so a pre-c4082db console shows up as `unhealthy` in
# `podman ps` without anybody having to run anything.
# Dark by default. JupyterLab ships "JupyterLab Light" and a room full of
# white screens is what people actually complain about. This is an OVERRIDE,
# not a lock: Settings -> Theme still switches it per user, and the choice is
# remembered in their browser.
# Spark tuned for a ~8 GB workstation, not a cluster. Read by spark-submit
# BEFORE the JVM starts, which is the only point at which spark.driver.memory
# can still take effect -- builder.config() is too late and is silently
# ignored. See the file itself for the reasoning behind each value.
COPY --chown=${NB_UID}:${NB_GID} spark-defaults.conf \
     /opt/conda/lib/python3.13/site-packages/pyspark/conf/spark-defaults.conf

COPY --chown=${NB_UID}:${NB_GID} jupyterlab-overrides.json \
     /opt/conda/share/jupyter/lab/settings/overrides.json

COPY --chown=${NB_UID}:${NB_GID} verify_image.py /opt/verify_image.py
RUN python3 /opt/verify_image.py

ENV JUPYTER_ENABLE_LAB=yes
WORKDIR /home/jovyan/work
