FROM quay.io/jupyter/base-notebook:latest

RUN pip install --no-cache-dir jupysql pymysql sqlalchemy

COPY --chown=${NB_UID}:${NB_GID} SQL_Console.ipynb /home/jovyan/work/SQL_Console.ipynb

ENV JUPYTER_ENABLE_LAB=yes
WORKDIR /home/jovyan/work
