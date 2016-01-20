#!/bin/bash
docker run -d -p 8888:8888 -v /home/rok/Documents/sparkblog/notebooks:/home/jovyan/work/ jupyter/pyspark-notebook
xdg-open http://127.0.0.1:8888/tree
docker attach "$(docker ps -lq)"
