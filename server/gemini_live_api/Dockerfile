FROM python:3.10-slim

WORKDIR /app

COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/main.py ./main.py

EXPOSE 8000

CMD ["python3", "main.py"]