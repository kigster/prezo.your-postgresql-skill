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

# Export the deck to deck.pdf, one page per slide
pdf: install
    @lsof -ti:8111 | xargs kill -9 2>/dev/null || true
    @python3 -m http.server 8111 --bind 127.0.0.1 & echo $! > /tmp/prezo-pdf-server.pid
    @sleep 1
    npx -y decktape@latest reveal \
        --chrome-path "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
        -s 1920x1080 http://127.0.0.1:8111/ deck.pdf
    @kill $(cat /tmp/prezo-pdf-server.pid) 2>/dev/null || true
    @rm -f /tmp/prezo-pdf-server.pid
    @echo "wrote deck.pdf"

# rm -rf node_modules
clean:
    rm -rf node_modules

# Presentation statistics
stats:
    @echo "slides: $$(grep -c '^---$' slides.md)"
    @echo "code blocks: $$(grep -c '^\`\`\`' slides.md)"
    @echo "lines: $$(wc -l < slides.md)"
