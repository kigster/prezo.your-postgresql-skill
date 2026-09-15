# PostgreSQL skills-file talk (reveal.js)

default:
    @just --list

# npm install
install:
    npm install

# python3 -m http.server 8000 --bind 0.0.0.0
serve: install
    @lsof -ti:8000 | xargs kill -9 2>/dev/null || true
    @echo "http://0.0.0.0:8000"
    python3 -m http.server 8000 --bind 0.0.0.0

# Stop the server on port 8000
stop:
    @lsof -ti:8000 | xargs kill -9 2>/dev/null && echo "stopped" || echo "nothing on 8000"

# Open http://localhost:8000
open:
    @open http://localhost:8000

# Serve, then open the browser
preview:
    @just serve &
    @sleep 1
    @just open

# rm -rf node_modules
clean:
    rm -rf node_modules

# Presentation statistics
stats:
    @echo "slides: $$(grep -c '^---$' slides.md)"
    @echo "code blocks: $$(grep -c '^\`\`\`' slides.md)"
    @echo "lines: $$(wc -l < slides.md)"
