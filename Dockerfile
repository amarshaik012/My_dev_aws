FROM python:3.9-alpine

WORKDIR /app

RUN echo "from http.server import SimpleHTTPRequestHandler, HTTPServer" > app.py && \
    echo "PORT = 8080" >> app.py && \
    echo "httpd = HTTPServer(('0.0.0.0', PORT), SimpleHTTPRequestHandler)" >> app.py && \
    echo "print('Serving on port', PORT)" >> app.py && \
    echo "httpd.serve_forever()" >> app.py

EXPOSE 8080

CMD ["python", "app.py"]
