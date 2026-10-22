FROM python:3.12-slim
RUN useradd --uid 10001 --create-home worker
WORKDIR /home/worker
COPY worker.py /home/worker/worker.py
USER 10001:10001
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
CMD ["python","worker.py"]
