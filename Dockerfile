FROM python:3.9-alpine

WORKDIR /app

RUN echo "from http.server import SimpleHTTPRequestHandler, HTTPServer\n\
PORT = 8080\n\
httpd = HTTPServer(('0.0.0.0', PORT), SimpleHTTPRequestHandler)\n\
print('Serving on port', PORT)\n\
httpd.serve_forever()" > app.py

EXPOSE 8080

CMD ["python", "app.py"]

