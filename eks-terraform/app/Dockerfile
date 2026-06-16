# Use official Python base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy app files
COPY app.py .

# Install Flask
RUN pip install flask

# Expose port
EXPOSE 5000

# Run application
CMD ["python", "app.py"]
