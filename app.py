from http.server import SimpleHTTPRequestHandler, HTTPServer

PORT = 8080
httpd = HTTPServer(('0.0.0.0', PORT), SimpleHTTPRequestHandler)
print('Serving on port', PORT)
httpd.serve_forever()
