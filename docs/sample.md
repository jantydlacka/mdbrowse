# Sample document

A quick taste of how **mdbrowse** renders Markdown — styled just like GitHub,
in light and dark, read-only.

## Text & inline

Regular text with **bold**, *italic*, ~~strikethrough~~, and `inline code`.
Links look like [this](https://example.com). Here's a footnote-ish aside and a
> blockquote spanning a thought worth setting apart.

## Task list

- [x] Render Markdown like GitHub
- [x] Work fully offline (no server, no API)
- [ ] Convince you to star the repo

## Table

| Tool     | Read-only | Offline | Default `.md` handler |
|----------|:---------:|:-------:|:---------------------:|
| mdbrowse   |     ✅     |    ✅    |          ✅           |
| grip     |     ✅     |    ⚠️    |          ❌           |
| an editor|     ❌     |    ✅    |          ❌           |

## Code block

```bash
mdbrowse README.md          # render and open
mdbrowse --url notes.md     # just print the file:// URL
```

## List with nesting

1. First
2. Second
   - a nested bullet
   - another one
3. Third
