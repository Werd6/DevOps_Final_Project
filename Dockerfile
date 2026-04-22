FROM python:3.13.13-slim-trixie@sha256:29cd4a998d62fb9ace6d42c1288391c31c3fdf6bca987a509f0f9b6cd4608df7

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
