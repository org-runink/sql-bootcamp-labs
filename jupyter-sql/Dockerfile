FROM quay.io/jupyter/base-notebook:latest

# jupysql/pymysql/sqlalchemy drive the SQL worksheets (24/08, 25/08).
#
# The rest is for the Pandas block (30/08). base-notebook deliberately ships
# without pandas -- that is the scipy-notebook image -- so every one of these
# has to be named explicitly or the worksheets are unrunnable:
#   openpyxl  .xlsx read AND write        xlrd     legacy .xls read
#   pyarrow   .parquet                    lxml     read_html / read_xml
#   html5lib + beautifulsoup4             read_html's fallback parser
#   tabulate  DataFrame.to_markdown()
RUN pip install --no-cache-dir \
      jupysql pymysql sqlalchemy \
      pandas numpy \
      openpyxl xlrd pyarrow lxml html5lib beautifulsoup4 tabulate matplotlib

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
