# What belongs in your PostgreSQL skills file

A 15-minute talk for Ruby developers who ship with coding agents.

The source of the file, and the argument for writing it, is [Condensing Twenty Years of Wisdom in One Markdown](https://kig.re/2026/08/19/condensing-twenty-years-of-wisdom-in-one-markdown.html).

## Run it

```bash
npm install
just serve
```

Then open http://0.0.0.0:8000/

`just serve` binds `0.0.0.0:8000`. `S` is speaker notes. Arrow keys move. Do not run `mdformat` on `slides.md`: it turns `---` into a thematic break and the deck collapses.

## Stack

reveal.js, Prism.js, Markdown slides.

The visual system is the 8 KB heap page. Every slide is drawn as a page: a header strip carrying the page number and one line pointer per slide, the headline at the start of the page, and the content stacked against the end of it the way tuples fill a real page. Ink `#10263B` on paper `#E9EEF2`, slonik blue `#336791` for anything the speaker points at, and `#D63B12` for the things that go wrong. Type is Archivo, variable in weight and width, with Fantasque Sans Mono for code.

Only the diagram slides animate, and each plays once when its slide arrives. `prefers-reduced-motion` turns that off.

## License

MIT for the deck. Archivo, in `assets/fonts/archivo`, is under the SIL Open Font License.
