# Dockerfile for LookMyShow Flask App
FROM python:3.10-slim

WORKDIR /app

COPY ../website/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY ../website/ .

EXPOSE 8080

CMD ["gunicorn", "-b", ":8080", "app:app"] 