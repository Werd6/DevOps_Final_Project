FROM python:3.13.13-slim-trixie@sha256:b477ccedc611b8aa6904f579525a4cfa15d643e17b95dda6ef527fd072acb8d4

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
